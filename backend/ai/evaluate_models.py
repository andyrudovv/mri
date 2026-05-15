"""
Evaluate trained MRI models and generate metric plots:
- Accuracy, Precision, Recall (Sensitivity), Specificity, F1-score (per-class bar charts)
- ROC-AUC curves (one-vs-rest)
- Confusion Matrix (heatmap)

Usage:
    cd backend/ai
    python evaluate_models.py --model ensemble
    python evaluate_models.py --model efficientnet
    python evaluate_models.py --model both

Outputs saved to: backend/ai/metrics/
"""

import os
import sys
import json
import argparse

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    confusion_matrix,
    classification_report,
    roc_curve,
    auc,
)
from sklearn.preprocessing import label_binarize

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image_dataset_from_directory

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
METRICS_DIR = os.path.join(SCRIPT_DIR, "metrics")
os.makedirs(METRICS_DIR, exist_ok=True)

ENSEMBLE_MODEL_PATH = os.path.join(SCRIPT_DIR, "trained", "MRI_ENSEMBLED.keras")
EFFNET_MODEL_PATH = os.path.join(SCRIPT_DIR, "trained", "finetuned_efficientnet.keras")
EFFNET_CLASSES_PATH = os.path.join(SCRIPT_DIR, "trained", "efficientnet_classes.json")

DATASET_4_DIR = os.path.join(SCRIPT_DIR, "dataset_4classes")
DATASET_30_DIR = os.path.join(SCRIPT_DIR, "dataset_30classes")

IMG_SIZE = (256, 256)
BATCH_SIZE = 32


def load_ensemble_test_data():
    """Load 4-class test dataset for ensemble model."""
    test_path = None
    for candidate in [
        os.path.join(DATASET_4_DIR, "CleandMRIImageData", "Testing"),
        os.path.join(DATASET_4_DIR, "Testing"),
        os.path.join(SCRIPT_DIR, "dataset", "Testing"),
    ]:
        if os.path.isdir(candidate):
            test_path = candidate
            break

    if test_path is None:
        print("ERROR: 4-class test dataset not found. Run download_datasets.py first.")
        sys.exit(1)

    class_names = sorted(os.listdir(test_path))
    class_names = [c for c in class_names if os.path.isdir(os.path.join(test_path, c))]

    ds = image_dataset_from_directory(
        test_path,
        label_mode="categorical",
        class_names=class_names,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        shuffle=False,
    ).map(lambda x, y: (x / 255.0, y))

    return ds, class_names


def load_effnet_test_data():
    """Load 30-class test data for EfficientNet. Uses validation split from training set.
    The 30-class dataset has class folders directly inside dataset_30classes/
    (e.g. dataset_30classes/Astrocytoma T1/, ...) alongside DATA.json.
    """
    img_dir = DATASET_30_DIR

    if not os.path.isfile(os.path.join(img_dir, "DATA.json")):
        print("ERROR: 30-class dataset not found. Run download_datasets.py first.")
        sys.exit(1)

    with open(EFFNET_CLASSES_PATH, "r") as f:
        class_names = json.load(f)

    ds = image_dataset_from_directory(
        img_dir,
        label_mode="categorical",
        class_names=class_names,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        shuffle=False,
        validation_split=0.2,
        subset="validation",
        seed=42,
    ).map(lambda x, y: (x / 255.0, y))

    return ds, class_names


def get_predictions(model, dataset, model_type="ensemble"):
    """Run inference and return (y_true_labels, y_pred_labels, y_true_onehot, y_pred_probs)."""
    all_images, all_labels = [], []
    for x_batch, y_batch in dataset:
        all_images.append(x_batch.numpy())
        all_labels.append(y_batch.numpy())

    X = np.concatenate(all_images, axis=0)
    y_true_onehot = np.concatenate(all_labels, axis=0)

    raw_pred = model.predict(X, batch_size=BATCH_SIZE, verbose=1)

    if model_type == "efficientnet" and isinstance(raw_pred, (list, tuple)):
        y_pred_probs = raw_pred[0]
    else:
        y_pred_probs = raw_pred

    if model_type == "ensemble":
        exp_pred = np.exp(y_pred_probs - np.max(y_pred_probs, axis=1, keepdims=True))
        y_pred_probs = exp_pred / exp_pred.sum(axis=1, keepdims=True)

    y_true_labels = np.argmax(y_true_onehot, axis=1)
    y_pred_labels = np.argmax(y_pred_probs, axis=1)

    return y_true_labels, y_pred_labels, y_true_onehot, y_pred_probs


