import tensorflow as tf
from tensorflow.keras.applications import VGG16
from tensorflow.keras.layers import *
from tensorflow.keras.models import *
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.losses import CategoricalCrossentropy
from tensorflow.keras.callbacks import *
from tensorflow.keras.preprocessing import image_dataset_from_directory
from sklearn.metrics import classification_report
import numpy as np
import os


DATA_DIR = "./dataset/"
CHECKPOINT_PATH = "./Checkpoints/model_vgg16.keras"


# --------------------
# Load Dataset
# --------------------
categories = os.listdir(DATA_DIR + "Training")
class_names = np.array(categories)

print("\n\nVGG16 model training started\n\n")

train_ds = image_dataset_from_directory(
    DATA_DIR + "Training",
    labels="inferred",
    label_mode="categorical",
    class_names=list(class_names),
    image_size=(256, 256),
    batch_size=32,
    shuffle=True,
    validation_split=0.2,
    subset="training",
    seed=74,
).map(lambda x, y: (x / 255., y))

val_ds = image_dataset_from_directory(
    DATA_DIR + "Training",
    labels="inferred",
    label_mode="categorical",
    class_names=list(class_names),
    image_size=(256, 256),
    batch_size=32,
    shuffle=True,
    validation_split=0.2,
    subset="validation",
    seed=74,
).map(lambda x, y: (x / 255., y))

test_ds = image_dataset_from_directory(
    DATA_DIR + "Testing",
    labels="inferred",
    label_mode="categorical",
    class_names=list(class_names),
    image_size=(256, 256),
    batch_size=32
).map(lambda x, y: (x / 255., y))


# --------------------
# VGG16 Model
# --------------------
def build_vgg16():
    base_model = VGG16(weights="imagenet", include_top=False, input_shape=(256, 256, 3))
    base_model.trainable = False

    inp = Input((256, 256, 3))
    x = RandomRotation(0.2)(inp)
    x = RandomZoom(0.1)(x)
    x = RandomContrast(0.2)(x)

    x = base_model(x, training=False)
    x = Flatten()(x)
    x = BatchNormalization()(x)
    x = Dense(1024, activation="relu")(x)
    out = Dense(4, activation="linear")(x)

    return Model(inp, out), base_model


model, base_model = build_vgg16()
model.compile(
    loss=CategoricalCrossentropy(from_logits=True),
    optimizer=Adam(),
    metrics=["accuracy"]
)

callbacks = [
    EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True, start_from_epoch=10),
    ModelCheckpoint(CHECKPOINT_PATH, monitor="val_loss", save_best_only=True)
]

# --------------------
# Train (Frozen)
# --------------------
model.fit(train_ds, epochs=50, validation_data=val_ds, callbacks=callbacks)
model.evaluate(test_ds)

# --------------------
# Fine-tune
# --------------------
for layer in base_model.layers:
    layer.trainable = True

model.compile(
    optimizer=Adam(1e-5),
    loss=CategoricalCrossentropy(from_logits=True),
    metrics=["accuracy"]
)

model.fit(train_ds, epochs=20, validation_data=val_ds, callbacks=callbacks)

# --------------------
# Save
# --------------------
model.save("trained/MRI_VGG16_Tuned.keras")
base_model.save("trained/MRI_VGG16_Tuned_Base.keras")

model.save_weights("trained/MRI_VGG16_Tuned.weights.h5")
base_model.save_weights("trained/MRI_VGG16_Tuned_Base.weights.h5")


print("\n\nVGG16 model trained and saved\n\n")

# --------------------
# Evaluation Report
# --------------------
for x, y in test_ds.unbatch().batch(100000):
    pass

pred = model.predict(x)
print(classification_report(
    class_names[np.argmax(y.numpy(), axis=-1)],
    class_names[np.argmax(pred, axis=-1)]
))
