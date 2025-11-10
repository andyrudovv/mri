import keras
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import classification_report
import tensorflow as tf
from tensorflow.keras.applications import *
from tensorflow.keras.callbacks import *
from tensorflow.keras.layers import *
from tensorflow.keras.losses import *
from tensorflow.keras.models import *
from tensorflow.keras.optimizers import *
from tensorflow.keras.preprocessing import image_dataset_from_directory
from tensorflow.keras.regularizers import *
import os

main_dataset_dir = "./dataset/"
categories = os.listdir(main_dataset_dir + "Training")
main_dataset_labels = np.array(categories)


train_dataset = image_dataset_from_directory(
    directory = main_dataset_dir + "Training",
    labels = "inferred",
    label_mode = "categorical",
    class_names = list(main_dataset_labels),
    color_mode = "rgb",
    batch_size = 32,
    image_size = (256, 256),
    shuffle = True,
    pad_to_aspect_ratio = True,
    validation_split = 0.2,
    subset = "training",
    seed = 74,
).map(
    lambda x, y: (x / 255., y)
)

validation_dataset = image_dataset_from_directory(
    directory = main_dataset_dir + "Training",
    labels = "inferred",
    label_mode = "categorical",
    class_names = list(main_dataset_labels),
    color_mode = "rgb",
    batch_size = 32,
    image_size = (256, 256),
    shuffle = True,
    pad_to_aspect_ratio = True,
    validation_split = 0.2,
    subset = "validation",
    seed = 74,
).map(
    lambda x, y: (x / 255., y)
)

test_dataset = image_dataset_from_directory(
    directory = main_dataset_dir + "Testing",
    labels = "inferred",
    label_mode = "categorical",
    class_names = list(main_dataset_labels),
    color_mode = "rgb",
    image_size = (256, 256),
    batch_size = 32,
    shuffle = True,
    pad_to_aspect_ratio = True    
).map(
    lambda x, y: (x / 255., y)
)


# plt.figure(figsize=(20, 10))
# i = 1
# for image, label in train_dataset.take(1).unbatch():
#     image = image.numpy()
#     label = main_dataset_labels[np.argmax(label.numpy())]
#     plt.subplot(4, 8, i)
#     plt.imshow(image)
#     plt.title(label)
#     plt.axis("off")
#     i += 1
# plt.show()


def VGG16_based_model():
    base_model = VGG16(
        weights = "imagenet", 
        input_shape = (256, 256, 3),
        include_top = False, 
    )

    base_model.trainable = False

    input = Input((256, 256, 3)) # pyright: ignore[reportUndefinedVariable]
    x = RandomRotation(factor=(-0.2, 0.2))(input) # type: ignore
    x = RandomZoom(height_factor=0.1, width_factor=0.1)(x)
    x = RandomContrast(factor= (0.8, 1.2))(x)
    x = base_model(input, training=False)
    x = Flatten()(x)
    x = BatchNormalization()(x)
    x = Dense(1024, activation="relu")(x)
    output = Dense(4, activation="linear")(x)
    
    return Model(inputs=input, outputs=output), base_model

model_1, base_models_1 = VGG16_based_model()
model_1.summary()


model_1.compile(loss = CategoricalCrossentropy(from_logits=True), optimizer=Adam(), metrics=["accuracy"])


checkpoint_file_path_1 = "./Checkpoints/model_1.keras"
callbacks_1 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 10,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_1,
        monitor = "val_loss",
        save_best_only = True,
    )
]


hist_1 = model_1.fit(train_dataset, epochs=50, callbacks=callbacks_1, validation_data=validation_dataset)

model_1.evaluate(test_dataset)

for layer in base_models_1.layers:
    layer.trainable = True

model_1.compile(loss = CategoricalCrossentropy(from_logits=True), optimizer=Adam(1e-5), metrics=["accuracy"])
hist_1_2 = model_1.fit(train_dataset, epochs=20, validation_data=validation_dataset, callbacks = callbacks_1)

