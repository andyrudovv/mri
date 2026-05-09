from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from database import get_db
from models import Patient, MRIAnalysis, Doctor
from schemas import MRIAnalysisResponse
from dependencies import get_current_doctor, get_current_patient
import tempfile
import shutil
import json
import uuid
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
import os
from PIL import Image as PILImage

router = APIRouter(prefix="/api/analysis", tags=["MRI Analysis"])

predict_model = None
diagnoses = ['glioma', 'meningioma', 'notumor', 'pituitary']

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

DISEASE_DESCRIPTIONS = {
    "glioma": {
        "name": "Glioma",
        "description": "Glioma is a type of tumor that originates in the glial cells of the brain or spinal cord. Glial cells surround and support neurons.",
        "details": "Gliomas account for about 33% of all brain tumors. They can be identified on MRI scans by irregular, heterogeneous masses that often show contrast enhancement. The tumor typically appears as a region of abnormal signal intensity, with surrounding edema visible as bright areas on T2-weighted images. Gliomas may infiltrate surrounding brain tissue, making their borders less distinct compared to other tumor types.",
        "severity": "Varies from low-grade (slow-growing) to high-grade (aggressive, e.g., glioblastoma)",
    },
    "meningioma": {
        "name": "Meningioma",
        "description": "Meningioma is a tumor that arises from the meninges, the membranes that surround the brain and spinal cord. It is usually benign.",
        "details": "Meningiomas are the most common primary brain tumors, accounting for about 30% of all brain tumors. On MRI, they appear as well-defined, homogeneously enhancing extra-axial masses attached to the dura. A characteristic 'dural tail' sign (thickening of adjacent dura) is often visible. The tumor compresses adjacent brain tissue rather than infiltrating it, and calcifications may be present.",
        "severity": "Most are benign (WHO Grade I), but atypical and malignant variants exist",
    },
    "pituitary": {
        "name": "Pituitary Tumor",
        "description": "Pituitary tumors (pituitary adenomas) are abnormal growths in the pituitary gland, located at the base of the brain.",
        "details": "Pituitary adenomas are typically benign and account for 10-15% of all intracranial tumors. On MRI, they appear as lesions in the sella turcica region. Microadenomas (<10mm) may show as hypointense areas within the gland, while macroadenomas (>10mm) can extend beyond the sella, potentially compressing the optic chiasm. They may cause hormonal imbalances depending on which hormone-producing cells are affected.",
        "severity": "Usually benign; may cause hormonal dysfunction or vision problems if large",
    },
    "notumor": {
        "name": "No Tumor Detected",
        "description": "The MRI scan analysis did not detect any tumor formations in the brain tissue.",
        "details": "The brain structures appear within normal limits based on the AI analysis. The scan does not show the characteristic patterns associated with glioma, meningioma, or pituitary tumors. However, this automated analysis should always be confirmed by a qualified radiologist or neurologist, as some conditions may not be detectable by the current model.",
        "severity": "No tumor pathology detected",
    },
}


def generate_ai_summary(predicted_class: str, probabilities: dict) -> str:
    info = DISEASE_DESCRIPTIONS.get(predicted_class, {})
    confidence = probabilities.get(predicted_class, 0) * 100
    name = info.get("name", predicted_class)
    description = info.get("description", "")
    details = info.get("details", "")
    severity = info.get("severity", "")

    if predicted_class == "notumor":
        summary = (
            f"Analysis Result: No Tumor Detected (confidence: {confidence:.1f}%).\n\n"
            f"{description}\n\n"
            f"{details}\n\n"
            f"Note: {severity}."
        )
    else:
        other_probs = {k: v for k, v in probabilities.items() if k != predicted_class}
        other_text = ", ".join(
            f"{DISEASE_DESCRIPTIONS.get(k, {}).get('name', k)}: {v*100:.1f}%"
            for k, v in sorted(other_probs.items(), key=lambda x: -x[1])
        )
        summary = (
            f"Analysis Result: {name} detected with {confidence:.1f}% confidence.\n\n"
            f"{description}\n\n"
            f"{details}\n\n"
            f"Severity: {severity}.\n\n"
            f"Other probabilities: {other_text}.\n\n"
            f"Important: This is an AI-assisted analysis. Please consult a qualified specialist for confirmation and treatment planning."
        )
    return summary


def load_prediction_model():
    global predict_model
    if predict_model is None:
        model_path = "ai/trained/MRI_ENSEMBLED.keras"
        if os.path.exists(model_path):
            predict_model = load_model(model_path)
        else:
            raise RuntimeError("Model file not found")
    return predict_model


def convert_dicom_to_png(dicom_path: str) -> str:
    try:
        import pydicom
        ds = pydicom.dcmread(dicom_path)
        pixel_array = ds.pixel_array.astype(float)
        pixel_array = (pixel_array - pixel_array.min()) / (pixel_array.max() - pixel_array.min() + 1e-8) * 255
        pixel_array = pixel_array.astype(np.uint8)
        img = PILImage.fromarray(pixel_array)
        if img.mode != "RGB":
            img = img.convert("RGB")
        png_path = dicom_path.rsplit(".", 1)[0] + ".png"
        img.save(png_path, "PNG")
        return png_path
    except ImportError:
        raise HTTPException(status_code=500, detail="pydicom not installed")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to process DICOM file: {str(e)}")


def save_upload_permanently(file_path: str, original_filename: str) -> str:
    ext = os.path.splitext(original_filename)[1] or ".jpg"
    if ext.lower() == ".dcm":
        ext = ".png"
    unique_name = f"{uuid.uuid4().hex}{ext}"
    dest = os.path.join(UPLOAD_DIR, unique_name)
    shutil.copy2(file_path, dest)
    return unique_name


