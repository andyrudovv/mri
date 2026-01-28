from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Patient, Doctor
from schemas import PatientCreate, PatientUpdate, PatientResponse, DoctorResponse
from dependencies import get_current_doctor

router = APIRouter(prefix="/api/patients", tags=["Patients"])


@router.get("", response_model=dict)
async def get_all_patients(
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Get all patients for the current doctor"""
    patients = db.query(Patient).filter(Patient.doctor_id == current_doctor.id).all()
    return {
        "patients": [PatientResponse(**p.to_dict()) for p in patients]
    }


@router.post("", response_model=DoctorResponse)
async def create_patient(
    patient_data: PatientCreate,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Create a new patient for the current doctor"""
    
    new_patient = Patient(
        doctor_id=current_doctor.id,
        name=patient_data.name,
        age=patient_data.age,
        gender=patient_data.gender,
        disease=patient_data.disease,
        notes=patient_data.notes,
    )
    
    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)
    db.refresh(current_doctor)
    
    return DoctorResponse(**current_doctor.to_dict())


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(
    patient_id: int,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Get a specific patient"""
    
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
    """Update a patient"""
    
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()
    
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    # Update fields if provided
    if patient_data.name:
        patient.name = patient_data.name
    if patient_data.age:
        patient.age = patient_data.age
    if patient_data.gender:
        patient.gender = patient_data.gender
    if patient_data.disease:
        patient.disease = patient_data.disease
    if patient_data.notes is not None:
        patient.notes = patient_data.notes
    
    db.commit()
    db.refresh(patient)
    
    return PatientResponse(**patient.to_dict())


@router.delete("/{patient_id}")
async def delete_patient(
    patient_id: int,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Delete a patient"""
    
    patient = db.query(Patient).filter(
        Patient.id == patient_id,
        Patient.doctor_id == current_doctor.id
    ).first()
    
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    db.delete(patient)
    db.commit()
    
    return {"message": "Patient deleted successfully"}