model_1.evaluate(test_dataset)

model_1.save("MRI_VGG_16_Tuned.keras")
base_models_1.save("MRI_VGG_16_Tuned_Base.keras")

model_1.save_weights("MRI_VGG_16_Tuned.weights.h5")
base_models_1.save_weights("MRI_VGG_16_Tuned_Base.weights.h5")

def Resnet_based_model():
    base_model = ResNet50V2(
        weights = "imagenet", 
        input_shape = (256, 256, 3),
        include_top = False, 
    )

    base_model.trainable = False

    input = Input((256, 256, 3))
    x = RandomRotation(factor=(-0.2, 0.2))(input)
    x = RandomZoom(height_factor=0.1, width_factor=0.1)(x)
    x = RandomContrast(factor= (0.8, 1.2))(x)
    x = base_model(input, training=False)
    x = Flatten()(x)
    x = BatchNormalization()(x)
    x = Dense(1024, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    output = Dense(4, activation="linear")(x)
    
    return Model(inputs=input, outputs=output), base_model

model_2, base_models_2 = Resnet_based_model()
model_2.compile(loss = CategoricalCrossentropy(from_logits=True), optimizer=Adam(), metrics=["accuracy"])

checkpoint_file_path_2 = "./Checkpoints/model_2.keras"
callbacks_2 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 10,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_2,
        monitor = "val_loss",
        save_best_only = True,
    )
]

hist_2 = model_2.fit(train_dataset, epochs=50, callbacks=callbacks_2, validation_data=validation_dataset)

hist = hist_2.history
plt.plot(hist["loss"], label="Loss")
plt.plot(hist["val_loss"], label="Validation loss")
plt.title("Loss per epochs")
plt.legend()
plt.show()

model_2.evaluate(test_dataset)

for x, y in test_dataset.unbatch().batch(100000):
    pass
y_pred = model_2.predict(x)
print(classification_report(main_dataset_labels[np.argmax(y.numpy(), axis=-1)], main_dataset_labels[np.argmax(y_pred, axis=-1)]))

model_2.save("MRI_ResNet50V2_Tuned.keras")
base_models_2.save("MRI_ResNet50V2_Tuned_Base.keras")

model_2.save_weights("MRI_ResNet50V2_Tuned.weights.h5")
base_models_2.save_weights("MRI_ResNet50V2_Tuned_Base.weights.h5")

def binarization(image):
    return tf.where(image > tf.reduce_mean(image) * 1.5 , 1., 0.)

# plt.figure(figsize=(20, 10))
# i = 1
# for image, label in train_dataset.take(1).unbatch():
#     image = image.numpy()
#     label = main_dataset_labels[np.argmax(label.numpy())]
#     plt.subplot(4, 8, i)
#     plt.imshow(binarization(image).numpy())
#     plt.title(label)
#     plt.axis("off")
#     i += 1
# plt.show()


