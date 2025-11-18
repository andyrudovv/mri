from tensorflow.keras.applications import VGG16
from tensorflow.keras.layers import Input, Flatten, Dense, BatchNormalization
from tensorflow.keras.models import Model
from augmentations import augment_input

def build_vgg16_model():
    base = VGG16(weights="imagenet", include_top=False, input_shape=(256, 256, 3))
    base.trainable = False

    inp = Input((256, 256, 3))
    x = augment_input(inp)
    x = base(x, training=False)
    x = Flatten()(x)
    x = BatchNormalization()(x)
    x = Dense(1024, activation="relu")(x)
    out = Dense(4, activation="linear")(x)

    return Model(inp, out), base
