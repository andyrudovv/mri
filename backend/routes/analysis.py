from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, status, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from database import get_db
from models import Patient, MRIAnalysis, Doctor
from schemas import MRIAnalysisResponse, GenerateAiSummaryRequest, GenerateAiSummaryResponse
from dependencies import get_current_doctor, get_current_patient, get_current_doctor_or_patient
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

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

AVAILABLE_MODELS = {
    "ensemble": {
        "path": "ai/trained/MRI_ENSEMBLED.keras",
        "classes": ['glioma', 'meningioma', 'notumor', 'pituitary'],
        "type": "single_head",
    },
    "efficientnet": {
        "path": "ai/trained/finetuned_efficientnet.keras",
        "classes_file": "ai/trained/efficientnet_classes.json",
        "type": "dual_head",
    },
}

_loaded_models = {}


def _get_efficientnet_classes():
    classes_file = AVAILABLE_MODELS["efficientnet"]["classes_file"]
    if os.path.exists(classes_file):
        with open(classes_file, 'r') as f:
            return json.load(f)
    raise RuntimeError("EfficientNet classes file not found")

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

GEMINI_SYSTEM_PROMPT = """You are an AI assistant that explains MRI analysis results in clear and understandable language.

Your input will be a set of probabilities (numbers), where each probability corresponds to a specific class.
A class name may contain a predicted diagnosis, an MRI scan type, or both (e.g. Diagnosis_T1 or "Diagnosis T1" style).

Your task:
1. Find the class with the highest probability.
2. When applicable, extract the diagnosis and the MRI scan type.
3. Explain the result in a calm, professional, and patient-friendly way.
4. Use simple language for patients.
5. If medical terminology is used, explain it in simple words immediately after mentioning it.
6. Sound slightly professional, but still easy for non-medical people to understand.
7. Do not make a final medical diagnosis.
8. Do not use alarming or frightening language.

WORKING MODES (follow the mode stated in the user message):

FOUR-NUMBER MODE — only diagnoses, no MRI sequence in the class name.
- Find the highest probability and most likely diagnosis.
- Explain briefly in simple language.
- Do NOT mention MRI scan types.
- End with a short note that only a doctor can give a final diagnosis.

COMBINED-CLASS MODE — class names combine diagnosis and MRI type (underscore or space between parts).
- Find the highest-probability class; extract diagnosis and MRI scan type.
- Briefly explain what the MRI scan type means:
  - T1 — mainly shows structure and anatomy of brain tissues.
  - T2 — better highlights fluid, swelling, and inflammation.
  - T1+C or T1C+ — contrast-enhanced MRI that helps see active areas of an abnormality or tumor.
- Explain the predicted diagnosis in simple words.
- If the diagnosis indicates no tumor / normal tissue, say that no clear signs of a tumor were detected in understandable language.
- End with a short recommendation to consult a doctor for a final interpretation.

Write in English unless the user message asks for another language."""


def _is_no_pathology_finding(predicted_class: str) -> bool:
    """Ensemble 'notumor' or EfficientNet 'Normal …' — no generative disease narrative."""
    pc = (predicted_class or "").strip()
    if not pc:
        return True
    if pc.lower() == "notumor":
        return True
    if pc.startswith("Normal "):
        return True
    return False


def _infer_gemini_mode(probabilities: dict) -> str:
    """Heuristic: 4-class ensemble keys are lowercase single tokens; EfficientNet uses 'Diagnosis T1' etc."""
    if not probabilities:
        return "four_number"
    for k in probabilities:
        if not isinstance(k, str):
            return "combined"
        if " " in k:
            tail = k.rsplit(" ", 1)[-1]
            if tail in ("T1", "T2", "T1C+", "T1+C", "T1+C+"):
                return "combined"
            if k != k.lower():
                return "combined"
    if all(isinstance(k, str) and k.islower() and " " not in k for k in probabilities):
        return "four_number"
    return "combined"


