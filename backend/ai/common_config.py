import os
import numpy as np

MAIN_DATASET_DIR = "./dataset/"
CATEGORIES = os.listdir(MAIN_DATASET_DIR + "Training")
MAIN_LABELS = np.array(CATEGORIES)

IMG_SIZE = (256, 256)
BATCH_SIZE = 32
NUM_CLASSES = 4
