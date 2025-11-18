import tensorflow as tf
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
CHECKPOINT = "./Checkpoints/model_ensemble.keras"

categories = os.listdir(DATA_DIR + "Training")
class_names = np.array(categories)


train_ds = image_dataset_from_directory(
    DATA_DIR + "Training",
    label_mode="categorical",
    class_names=list(class_names),
    image_size=(256, 256),
    batch_size=32,
    validation_split=0.2,
    subset="training",
    seed=74,
).map(lambda x, y: (x / 255., y))

val_ds = image_dataset_from_directory(
    DATA_DIR + "Training",
    label_mode="categorical",
    class_names=list(class_names),
    image_size=(256, 256),
    batch_size=32,
    validation_split=0.2,
    subset="validation",
    seed=74,
).map(lambda x, y: (x / 255., y))

test_ds = image_dataset_from_directory(
    DATA_DIR + "Testing",
    label_mode="categorical",
    class_names=list(class_names),
    image_size=(256, 256),
    batch_size=32,
).map(lambda x, y: (x / 255., y))


# --------------------
# Load pretrained base models
# --------------------
vgg_base = tf.keras.models.load_model("trained/MRI_VGG16_Tuned_Base.keras")
resnet_base = tf.keras.models.load_model("trained/MRI_ResNet50V2_Tuned_Base.keras")
cnn_base = tf.keras.models.load_model("trained/MRI_CNN_Base.keras")

vgg_base.trainable = False
resnet_base.trainable = False
cnn_base.trainable = False


# --------------------
# Ensemble Model
# --------------------
def build_ensemble():
    inp = Input((256, 256, 3))

    x = RandomRotation(0.2)(inp)
    x = RandomZoom(0.1)(x)
    x = RandomContrast(0.2)(x)

    f1 = BatchNormalization()(vgg_base(x))
    f2 = BatchNormalization()(Conv2D(512, 1, activation="relu")(resnet_base(x)))
    f3 = BatchNormalization()(cnn_base(x))

    merged = Concatenate()([f1, f2, f3])
    x = GlobalAveragePooling2D()(merged)
    x = Dense(512, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    out = Dense(4, activation="linear")(x)

    return Model(inp, out)


model = build_ensemble()
model.compile(
    loss=CategoricalCrossentropy(from_logits=True),
    optimizer=Adam(),
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


# --------------------
# Save
# --------------------
model.save("trained/MRI_ENSEMBLED.keras")
model.save_weights("trained/MRI_ENSEMBLED.weights.h5")


# --------------------
# Classification Report
# --------------------
for x, y in test_ds.unbatch().batch(100000):
    pass

pred = model.predict(x)
print(classification_report(
    class_names[np.argmax(y.numpy(), axis=-1)],
    class_names[np.argmax(pred, axis=-1)]
))