def _class_key_for_combined_mode(class_name: str) -> str:
    """Normalize to Diagnosis_Sequence for the model (aligns with Diagnosis_T1 examples)."""
    if not isinstance(class_name, str):
        return str(class_name)
    s = class_name.strip()
    if " " not in s:
        return s.replace("-", "_")
    diagnosis, seq = s.rsplit(" ", 1)
    if seq == "T1C+":
        seq = "T1+C"
    d = diagnosis.replace(" ", "_")
    return f"{d}_{seq}"


def _format_probabilities_percent(probabilities: dict, mode: str) -> dict:
    ensemble_labels = {
        "glioma": "Glioma",
        "meningioma": "Meningioma",
        "pituitary": "Pituitary",
        "notumor": "No Tumor",
    }
    out: dict[str, float] = {}
    if mode == "four_number":
        for k, v in probabilities.items():
            lk = k.lower() if isinstance(k, str) else k
            label = ensemble_labels.get(lk, str(k).title() if isinstance(k, str) else str(k))
            out[label] = round(float(v) * 100.0, 1)
    else:
        for k, v in probabilities.items():
            out[_class_key_for_combined_mode(k)] = round(float(v) * 100.0, 1)
    return out


_genai_client = None


def _get_genai_client():
    global _genai_client
    if _genai_client is not None:
        return _genai_client
    api_key = (os.environ.get("GEMINI_API_KEY") or "").strip()
    if not api_key:
        return None
    from google import genai
    _genai_client = genai.Client(api_key=api_key)
    return _genai_client


def _gemini_generate_patient_text(user_message: str) -> str | None:
    client = _get_genai_client()
    if client is None:
        print("[GEMINI] GEMINI_API_KEY is NOT set — falling back to template", flush=True)
        return None

    model = (os.environ.get("GEMINI_MODEL") or "gemini-flash-latest").strip() or "gemini-flash-latest"
    print(f"[GEMINI] Calling model={model}", flush=True)

    try:
        from google.genai import types
        response = client.models.generate_content(
            model=model,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=GEMINI_SYSTEM_PROMPT,
                temperature=0.35,
                max_output_tokens=1200,
            ),
        )
        text = response.text
        if text and text.strip():
            print(f"[GEMINI] OK — received {len(text.strip())} chars", flush=True)
            return text.strip()
        print("[GEMINI] Returned empty text", flush=True)
        return None
    except Exception as exc:
        print(f"[GEMINI] Exception: {type(exc).__name__}: {exc}", flush=True)
        return None


def generate_ai_summary_generative(predicted_class: str, probabilities: dict) -> str | None:
    """Gemini-based patient explanation; returns None on missing key or API failure."""
    if not probabilities:
        return None
    mode = _infer_gemini_mode(probabilities)
    prob_payload = _format_probabilities_percent(probabilities, mode)
    mode_title = "COMBINED-CLASS MODE" if mode == "combined" else "FOUR-NUMBER MODE"
    user_message = (
        f"WORKING MODE: {mode_title}\n\n"
        f"Class probabilities (percentages 0–100):\n{json.dumps(prob_payload, ensure_ascii=False, indent=2)}\n\n"
        "The model's top predicted class label (internal id) is: "
        f"{predicted_class}\n\n"
        "Write the patient-facing explanation now, following all rules."
    )
    return _gemini_generate_patient_text(user_message)


