from tensorflow.keras.layers import *
from tensorflow.keras.models import Model
from augmentations import augment_input

def build_cnn_model():
    inp = Input((256, 256, 3))
    x = augment_input(inp)

    # Example CNN
    for filters in [32, 64, 128, 256, 512]:
        x = Conv2D(filters, 3, padding="same", activation="relu")(x)
        x = Conv2D(filters, 3, padding="same", activation="relu")(x)
        x = MaxPooling2D(2)(x)
        x = BatchNormalization()(x)

    base = Model(inp, x)
    x = Flatten()(x)
    x = Dense(1024, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    out = Dense(4, activation="linear")(x)

    return Model(inp, out), base
