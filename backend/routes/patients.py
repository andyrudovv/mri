from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import asc, desc
from database import get_db
from models import Patient, Doctor
from schemas import PatientCreate, PatientUpdate, PatientResponse, DoctorResponse
from dependencies import get_current_doctor
from security import hash_password

router = APIRouter(prefix="/api/patients", tags=["Patients"])


@router.get("", response_model=dict)
async def get_all_patients(
    search: str = Query(None, description="Search by name or IIN"),
    sort_by: str = Query("name", description="Sort field: name, age, disease, created_at"),
    sort_order: str = Query("asc", description="Sort order: asc or desc"),
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    query = db.query(Patient).filter(Patient.doctor_id == current_doctor.id)

    if search:
        search_term = f"%{search}%"
        query = query.filter(
            (Patient.name.ilike(search_term)) | (Patient.iin.ilike(search_term))
        )

    sort_col = {
        "name": Patient.name,
        "age": Patient.age,
        "disease": Patient.disease,
        "created_at": Patient.created_at,
    }.get(sort_by, Patient.name)

    order_fn = desc if sort_order == "desc" else asc
    query = query.order_by(order_fn(sort_col))

    patients = query.all()
    return {
        "patients": [PatientResponse(**p.to_dict()) for p in patients]
    }


@router.post("", response_model=DoctorResponse)
async def create_patient(
    patient_data: PatientCreate,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    if patient_data.iin:
        existing = db.query(Patient).filter(Patient.iin == patient_data.iin).first()
        if existing:
            existing.doctor_id = current_doctor.id
            if patient_data.name:
                existing.name = patient_data.name
            if patient_data.age:
                existing.age = patient_data.age
            if patient_data.gender:
                existing.gender = patient_data.gender
            if patient_data.disease:
                existing.disease = patient_data.disease
            if patient_data.notes is not None:
                existing.notes = patient_data.notes
            db.commit()
            db.refresh(existing)
            db.refresh(current_doctor)
            return DoctorResponse(**current_doctor.to_dict())

    pwd_hash = hash_password(patient_data.password) if patient_data.password else None

    new_patient = Patient(
        doctor_id=current_doctor.id,
        name=patient_data.name,
        age=patient_data.age,
        gender=patient_data.gender,
        disease=patient_data.disease or "",
        notes=patient_data.notes,
        iin=patient_data.iin,
        password_hash=pwd_hash,
    )

    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)
    db.refresh(current_doctor)

    return DoctorResponse(**current_doctor.to_dict())


@router.get("/check-iin/{iin}")
async def check_iin(
    iin: str,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Check if a patient with this IIN already exists."""
    patient = db.query(Patient).filter(Patient.iin == iin).first()
    if patient:
        return {
            "exists": True,
            "patient": {
                "name": patient.name,
                "age": patient.age,
                "gender": patient.gender,
                "disease": patient.disease or "",
            },
        }
    return {"exists": False, "patient": None}


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(
    patient_id: int,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )

    return PatientResponse(**patient.to_dict())


@router.put("/{patient_id}", response_model=PatientResponse)
async def update_patient(
    patient_id: int,
    patient_data: PatientUpdate,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )

    if patient_data.name:
        patient.name = patient_data.name
    if patient_data.age:
        patient.age = patient_data.age
    if patient_data.gender:
        patient.gender = patient_data.gender
    if patient_data.disease is not None:
        patient.disease = patient_data.disease
    if patient_data.notes is not None:
        patient.notes = patient_data.notes
    if patient_data.iin is not None:
        patient.iin = patient_data.iin

    db.commit()
    db.refresh(patient)

    return PatientResponse(**patient.to_dict())


@router.delete("/{patient_id}")
async def delete_patient(
    patient_id: int,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )

    patient.doctor_id = None
    db.commit()

    return {"message": "Patient unlinked successfully"}
