from tensorflow.keras.layers import *
from tensorflow.keras.models import Model
from augmentations import augment_input

def build_ensemble(base1, base2, base3):
    inp = Input((256, 256, 3))
    x = augment_input(inp)

    f1 = BatchNormalization()(base1(x))
    f2 = BatchNormalization()(Conv2D(512, 1, activation="relu")(base2(x)))
    f3 = BatchNormalization()(base3(x))

    merged = Concatenate()([f1, f2, f3])
    merged = GlobalAveragePooling2D()(merged)
    merged = Dense(512, activation="relu")(merged)
    merged = BatchNormalization()(merged)
    merged = Dropout(0.25)(merged)

    out = Dense(4, activation="linear")(merged)
    return Model(inp, out)