def make_prediction(path_to_img: str) -> dict:
    model = load_prediction_model()

    img_to_predict = image.load_img(path_to_img, target_size=(256, 256))
    img_array = image.img_to_array(img_to_predict)
    img_array = img_array / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    pred = model.predict(img_array)
    probs = np.exp(pred) / np.sum(np.exp(pred), axis=1, keepdims=True)
    probs_rounded = np.round(probs[0], 4)

    res_index = int(np.argmax(pred[0]))
    predicted_class = diagnoses[res_index]

    probabilities = {diagnoses[i]: float(probs_rounded[i]) for i in range(len(diagnoses))}
    ai_summary = generate_ai_summary(predicted_class, probabilities)

    return {
        "predicted_class": predicted_class,
        "probabilities": probabilities,
        "ai_summary": ai_summary,
    }


ALLOWED_CONTENT_TYPES = [
    "image/jpeg", "image/png", "image/jpg", "image/webp",
    "application/dicom", "application/octet-stream",
]


def _process_upload(file: UploadFile) -> str:
    """Save upload to temp, handle DICOM conversion if needed, return path to processable image."""
    is_dicom = (
        file.content_type in ("application/dicom", "application/octet-stream")
        or (file.filename and file.filename.lower().endswith(".dcm"))
    )

    suffix = ".dcm" if is_dicom else ".jpg"
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            shutil.copyfileobj(file.file, tmp)
            tmp_path = tmp.name
    finally:
        file.file.close()

    if is_dicom:
        png_path = convert_dicom_to_png(tmp_path)
        try:
            os.remove(tmp_path)
        except OSError:
            pass
        return png_path

    return tmp_path


@router.post("/predict/{patient_id}", response_model=MRIAnalysisResponse)
async def analyze_mri(
    patient_id: int,
    file: UploadFile = File(...),
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    tmp_path = _process_upload(file)

    try:
        prediction_result = make_prediction(tmp_path)
        saved_name = save_upload_permanently(tmp_path, file.filename or "mri.jpg")

        analysis = MRIAnalysis(
            patient_id=patient_id,
            image_path=saved_name,
            predicted_class=prediction_result["predicted_class"],
            probabilities=json.dumps(prediction_result["probabilities"])
        )

        patient.disease = prediction_result["predicted_class"]

        db.add(analysis)
        db.commit()
        db.refresh(analysis)

        return MRIAnalysisResponse(
            id=analysis.id,
            patientId=analysis.patient_id,
            imagePath=analysis.image_path,
            predictedClass=analysis.predicted_class,
            probabilities=prediction_result["probabilities"],
            aiSummary=prediction_result["ai_summary"],
            createdAt=analysis.created_at.isoformat()
        )
    finally:
        try:
            os.remove(tmp_path)
        except OSError:
            pass


@router.get("/patient/{patient_id}", response_model=list)
async def get_patient_analyses(
    patient_id: int,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    analyses = db.query(MRIAnalysis).filter(
        MRIAnalysis.patient_id == patient_id
    ).order_by(MRIAnalysis.created_at.desc()).all()

    results = []
    for a in analyses:
        probs = a.probabilities
        if isinstance(probs, str):
            try:
                probs = json.loads(probs)
            except Exception:
                probs = {}
        ai_summary = generate_ai_summary(a.predicted_class, probs if isinstance(probs, dict) else {})
        results.append({
            "id": a.id,
            "patientId": a.patient_id,
            "imagePath": a.image_path,
            "predictedClass": a.predicted_class,
            "probabilities": probs,
            "aiSummary": ai_summary,
            "createdAt": a.created_at.isoformat(),
        })

    return results


@router.post("/predict-patient", response_model=MRIAnalysisResponse)
async def analyze_mri_for_patient(
    file: UploadFile = File(...),
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    tmp_path = _process_upload(file)

    try:
        prediction_result = make_prediction(tmp_path)
        saved_name = save_upload_permanently(tmp_path, file.filename or "mri.jpg")

        analysis = MRIAnalysis(
            patient_id=current_patient.id,
            image_path=saved_name,
            predicted_class=prediction_result["predicted_class"],
            probabilities=json.dumps(prediction_result["probabilities"])
        )

        current_patient.disease = prediction_result["predicted_class"]

        db.add(analysis)
        db.commit()
        db.refresh(analysis)

        return MRIAnalysisResponse(
            id=analysis.id,
            patientId=analysis.patient_id,
            imagePath=analysis.image_path,
            predictedClass=analysis.predicted_class,
            probabilities=prediction_result["probabilities"],
            aiSummary=prediction_result["ai_summary"],
            createdAt=analysis.created_at.isoformat()
        )
    finally:
        try:
            os.remove(tmp_path)
        except OSError:
            pass


@router.get("/my-analyses", response_model=list)
async def get_my_analyses(
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    analyses = db.query(MRIAnalysis).filter(
        MRIAnalysis.patient_id == current_patient.id
    ).order_by(MRIAnalysis.created_at.desc()).all()

    results = []
    for a in analyses:
        probs = a.probabilities
        if isinstance(probs, str):
            try:
                probs = json.loads(probs)
            except Exception:
                probs = {}
        ai_summary = generate_ai_summary(a.predicted_class, probs if isinstance(probs, dict) else {})
        results.append({
            "id": a.id,
            "patientId": a.patient_id,
            "imagePath": a.image_path,
            "predictedClass": a.predicted_class,
            "probabilities": probs,
            "aiSummary": ai_summary,
            "createdAt": a.created_at.isoformat(),
        })

    return results


@router.get("/image/{filename}")
async def get_analysis_image(filename: str):
    file_path = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(file_path)