def compute_specificity(y_true, y_pred, num_classes):
    """Compute per-class specificity from confusion matrix."""
    cm = confusion_matrix(y_true, y_pred, labels=range(num_classes))
    specificity = []
    for i in range(num_classes):
        tn = cm.sum() - (cm[i, :].sum() + cm[:, i].sum() - cm[i, i])
        fp = cm[:, i].sum() - cm[i, i]
        spec = tn / (tn + fp) if (tn + fp) > 0 else 0.0
        specificity.append(spec)
    return np.array(specificity)


def plot_confusion_matrix(y_true, y_pred, class_names, title, save_path):
    """Plot and save confusion matrix heatmap."""
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(max(8, len(class_names) * 0.6), max(6, len(class_names) * 0.5)))
    sns.heatmap(
        cm, annot=True, fmt="d", cmap="Blues",
        xticklabels=class_names, yticklabels=class_names,
    )
    plt.title(f"Confusion Matrix — {title}", fontsize=14, fontweight="bold")
    plt.xlabel("Predicted", fontsize=11)
    plt.ylabel("Actual", fontsize=11)
    plt.xticks(rotation=45, ha="right", fontsize=8)
    plt.yticks(rotation=0, fontsize=8)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Saved: {save_path}")


def plot_per_class_metrics(precision, recall, specificity, f1, class_names, title, save_path):
    """Bar chart with per-class Precision, Recall, Specificity, F1."""
    x = np.arange(len(class_names))
    width = 0.2

    fig, ax = plt.subplots(figsize=(max(10, len(class_names) * 0.8), 6))
    ax.bar(x - 1.5 * width, precision, width, label="Precision", color="#2196F3")
    ax.bar(x - 0.5 * width, recall, width, label="Recall (Sensitivity)", color="#4CAF50")
    ax.bar(x + 0.5 * width, specificity, width, label="Specificity", color="#FF9800")
    ax.bar(x + 1.5 * width, f1, width, label="F1-Score", color="#9C27B0")

    ax.set_xlabel("Class")
    ax.set_ylabel("Score")
    ax.set_title(f"Per-Class Metrics — {title}", fontsize=14, fontweight="bold")
    ax.set_xticks(x)
    ax.set_xticklabels(class_names, rotation=45, ha="right", fontsize=8)
    ax.set_ylim(0, 1.05)
    ax.legend(loc="lower right")
    ax.grid(axis="y", alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Saved: {save_path}")


def plot_roc_auc(y_true_onehot, y_pred_probs, class_names, title, save_path):
    """Plot ROC curves (one-vs-rest) for each class + macro average."""
    num_classes = len(class_names)
    fpr, tpr, roc_auc_vals = {}, {}, {}

    for i in range(num_classes):
        fpr[i], tpr[i], _ = roc_curve(y_true_onehot[:, i], y_pred_probs[:, i])
        roc_auc_vals[i] = auc(fpr[i], tpr[i])

    all_fpr = np.unique(np.concatenate([fpr[i] for i in range(num_classes)]))
    mean_tpr = np.zeros_like(all_fpr)
    for i in range(num_classes):
        mean_tpr += np.interp(all_fpr, fpr[i], tpr[i])
    mean_tpr /= num_classes
    macro_auc = auc(all_fpr, mean_tpr)

    plt.figure(figsize=(10, 8))

    if num_classes <= 10:
        colors = plt.cm.tab10(np.linspace(0, 1, num_classes))
        for i in range(num_classes):
            plt.plot(fpr[i], tpr[i], color=colors[i], lw=1.5,
                     label=f"{class_names[i]} (AUC={roc_auc_vals[i]:.3f})")
    else:
        for i in range(num_classes):
            plt.plot(fpr[i], tpr[i], lw=0.8, alpha=0.4)

    plt.plot(all_fpr, mean_tpr, "k--", lw=2.5,
             label=f"Macro Average (AUC={macro_auc:.3f})")
    plt.plot([0, 1], [0, 1], "r:", lw=1, alpha=0.5)

    plt.xlim([-0.01, 1.0])
    plt.ylim([0.0, 1.02])
    plt.xlabel("False Positive Rate", fontsize=11)
    plt.ylabel("True Positive Rate", fontsize=11)
    plt.title(f"ROC Curves (One-vs-Rest) — {title}", fontsize=14, fontweight="bold")
    plt.legend(loc="lower right", fontsize=8)
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Saved: {save_path}")


def plot_overall_accuracy(accuracy, title, save_path):
    """Simple accuracy gauge-style bar."""
    fig, ax = plt.subplots(figsize=(6, 3))
    ax.barh(["Accuracy"], [accuracy], color="#0077B6", height=0.4)
    ax.barh(["Accuracy"], [1.0 - accuracy], left=[accuracy], color="#E0E0E0", height=0.4)
    ax.set_xlim(0, 1)
    ax.set_xlabel("Score")
    ax.set_title(f"Overall Accuracy — {title}: {accuracy:.4f} ({accuracy*100:.2f}%)",
                 fontsize=12, fontweight="bold")
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:.0%}"))
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Saved: {save_path}")


