from tensorflow.keras.applications import ResNet50V2
from tensorflow.keras.layers import *
from tensorflow.keras.models import Model
from augmentations import augment_input

def build_resnet_model():
    base = ResNet50V2(weights="imagenet", include_top=False, input_shape=(256, 256, 3))
    base.trainable = False

    inp = Input((256, 256, 3))
    x = augment_input(inp)
    x = base(x)
    x = Flatten()(x)
    x = BatchNormalization()(x)
    x = Dense(1024, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    out = Dense(4, activation="linear")(x)

    return Model(inp, out), base