def CNN_based_model():
    input = Input((256, 256, 3))
    x = RandomRotation(factor=(-0.2, 0.2))(input)
    x = RandomZoom(height_factor=0.1, width_factor=0.1)(x)
    x = RandomContrast(factor= (0.8, 1.2))(x)
    x = Lambda(binarization, output_shape=(256, 256, 3))(x)
    x = Conv2D(32, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(32, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(64, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(64, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(128, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(128, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(256, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(256, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(512, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(512, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    base_model = Model(inputs=input, outputs=x)
    x = Flatten()(x)
    x = Dense(1024, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    output = Dense(4, activation="linear")(x)
    
    return Model(inputs=input, outputs=output), base_model

model_3, base_models_3 = CNN_based_model()
model_3.compile(loss = CategoricalCrossentropy(from_logits=True), optimizer=Adam(), metrics=["accuracy"])

checkpoint_file_path_3 = "./Checkpoints/model_3.keras"
callbacks_3 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 15,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_3,
        monitor = "val_loss",
        save_best_only = True,
    )
]

hist_3 = model_3.fit(train_dataset, epochs=50, callbacks=callbacks_3, validation_data=validation_dataset)

hist = hist_3.history
# plt.plot(hist["loss"], label="Loss")
# plt.plot(hist["val_loss"], label="Validation loss")
# plt.title("Loss per epochs")
# plt.legend()
# plt.show()

model_3.evaluate(test_dataset)

for x, y in test_dataset.unbatch().batch(100000):
    pass
y_pred = model_3.predict(x)
print(classification_report(main_dataset_labels[np.argmax(y.numpy(), axis=-1)], main_dataset_labels[np.argmax(y_pred, axis=-1)]))

model_3.save("MRI_CNN_Binarized.keras")
base_models_3.save("MRI_CNN_Binarized_Base.keras")

model_3.save_weights("MRI_CNN_Binarized.weights.h5")
base_models_3.save_weights("MRI_CNN_Binarized_Base.weights.h5")

def CNN_based_model_2():
    input = Input((256, 256, 3))
    x = RandomRotation(factor=(-0.2, 0.2))(input)
    x = RandomZoom(height_factor=0.1, width_factor=0.1)(x)
    x = RandomContrast(factor= (0.8, 1.2))(x)
    x = Conv2D(32, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(32, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(64, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(64, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(128, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(128, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(256, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(256, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    x = Conv2D(512, (3, 3), activation="relu", padding="same")(x)
    x = Conv2D(512, (3, 3), activation="relu", padding="same")(x)
    x = MaxPooling2D((2, 2))(x)
    x = BatchNormalization()(x)
    base_model = Model(inputs=input, outputs=x)
    x = Flatten()(x)
    x = Dense(1024, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    output = Dense(4, activation="linear")(x)
    
    return Model(inputs=input, outputs=output), base_model

model_4, base_models_4 = CNN_based_model_2()

model_4.compile(loss = CategoricalCrossentropy(from_logits=True), optimizer=Adam(), metrics=["accuracy"])

checkpoint_file_path_4 = "./Checkpoints/model_4.keras"
callbacks_4 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 15,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_4,
        monitor = "val_loss",
        save_best_only = True,
    )
]

hist_4 = model_4.fit(train_dataset, epochs=50, callbacks=callbacks_4, validation_data=validation_dataset)

hist = hist_4.history
# plt.plot(hist["loss"], label="Loss")
# plt.plot(hist["val_loss"], label="Validation loss")
# plt.title("Loss per epochs")
# plt.legend()
# plt.show()

model_4.evaluate(test_dataset)

for x, y in test_dataset.unbatch().batch(100000):
    pass
y_pred = model_4.predict(x)
print(classification_report(main_dataset_labels[np.argmax(y.numpy(), axis=-1)], main_dataset_labels[np.argmax(y_pred, axis=-1)]))

base_models_1.summary()
base_models_2.summary()

base_models_4.trainable = False
base_models_4.summary()


def ensembled_model():
    input = Input((256, 256, 3))
    x = RandomRotation(factor=(-0.2, 0.2))(input)
    x = RandomZoom(height_factor=0.1, width_factor=0.1)(x)
    x = RandomContrast(factor= (0.8, 1.2))(x)
    features_1 = base_models_1(x)
    features_1 = BatchNormalization()(features_1)
    features_2 = base_models_2(x)
    features_2 = Conv2D(512, (1, 1), padding="same", activation="relu", name="Resnet50V2_reshaped")(features_2)
    features_2 = BatchNormalization()(features_2)
    features_3 = base_models_4(x, training=False)
    features_3 = BatchNormalization()(features_3)
    concat = Concatenate()([features_1, features_2, features_3])
    x = GlobalAveragePooling2D()(concat)
    x = Dense(512, activation="relu")(x)
    x = BatchNormalization()(x)
    x = Dropout(0.25)(x)
    output = Dense(4, activation="linear")(x)
    return Model(inputs=input, outputs=output)
    
model_5 = ensembled_model()
model_5.summary()

model_5.compile(loss = CategoricalCrossentropy(from_logits=True), optimizer=Adam(), metrics=["accuracy"])

checkpoint_file_path_5 = "./Checkpoints/model_5.keras"
callbacks_5 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 15,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_5,
        monitor = "val_loss",
        save_best_only = True,
    )
]
hist_5 = model_5.fit(train_dataset, epochs=50, callbacks=callbacks_5, validation_data=validation_dataset)
hist = hist_5.history
# plt.plot(hist["loss"], label="Loss")
# plt.plot(hist["val_loss"], label="Validation loss")
# plt.title("Loss per epochs")
# plt.ylim([0, 1])
# plt.legend()
# plt.show()

model_5.evaluate(test_dataset)
checkpoint_file_path_5_1 = "./Checkpoints/model_5_1.keras"
callbacks_5_1 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 40,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_5_1,
        monitor = "val_loss",
        save_best_only = True,
    )
]

hist_5_1 = model_5.fit(train_dataset, epochs=50, callbacks=callbacks_5_1, validation_data=validation_dataset)
model_5.evaluate(test_dataset)

hist = hist_5_1.history
# plt.plot(hist["loss"], label="Loss")
# plt.plot(hist["val_loss"], label="Validation loss")
# plt.title("Loss per epochs")
# plt.legend()
# plt.show()

def schedule_5_2(epochs, lr):
    if epochs % 5 == 0:
        return lr * 0.8
    return lr
checkpoint_file_path_5_2 = "./Checkpoints/model_5_2.keras"
callbacks_5_2 = [
    EarlyStopping(
        monitor = "val_loss", 
        min_delta = 1e-3, 
        patience = 3,
        start_from_epoch = 10,
        restore_best_weights = True, 
    ),
    ModelCheckpoint(
        filepath = checkpoint_file_path_5_2,
        monitor = "val_loss",
        save_best_only = True,
    ),
    LearningRateScheduler(
        schedule_5_2,
        verbose=True
    )
]

hist_5_2 = model_5.fit(train_dataset, epochs=50, callbacks=callbacks_5_2, validation_data=validation_dataset)

hist = hist_5_2.history
# plt.plot(hist["loss"], label="Loss")
# plt.plot(hist["val_loss"], label="Validation loss")
# plt.title("Loss per epochs")
# plt.legend()
# plt.show()

model_5.evaluate(test_dataset)

for x, y in test_dataset.unbatch().batch(100000):
    pass
y_pred = model_5.predict(x)
print(classification_report(main_dataset_labels[np.argmax(y.numpy(), axis=-1)], main_dataset_labels[np.argmax(y_pred, axis=-1)]))

model_5.save("MRI_ensembled_CNN+VGG16+ResNet50V2.keras")
model_5.save_weights("MRI_ensembled_CNN+VGG16+ResNet50V2.weights.h5")


counts = tf.Variable([0, 0, 0, 0], dtype=tf.float32)
for _, label in train_dataset.unbatch().take(-1):
    counts.assign_add(label)


def visualize_result(dataset):
    plt.figure(figsize=(20, 12))
    i = 1
    for image, label in dataset.take(1).unbatch().take(32):
        image = image.numpy()
        label = main_dataset_labels[np.argmax(label.numpy())]
        predicted_label = main_dataset_labels[np.argmax(model_5.predict(np.reshape(image, (1,) + image.shape), verbose=False))]
        plt.subplot(4, 8, i)
        plt.imshow(image)
        plt.title(f"Label: {label}\nPredicted: {predicted_label}")
        plt.axis("off")
        i += 1
    plt.show()

visualize_result(test_dataset)