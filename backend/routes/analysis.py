from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, status
from sqlalchemy.orm import Session
from database import get_db
from models import Patient, MRIAnalysis, Doctor
from schemas import MRIAnalysisResponse
from dependencies import get_current_doctor, get_current_patient
import tempfile
import shutil
import json
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
import os

router = APIRouter(prefix="/api/analysis", tags=["MRI Analysis"])

# Load model once at startup
predict_model = None

diagnoses = ['glioma', 'meningioma', 'notumor', 'pituitary']


def load_prediction_model():
    """Load the prediction model"""
    global predict_model
    if predict_model is None:
        model_path = "ai/trained/MRI_ENSEMBLED.keras"
        if os.path.exists(model_path):
            predict_model = load_model(model_path)
        else:
            raise RuntimeError("Model file not found")
    return predict_model


def make_prediction(path_to_img: str) -> dict:
    """Make prediction on an MRI image"""
    model = load_prediction_model()
    
    # Load and preprocess image
    img_to_predict = image.load_img(path_to_img, target_size=(256, 256))
    img_array = image.img_to_array(img_to_predict)
    img_array = img_array / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    # Predict
    pred = model.predict(img_array)

    # Apply softmax to get probabilities
    probs = np.exp(pred) / np.sum(np.exp(pred), axis=1, keepdims=True)
    probs_rounded = np.round(probs[0], 4)

    # Get predicted class
    res_index = int(np.argmax(pred[0]))
    predicted_class = diagnoses[res_index]

    return {
        "predicted_class": predicted_class,
        "probabilities": {
            diagnoses[i]: float(probs_rounded[i]) for i in range(len(diagnoses))
        }
    }


@router.post("/predict/{patient_id}", response_model=MRIAnalysisResponse)
async def analyze_mri(
    patient_id: int,
    file: UploadFile = File(...),
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Analyze an MRI image for a specific patient"""
    
    # Verify patient belongs to current doctor
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()
    
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    # Validate image type
    if file.content_type not in ["image/jpeg", "image/png", "image/jpg", "image/webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image type. Supported: JPEG, PNG, WebP"
        )
    
    # Save uploaded file to temporary location
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            shutil.copyfileobj(file.file, tmp)
            tmp_path = tmp.name
    finally:
        file.file.close()
    
    try:
        # Make prediction
        prediction_result = make_prediction(tmp_path)

        # Save analysis to database
        analysis = MRIAnalysis(
            patient_id=patient_id,
            image_path=tmp_path,
            predicted_class=prediction_result["predicted_class"],
            probabilities=json.dumps(prediction_result["probabilities"])
        )

        # Update patient's disease field with the predicted class
        patient.disease = prediction_result["predicted_class"]

        db.add(analysis)
        db.commit()
        db.refresh(analysis)

        # Return response with parsed probabilities
        return MRIAnalysisResponse(
            id=analysis.id,
            patientId=analysis.patient_id,
            imagePath=analysis.image_path,
            predictedClass=analysis.predicted_class,
            probabilities=analysis.probabilities,
            createdAt=analysis.created_at.isoformat()
        )

    finally:
        # Clean up temporary file
        try:
            os.remove(tmp_path)
        except:
            pass


@router.get("/patient/{patient_id}", response_model=list)
async def get_patient_analyses(
    patient_id: int,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Get all analyses for a specific patient"""

    # Verify patient belongs to current doctor
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )

    analyses = db.query(MRIAnalysis).filter(
        MRIAnalysis.patient_id == patient_id
    ).order_by(MRIAnalysis.created_at.desc()).all()

    return [
        {
            "id": a.id,
            "patientId": a.patient_id,
            "imagePath": a.image_path,
            "predictedClass": a.predicted_class,
            "probabilities": a.probabilities,
            "createdAt": a.created_at.isoformat(),
        }
        for a in analyses
    ]


@router.post("/predict-patient", response_model=MRIAnalysisResponse)
async def analyze_mri_for_patient(
    file: UploadFile = File(...),
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    """Analyze an MRI image for the current authenticated patient (self-service)"""

    # Validate image type
    if file.content_type not in ["image/jpeg", "image/png", "image/jpg", "image/webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image type. Supported: JPEG, PNG, WebP"
        )

    # Save uploaded file to temporary location
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            shutil.copyfileobj(file.file, tmp)
            tmp_path = tmp.name
    finally:
        file.file.close()

    try:
        # Make prediction
        prediction_result = make_prediction(tmp_path)

        # Save analysis to database
        analysis = MRIAnalysis(
            patient_id=current_patient.id,
            image_path=tmp_path,
            predicted_class=prediction_result["predicted_class"],
            probabilities=json.dumps(prediction_result["probabilities"])
        )

        # Update patient's disease field with the predicted class
        current_patient.disease = prediction_result["predicted_class"]

        db.add(analysis)
        db.commit()
        db.refresh(analysis)

        # Return response with parsed probabilities
        return MRIAnalysisResponse(
            id=analysis.id,
            patientId=analysis.patient_id,
            imagePath=analysis.image_path,
            predictedClass=analysis.predicted_class,
            probabilities=analysis.probabilities,
            createdAt=analysis.created_at.isoformat()
        )

    finally:
        # Clean up temporary file
        try:
            os.remove(tmp_path)
        except:
            pass


@router.get("/my-analyses", response_model=list)
async def get_my_analyses(
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    """Get all analyses for the current authenticated patient"""

    analyses = db.query(MRIAnalysis).filter(
        MRIAnalysis.patient_id == current_patient.id
    ).order_by(MRIAnalysis.created_at.desc()).all()

    return [
        {
            "id": a.id,
            "patientId": a.patient_id,
            "imagePath": a.image_path,
            "predictedClass": a.predicted_class,
            "probabilities": a.probabilities,
            "createdAt": a.created_at.isoformat(),
        }
        for a in analyses
    ]