def _generate_ai_summary_template(predicted_class: str, probabilities: dict) -> str:
    confidence = probabilities.get(predicted_class, 0) * 100
    info = DISEASE_DESCRIPTIONS.get(predicted_class)

    if predicted_class == "notumor" or (isinstance(predicted_class, str) and predicted_class.startswith("Normal ")):
        nt = DISEASE_DESCRIPTIONS["notumor"]
        summary = (
            f"Analysis Result: {nt['name']} (confidence: {confidence:.1f}%).\n\n"
            f"{nt['description']}\n\n"
            f"{nt['details']}\n\n"
            f"Note: {nt['severity']}."
        )
        return summary

    if info is None:
        other_probs = {k: v for k, v in probabilities.items() if k != predicted_class}
        other_text = ", ".join(
            f"{DISEASE_DESCRIPTIONS.get(k, {}).get('name', k)}: {v*100:.1f}%"
            for k, v in sorted(other_probs.items(), key=lambda x: -x[1])
        ) if other_probs else "—"
        return (
            f"Analysis Result: {predicted_class} (model confidence {confidence:.1f}%).\n\n"
            "This text is a fallback summary: the detailed model class is not in the local description catalog.\n\n"
            f"Other class scores: {other_text}.\n\n"
            "Important: This is an AI-assisted analysis. Please consult a qualified specialist for confirmation and treatment planning."
        )

    name = info.get("name", predicted_class)
    description = info.get("description", "")
    details = info.get("details", "")
    severity = info.get("severity", "")
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


def generate_ai_summary(predicted_class: str, probabilities: dict) -> str:
    probs = probabilities or {}
    if not _is_no_pathology_finding(predicted_class):
        gen = generate_ai_summary_generative(predicted_class, probs)
        if gen:
            return gen
    return _generate_ai_summary_template(predicted_class, probs)


def load_prediction_model(model_type: str = "ensemble"):
    if model_type not in AVAILABLE_MODELS:
        raise ValueError(f"Unknown model: {model_type}. Available: {list(AVAILABLE_MODELS.keys())}")

    if model_type not in _loaded_models:
        model_path = AVAILABLE_MODELS[model_type]["path"]
        if not os.path.exists(model_path):
            raise RuntimeError(f"Model file not found: {model_path}")
        _loaded_models[model_type] = load_model(model_path)

    return _loaded_models[model_type]


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


def make_prediction(path_to_img: str, model_type: str = "ensemble") -> dict:
    model = load_prediction_model(model_type)
    model_config = AVAILABLE_MODELS[model_type]

    img_to_predict = image.load_img(path_to_img, target_size=(256, 256))
    img_array = image.img_to_array(img_to_predict)
    img_array = img_array / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    pred = model.predict(img_array)

    if model_config["type"] == "dual_head":
        class_pred = pred[0]
        diagnoses = _get_efficientnet_classes()
        probs_rounded = np.round(class_pred[0], 4)
        res_index = int(np.argmax(class_pred[0]))
    else:
        diagnoses = model_config["classes"]
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
        "model_used": model_type,
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
    model_type: str = Form(default="ensemble"),
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    if model_type not in AVAILABLE_MODELS:
        raise HTTPException(status_code=400, detail=f"Invalid model. Available: {list(AVAILABLE_MODELS.keys())}")

    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    tmp_path = _process_upload(file)

    try:
        prediction_result = make_prediction(tmp_path, model_type)
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
    model_type: str = Form(default="ensemble"),
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    if model_type not in AVAILABLE_MODELS:
        raise HTTPException(status_code=400, detail=f"Invalid model. Available: {list(AVAILABLE_MODELS.keys())}")

    tmp_path = _process_upload(file)

    try:
        prediction_result = make_prediction(tmp_path, model_type)
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


@router.get("/models")
async def get_available_models():
    return {
        "models": [
            {"id": "ensemble", "name": "MRI Ensemble (4 classes)"},
            {"id": "efficientnet", "name": "EfficientNetV2S (30 classes)"},
        ]
    }


@router.post("/generate-summary", response_model=GenerateAiSummaryResponse)
async def generate_summary_from_probabilities(
    body: GenerateAiSummaryRequest,
    _: Doctor | Patient = Depends(get_current_doctor_or_patient),
):
    """Build patient-facing AI summary (Gemini when configured, otherwise template fallback)."""
    probs = {str(k): float(v) for k, v in body.probabilities.items()}
    text = generate_ai_summary(body.predictedClass, probs)
    return GenerateAiSummaryResponse(aiSummary=text)


@router.get("/image/{filename}")
async def get_analysis_image(filename: str):
    file_path = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(file_path)
