import tensorflow as tf
from tensorflow.keras.preprocessing import image_dataset_from_directory
from common_config import MAIN_DATASET_DIR, MAIN_LABELS, IMG_SIZE, BATCH_SIZE

def load_datasets():
    train_dataset = image_dataset_from_directory(
        MAIN_DATASET_DIR + "Training",
        labels="inferred",
        label_mode="categorical",
        class_names=list(MAIN_LABELS),
        color_mode="rgb",
        batch_size=BATCH_SIZE,
        image_size=IMG_SIZE,
        shuffle=True,
        pad_to_aspect_ratio=True,
        validation_split=0.2,
        subset="training",
        seed=74,
    ).map(lambda x, y: (x / 255., y))

    validation_dataset = image_dataset_from_directory(
        MAIN_DATASET_DIR + "Training",
        labels="inferred",
        label_mode="categorical",
        class_names=list(MAIN_LABELS),
        color_mode="rgb",
        batch_size=BATCH_SIZE,
        image_size=IMG_SIZE,
        shuffle=True,
        pad_to_aspect_ratio=True,
        validation_split=0.2,
        subset="validation",
        seed=74,
    ).map(lambda x, y: (x / 255., y))

    test_dataset = image_dataset_from_directory(
        MAIN_DATASET_DIR + "Testing",
        labels="inferred",
        label_mode="categorical",
        class_names=list(MAIN_LABELS),
        color_mode="rgb",
        batch_size=BATCH_SIZE,
        image_size=IMG_SIZE,
        shuffle=True,
        pad_to_aspect_ratio=True  
    ).map(lambda x, y: (x / 255., y))

    return train_dataset, validation_dataset, test_dataset
