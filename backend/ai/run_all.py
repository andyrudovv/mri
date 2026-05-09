import os


if not os.path.exists("trained/MRI_VGG16_Tuned_Base.keras"):
    os.system("python train_vgg16.py")
if not os.path.exists("trained/MRI_ResNet50V2_Tuned_Base.keras"):
    os.system("python train_resnet50v2.py")
if not os.path.exists("trained/MRI_CNN_Base.keras"):
    os.system("python train_cnn.py")
if not os.path.exists("trained/MRI_ENSEMBLED.keras"):
    os.system("python train_ensemble.py")