def evaluate_model(model, dataset, class_names, model_type, model_label):
    """Full evaluation pipeline for one model."""
    print(f"\n{'='*60}")
    print(f"  Evaluating: {model_label}")
    print(f"{'='*60}")

    y_true, y_pred, y_true_oh, y_pred_probs = get_predictions(model, dataset, model_type)
    num_classes = len(class_names)

    all_labels_range = list(range(num_classes))

    acc = accuracy_score(y_true, y_pred)
    prec = precision_score(y_true, y_pred, labels=all_labels_range, average=None, zero_division=0)
    rec = recall_score(y_true, y_pred, labels=all_labels_range, average=None, zero_division=0)
    f1 = f1_score(y_true, y_pred, labels=all_labels_range, average=None, zero_division=0)
    spec = compute_specificity(y_true, y_pred, num_classes)

    macro_prec = precision_score(y_true, y_pred, labels=all_labels_range, average="macro", zero_division=0)
    macro_rec = recall_score(y_true, y_pred, labels=all_labels_range, average="macro", zero_division=0)
    macro_f1 = f1_score(y_true, y_pred, labels=all_labels_range, average="macro", zero_division=0)
    macro_spec = spec.mean()

    print(f"\n  Overall Accuracy:   {acc:.4f} ({acc*100:.2f}%)")
    print(f"  Macro Precision:    {macro_prec:.4f}")
    print(f"  Macro Recall:       {macro_rec:.4f}")
    print(f"  Macro Specificity:  {macro_spec:.4f}")
    print(f"  Macro F1-Score:     {macro_f1:.4f}")

    print(f"\n  Classification Report:")
    print(classification_report(y_true, y_pred, labels=all_labels_range,
                                target_names=class_names, zero_division=0))

    prefix = model_type
    plot_overall_accuracy(acc, model_label,
                          os.path.join(METRICS_DIR, f"{prefix}_accuracy.png"))
    plot_per_class_metrics(prec, rec, spec, f1, class_names, model_label,
                           os.path.join(METRICS_DIR, f"{prefix}_per_class_metrics.png"))
    plot_confusion_matrix(y_true, y_pred, class_names, model_label,
                          os.path.join(METRICS_DIR, f"{prefix}_confusion_matrix.png"))
    plot_roc_auc(y_true_oh, y_pred_probs, class_names, model_label,
                 os.path.join(METRICS_DIR, f"{prefix}_roc_auc.png"))

    report = {
        "model": model_label,
        "accuracy": float(acc),
        "macro_precision": float(macro_prec),
        "macro_recall": float(macro_rec),
        "macro_specificity": float(macro_spec),
        "macro_f1": float(macro_f1),
        "per_class": {
            class_names[i]: {
                "precision": float(prec[i]),
                "recall": float(rec[i]),
                "specificity": float(spec[i]),
                "f1": float(f1[i]),
            }
            for i in range(num_classes)
        },
    }
    report_path = os.path.join(METRICS_DIR, f"{prefix}_report.json")
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"  Saved: {report_path}")

    return report


def main():
    parser = argparse.ArgumentParser(description="Evaluate MRI models and generate metric plots")
    parser.add_argument("--model", type=str, default="both",
                        choices=["ensemble", "efficientnet", "both"],
                        help="Which model to evaluate (default: both)")
    args = parser.parse_args()

    if args.model in ("ensemble", "both"):
        if not os.path.isfile(ENSEMBLE_MODEL_PATH):
            print(f"Ensemble model not found: {ENSEMBLE_MODEL_PATH}")
        else:
            print("\nLoading Ensemble model...")
            model = load_model(ENSEMBLE_MODEL_PATH)
            ds, classes = load_ensemble_test_data()
            evaluate_model(model, ds, classes, "ensemble", "Ensemble (VGG16+ResNet50+CNN)")

    if args.model in ("efficientnet", "both"):
        if not os.path.isfile(EFFNET_MODEL_PATH):
            print(f"EfficientNet model not found: {EFFNET_MODEL_PATH}")
        else:
            print("\nLoading EfficientNetV2S model...")
            model = load_model(EFFNET_MODEL_PATH)
            ds, classes = load_effnet_test_data()
            evaluate_model(model, ds, classes, "efficientnet", "EfficientNetV2S (30 classes)")

    print(f"\n{'='*60}")
    print(f"  All plots saved to: {METRICS_DIR}/")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
