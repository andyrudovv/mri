from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint

def get_callbacks(model_name, start_epoch=10):
    return [
        EarlyStopping(
            monitor="val_loss",
            min_delta=1e-3,
            patience=3,
            start_from_epoch=start_epoch,
            restore_best_weights=True
        ),
        ModelCheckpoint(
            filepath=f"./Checkpoints/{model_name}.keras",
            monitor="val_loss",
            save_best_only=True
        )
    ]
