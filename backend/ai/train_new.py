import os
import json
import argparse
import numpy as np
import cv2
import tensorflow as tf
import albumentations as A
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from tensorflow.keras.utils import Sequence
from tensorflow.keras.applications import EfficientNetV2S, ResNet50V2, VGG16
from tensorflow.keras.layers import (
    Dense, GlobalAveragePooling2D, Dropout, Conv2DTranspose,
    Input, Conv2D, MaxPooling2D, BatchNormalization, Flatten
)
from tensorflow.keras.models import Model
import random
import logging
import kagglehub

logging.getLogger('tensorflow').setLevel(logging.ERROR)
tf.get_logger().setLevel('ERROR')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(SCRIPT_DIR, "dataset_30classes")

def ensure_dataset():
    """Download the 30-classes dataset via kagglehub into ./dataset/ if not already present."""
    if os.path.exists(DATASET_DIR) and os.path.isfile(os.path.join(DATASET_DIR, "DATA.json")):
        print(f"Dataset already exists at: {DATASET_DIR}")
        return DATASET_DIR
    
    print("Downloading dataset via kagglehub...")
    path = kagglehub.dataset_download(
        "fernando2rad/brain-tumor-mri-images-30-classes",
        output_dir=DATASET_DIR
    )
    print(f"Dataset downloaded to: {path}")
    return DATASET_DIR

DATASET_PATH = ensure_dataset()
JSON_PATH = os.path.join(DATASET_PATH, "DATA.json")
IMG_DIR = DATASET_PATH

IMG_SIZE = 256
BATCH_SIZE = 16
EPOCHS = 40
EPOCHS_FINETUNE = 15
HEATMAP_SIGMA = 15

MODELS_DIR = os.path.join(SCRIPT_DIR, "models")
os.makedirs(MODELS_DIR, exist_ok=True)

def load_dataset_info(json_path, img_dir):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    dataset_info = []
    classes_set = set()
    
    for rel_path, info in data.items():
        safe_rel_path = rel_path.replace('\\', os.sep).replace('/', os.sep)
        full_img_path = os.path.join(img_dir, safe_rel_path)
        
        if not os.path.exists(full_img_path):
            continue
            
        class_name = info['class']
        classes_set.add(class_name)
        
        if "Normal" in class_name:
            point = None
        else:
            point = (info['point']['x'], info['point']['y'])
            
        dataset_info.append({
            'img_path': full_img_path,
            'class': class_name,
            'point': point
        })
        
    classes_list = sorted(list(classes_set))
    class_to_idx = {cls: idx for idx, cls in enumerate(classes_list)}
    
    return dataset_info, class_to_idx, classes_list


def generate_gaussian_heatmap(size, center, sigma):
    heatmap = np.zeros((size, size), dtype=np.float32)
    if center is None:
        return heatmap
    
    x_center, y_center = center
    x = np.arange(0, size, 1, float)
    y = np.arange(0, size, 1, float)
    y = y[:, np.newaxis]
    x0 = int(x_center)
    y0 = int(y_center)
    
    if x0 < 0 or x0 >= size or y0 < 0 or y0 >= size:
        return heatmap 

    heatmap = np.exp(-4 * np.log(2) * ((x - x0)**2 + (y - y0)**2) / sigma**2)
    return heatmap


