import tensorflow as tf
from tensorflow.keras.layers import *
from tensorflow.keras.models import *
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import *
from sklearn.metrics import classification_report
from tensorflow.keras.losses import CategoricalCrossentropy
from tensorflow.keras.preprocessing import image_dataset_from_directory
import numpy as np
import os


DATA_DIR = "./dataset/"
CHECKPOINT = "./Checkpoints/model_cnn_binarized.keras"

categories = os.listdir(DATA_DIR + "Training")
class_names = np.array(categories)


print("\n\nCNN BINARIZED model training started\n\n")

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
    batch_size=32,
    shuffle=True,
).map(lambda x, y: (x / 255., y))


# --------------------
# Binarization function
# --------------------
def binarization(img):
    return tf.where(img > tf.reduce_mean(img) * 1.5, 1., 0.)


# --------------------
# Custom CNN w/ binarization
# --------------------
def build_cnn():
    inp = Input((256, 256, 3))
    x = RandomRotation(0.2)(inp)
    x = RandomZoom(0.1)(x)
    x = RandomContrast(0.2)(x)
    x = Lambda(binarization)(x)

    for filters in [32, 64, 128, 256, 512]:
        x = Conv2D(filters, 3, activation="relu", padding="same")(x)
        x = Conv2D(filters, 3, activation="relu", padding="same")(x)
        x = MaxPooling2D(2)(x)
        x = BatchNormalization()(x)

    base = Model(inp, x)

    x = Flatten()(x)
    x = Dense(1024, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    out = Dense(4, activation="linear")(x)

    return Model(inp, out), base


model, base = build_cnn()

model.compile(
    optimizer=Adam(),
    loss=CategoricalCrossentropy(from_logits=True),
    metrics=["accuracy"]
)

callbacks = [
    EarlyStopping(monitor="val_loss", patience=3, restore_best_weights=True, start_from_epoch=15),
    ModelCheckpoint(CHECKPOINT, save_best_only=True)
]


# --------------------
# Train
# --------------------
model.fit(train_ds, epochs=50, validation_data=val_ds, callbacks=callbacks)
model.evaluate(test_ds)

model.save("trained/MRI_CNN_Binarized.keras")
base.save("trained/MRI_CNN_Binarized_Base.keras")

model.save_weights("trained/MRI_CNN_Binarized.weights.h5")
base.save_weights("trained/MRI_CNN_Binarized_Base.weights.h5")

print("\n\nCNN BINARIZED model trained and saved\n\n")


# --------------------
# Classification report
# --------------------
for x, y in test_ds.unbatch().batch(100000):
    pass

pred = model.predict(x)
print(classification_report(
    class_names[np.argmax(y.numpy(), axis=-1)],
    class_names[np.argmax(pred, axis=-1)]
))
