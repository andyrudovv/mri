import os
import kagglehub



SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET30_DIR = os.path.join(SCRIPT_DIR, "dataset_30classes")
DATASET4_DIR = os.path.join(SCRIPT_DIR, "dataset_4classes")


def ensure_dataset30():
    """Download the 30-classes dataset via kagglehub into ./dataset/ if not already present."""
    if os.path.exists(DATASET30_DIR) and os.path.isfile(os.path.join(DATASET30_DIR, "DATA.json")):
        print(f"Dataset already exists at: {DATASET30_DIR}")
        return DATASET30_DIR
    
    print("Downloading dataset via kagglehub...")
    path = kagglehub.dataset_download(
        "fernando2rad/brain-tumor-mri-images-30-classes",
        output_dir=DATASET30_DIR
    )
    print(f"Dataset downloaded to: {path}")
    return DATASET30_DIR

def ensure_dataset4():
    """Download the 30-classes dataset via kagglehub into ./dataset/ if not already present."""
    if os.path.exists(DATASET4_DIR) and os.path.isfile(os.path.join(DATASET4_DIR, "DATA.json")):
        print(f"Dataset already exists at: {DATASET4_DIR}")
        return DATASET4_DIR
    
    print("Downloading dataset via kagglehub...")
    path = kagglehub.dataset_download(
        "alaminbhuyan/mri-image-data",
        output_dir=DATASET4_DIR
    )
    print(f"Dataset downloaded to: {path}")
    return DATASET4_DIR

if __name__ == "__main__":
    ensure_dataset30()
    ensure_dataset4()