class BrainTumorDataGenerator(Sequence):
    def __init__(self, dataset_info, class_to_idx, batch_size, img_size, augment=False, shuffle=True, **kwargs):
        super().__init__(**kwargs)
        self.dataset_info = dataset_info
        self.class_to_idx = class_to_idx
        self.num_classes = len(class_to_idx)
        self.batch_size = batch_size
        self.img_size = img_size
        self.shuffle = shuffle

        if augment:
            self.transform = A.Compose([
                A.Resize(img_size, img_size),
                A.HorizontalFlip(p=0.5),
                A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.4),
                A.Affine(translate_percent={'x': (-0.05, 0.05), 'y': (-0.05, 0.05)}, 
                         scale={'x': (0.95, 1.05), 'y': (0.95, 1.05)}, 
                         rotate=0, p=0.3),
                A.ElasticTransform(alpha=1, sigma=50, p=0.2)
            ], keypoint_params=A.KeypointParams(format='xy', remove_invisible=False))
        else:
            self.transform = A.Compose([
                A.Resize(img_size, img_size)
            ], keypoint_params=A.KeypointParams(format='xy', remove_invisible=False))
            
        self.on_epoch_end()

    def __len__(self):
        return int(np.floor(len(self.dataset_info) / self.batch_size))

    def __getitem__(self, index):
        indexes = self.indexes[index * self.batch_size:(index + 1) * self.batch_size]
        batch_info = [self.dataset_info[k] for k in indexes]
        
        X = np.empty((self.batch_size, self.img_size, self.img_size, 3), dtype=np.float32)
        y_class = np.empty((self.batch_size, self.num_classes), dtype=np.float32)
        y_heatmap = np.empty((self.batch_size, self.img_size, self.img_size, 1), dtype=np.float32)
        
        for i, info in enumerate(batch_info):
            img = cv2.imread(info['img_path'])
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            keypoints = [info['point']] if info['point'] is not None else []
            transformed = self.transform(image=img, keypoints=keypoints)
            transformed_img = transformed['image'] / 255.0
            transformed_kps = transformed['keypoints']
            new_point = transformed_kps[0] if len(transformed_kps) > 0 else None
            X[i,] = transformed_img
            y_class[i,] = tf.keras.utils.to_categorical(self.class_to_idx[info['class']], num_classes=self.num_classes)
            heatmap_2d = generate_gaussian_heatmap(self.img_size, new_point, HEATMAP_SIGMA)
            y_heatmap[i,] = np.expand_dims(heatmap_2d, axis=-1)
            
        return X, {"class_output": y_class, "heatmap_output": y_heatmap}

    def on_epoch_end(self):
        self.indexes = np.arange(len(self.dataset_info))
        if self.shuffle:
            np.random.shuffle(self.indexes)


AVAILABLE_BACKBONES = ["efficientnet", "resnet50v2", "vgg16", "cnn"]


def _build_cnn_backbone(inputs, input_size):
    """Custom CNN backbone (no pretrained weights)."""
    x = inputs
    for filters in [32, 64, 128, 256, 512]:
        x = Conv2D(filters, 3, activation="relu", padding="same")(x)
        x = Conv2D(filters, 3, activation="relu", padding="same")(x)
        x = MaxPooling2D(2)(x)
        x = BatchNormalization()(x)
    return x


def build_dual_head_model(input_size, num_classes, backbone="efficientnet"):
    inputs = tf.keras.Input(shape=(input_size, input_size, 3))

    if backbone == "efficientnet":
        base_model = EfficientNetV2S(include_top=False, weights='imagenet', input_tensor=inputs)
        for layer in base_model.layers[:-50]:
            layer.trainable = False
        x = base_model.output
        upsample_steps = 5

    elif backbone == "resnet50v2":
        base_model = ResNet50V2(include_top=False, weights='imagenet', input_tensor=inputs)
        for layer in base_model.layers[:-30]:
            layer.trainable = False
        x = base_model.output
        upsample_steps = 5

    elif backbone == "vgg16":
        base_model = VGG16(include_top=False, weights='imagenet', input_tensor=inputs)
        for layer in base_model.layers[:-4]:
            layer.trainable = False
        x = base_model.output
        upsample_steps = 5

    elif backbone == "cnn":
        x = _build_cnn_backbone(inputs, input_size)
        upsample_steps = 5

    else:
        raise ValueError(f"Unknown backbone: {backbone}. Choose from: {AVAILABLE_BACKBONES}")

    # Classification head
    gap = GlobalAveragePooling2D()(x)
    gap = Dropout(0.4)(gap)
    class_output = Dense(num_classes, activation='softmax', name='class_output')(gap)

    # Heatmap (localization) head — adaptive upsampling to match input size
    h = x
    filters_seq = [256, 128, 64, 32, 16]
    for i in range(upsample_steps):
        h = Conv2DTranspose(filters_seq[i], (3, 3), strides=(2, 2), padding='same', activation='relu')(h)
    heatmap_output = Conv2DTranspose(1, (3, 3), strides=(1, 1), padding='same', activation='sigmoid', name='heatmap_output')(h)

    model = Model(inputs=inputs, outputs=[class_output, heatmap_output])
    return model


