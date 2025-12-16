from tensorflow.keras.layers import RandomRotation, RandomZoom, RandomContrast

def augment_input(input_layer):
    x = RandomRotation((-0.2, 0.2))(input_layer)
    x = RandomZoom(0.1, 0.1)(x)
    x = RandomContrast((0.8, 1.2))(x)
    return x
