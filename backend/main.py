from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
import tempfile
import shutil
import os
from database import engine, Base
from routes.auth import router as auth_router
from routes.patients import router as patients_router
from routes.analysis import router as analysis_router

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="MRI Analysis API",
    description="API for MRI analysis with doctor and patient management",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router)
app.include_router(patients_router)
app.include_router(analysis_router)

# Load model once at startup
predict_model = load_model("ai/trained/MRI_ENSEMBLED.keras")

# Your classes
diagnoses = ['glioma', 'meningioma', 'notumor', 'pituitary']


def make_prediction(path_to_img: str) -> dict:
    # Load and preprocess image
    img_to_predict = image.load_img(path_to_img, target_size=(256, 256))
    img_array = image.img_to_array(img_to_predict)
    img_array = img_array / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    # Predict (logits)
    pred = predict_model.predict(img_array)  # shape (1, 4)

    # Apply softmax to get probabilities
    probs = np.exp(pred) / np.sum(np.exp(pred), axis=1, keepdims=True)

    # Round probabilities to 2 decimals
    probs_rounded = np.round(probs[0], 4)  # shape (4,)

    # Get predicted class
    res_index = int(np.argmax(pred[0]))
    predicted_class = diagnoses[res_index]

    print(probs_rounded)

    # Return dictionary with class + probs
    return {
        "predicted_class": predicted_class,
        "probabilities": {
            diagnoses[i]: float(probs_rounded[i]) for i in range(len(diagnoses))
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.post("/predict")
async def predict_image(file: UploadFile = File(...)):
    # Validate image type
    if file.content_type not in ["image/jpeg", "image/png", "image/jpg", "image/webp"]:
        raise HTTPException(status_code=400, detail="Invalid image type")

    # Save uploaded file to a temporary location
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            shutil.copyfileobj(file.file, tmp)
            tmp_path = tmp.name

            # convert to jpg if necessary
            # if file.content_type != "image/jpeg":
            #     from PIL import Image
            #     img = Image.open(tmp_path)
            #     jpg_path = tmp_path.rsplit('.', 1)[0] + ".jpg"
            #     img.convert("RGB").save(jpg_path, "JPEG")
            #     tmp_path = jpg_path
    finally:
        file.file.close()

    # Run prediction
    result = make_prediction(tmp_path)

    return {
        "filename": file.filename,
        "prediction": result
    }