class EpochSummaryReport(tf.keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        logs = logs or {}
        acc = logs.get('class_output_accuracy', 0) * 100
        prec = logs.get('class_output_precision', 0) * 100
        rec = logs.get('class_output_recall', 0) * 100
        loss = logs.get('class_output_loss', 0)
        val_acc = logs.get('val_class_output_accuracy', 0) * 100
        val_prec = logs.get('val_class_output_precision', 0) * 100
        val_rec = logs.get('val_class_output_recall', 0) * 100
        val_loss = logs.get('val_class_output_loss', 0)
        
        print(f"\n" + "="*60)
        print(f"🏁 EPOCH {epoch + 1} SUMMARY 🏁")
        print(f"-"*60)
        print(f"📊 TRAINING PERFORMANCE:")
        print(f"   • Accuracy: {acc:.2f}%, Precision: {prec:.2f}%, Sensitivity/Recall: {rec:.2f}%, Loss: {loss:.4f}")
        print(f"🩺 VALIDATION PERFORMANCE:")
        print(f"   • Accuracy: {val_acc:.2f}%, Precision: {val_prec:.2f}%, Sensitivity/Recall: {val_rec:.2f}%, Loss: {val_loss:.4f}")
        print(f"="*60 + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train brain tumor dual-head model (classification + localization)")
    parser.add_argument("--backbone", type=str, default="efficientnet",
                        choices=AVAILABLE_BACKBONES,
                        help="Backbone architecture to use (default: efficientnet)")
    parser.add_argument("--epochs", type=int, default=EPOCHS,
                        help=f"Phase 1 epochs (default: {EPOCHS})")
    parser.add_argument("--epochs-finetune", type=int, default=EPOCHS_FINETUNE,
                        help=f"Phase 2 fine-tune epochs (default: {EPOCHS_FINETUNE})")
    parser.add_argument("--batch-size", type=int, default=BATCH_SIZE,
                        help=f"Batch size (default: {BATCH_SIZE})")
    args = parser.parse_args()

    backbone = args.backbone
    print(f"\n{'='*60}")
    print(f"  BACKBONE: {backbone.upper()}")
    print(f"  Epochs Phase 1: {args.epochs}, Phase 2: {args.epochs_finetune}")
    print(f"  Batch size: {args.batch_size}")
    print(f"{'='*60}\n")

    print("Starting data loading...")
    dataset_info, class_to_idx, classes_list = load_dataset_info(JSON_PATH, IMG_DIR)
    print(f"Total images loaded: {len(dataset_info)}")
    print(f"Classes identified: {len(classes_list)}")
    
    train_info, val_info = train_test_split(dataset_info, test_size=0.2, random_state=42, stratify=[d['class'] for d in dataset_info])
    train_gen = BrainTumorDataGenerator(train_info, class_to_idx, args.batch_size, IMG_SIZE, augment=True)
    val_gen = BrainTumorDataGenerator(val_info, class_to_idx, args.batch_size, IMG_SIZE, augment=False, shuffle=False)
    
    model = build_dual_head_model(input_size=IMG_SIZE, num_classes=len(classes_list), backbone=backbone)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
        loss={
            "class_output": "categorical_crossentropy",
            "heatmap_output": "mean_squared_error"
        },
        loss_weights={
            "class_output": 1.0,
            "heatmap_output": 0.5
        },
        metrics={
            "class_output": [
                "accuracy",
                tf.keras.metrics.Precision(name="precision"), 
                tf.keras.metrics.Recall(name="recall"),
                tf.keras.metrics.TopKCategoricalAccuracy(k=3, name="top3_accuracy")
            ],
            "heatmap_output": []
        }
    )
    
    best_model_path = os.path.join(MODELS_DIR, f"best_{backbone}.keras")
    finetuned_model_path = os.path.join(MODELS_DIR, f"finetuned_{backbone}.keras")
    
    callbacks_p1 = [
        tf.keras.callbacks.ModelCheckpoint(best_model_path, save_best_only=True, monitor="val_class_output_accuracy", mode="max"),
        tf.keras.callbacks.ReduceLROnPlateau(monitor="val_class_output_loss", factor=0.5, patience=4, min_lr=1e-6, verbose=1, mode="min"),
        tf.keras.callbacks.EarlyStopping(monitor="val_class_output_accuracy", patience=10, restore_best_weights=True, mode="max"),
        EpochSummaryReport()
    ]
    
    history_p1 = model.fit(train_gen, validation_data=val_gen, epochs=args.epochs, callbacks=callbacks_p1)
    model.load_weights(best_model_path)
    
    for layer in model.layers:
        layer.trainable = True
        
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss={
            "class_output": "categorical_crossentropy",
            "heatmap_output": "mean_squared_error"
        },
        loss_weights={
            "class_output": 1.0,
            "heatmap_output": 0.5
        },
        metrics={
            "class_output": [
                "accuracy",
                tf.keras.metrics.Precision(name="precision"), 
                tf.keras.metrics.Recall(name="recall"),
                tf.keras.metrics.TopKCategoricalAccuracy(k=3, name="top3_accuracy")
            ],
            "heatmap_output": []
        }
    )
    
    callbacks_p2 = [
        tf.keras.callbacks.ModelCheckpoint(finetuned_model_path, save_best_only=True, monitor="val_class_output_accuracy", mode="max"),
        tf.keras.callbacks.EarlyStopping(monitor="val_class_output_accuracy", patience=6, restore_best_weights=True, mode="max"),
        EpochSummaryReport()
    ]
    
    history_p2 = model.fit(train_gen, validation_data=val_gen, epochs=args.epochs_finetune, callbacks=callbacks_p2)
    print(f"Training completely finished. Final model saved at: {finetuned_model_path}")


    from sklearn.metrics import confusion_matrix, classification_report
    import seaborn as sns

    def cmatrix(m, vg, vi, cl, bb):
        preds = m.predict(vg)
        y_pred = np.argmax(preds[0], axis=1)
        y_true = [vg.class_to_idx[info['class']] for info in vi[:len(y_pred)]]
        
        cm = confusion_matrix(y_true, y_pred)
        plt.figure(figsize=(20, 16))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=cl, yticklabels=cl)
        plt.title(f'Confusion Matrix — {bb.upper()}')
        plt.ylabel('Real Class')
        plt.xlabel('Predicted Class')
        plt.xticks(rotation=90)
        plt.tight_layout()
        plt.savefig(os.path.join(SCRIPT_DIR, f'matrix_{bb}.png'))
        plt.close()
        print(classification_report(y_true, y_pred, target_names=cl))

    def graphs(history, filename="graphs.png"):
        sns.set_theme(style="whitegrid")
        fig, axes = plt.subplots(1, 3, figsize=(20, 6))

        axes[0].plot(history.history['class_output_accuracy'], label='Train', color='blue', linewidth=2)
        axes[0].plot(history.history['val_class_output_accuracy'], label='Test', color='orange', linewidth=2)
        axes[0].set_title('Accuracy', fontsize=14)
        axes[0].set_xlabel('Epoch')
        axes[0].set_ylabel('Accuracy')
        axes[0].legend()

        axes[1].plot(history.history['class_output_loss'], label='Loss Train', color='red', linestyle='--')
        axes[1].plot(history.history['val_class_output_loss'], label='Loss Test', color='green')
        axes[1].set_title('Loss', fontsize=14)
        axes[1].set_xlabel('Epoch')
        axes[1].set_ylabel('Loss')
        axes[1].legend()

        axes[2].plot(history.history['class_output_recall'], label='Recall Train', color='purple')
        axes[2].plot(history.history['val_class_output_recall'], label='Recall Test', color='magenta')
        axes[2].set_title('Recall', fontsize=14)
        axes[2].set_xlabel('Epoch')
        axes[2].set_ylabel('Recall')
        axes[2].legend()

        plt.tight_layout()
        plt.savefig(filename, dpi=300)
        plt.close()

    cmatrix(model, val_gen, val_info, classes_list, backbone)
    graphs(history_p1, filename=os.path.join(SCRIPT_DIR, f"graphs_{backbone}_phase1.png"))
    graphs(history_p2, filename=os.path.join(SCRIPT_DIR, f"graphs_{backbone}_phase2.png"))
