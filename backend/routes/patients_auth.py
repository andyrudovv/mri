from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Patient
from schemas import (
    PatientRegister, PatientLogin, PatientAuthResponse,
    PatientResponse, ChangePasswordSchema,
)
from security import create_access_token, hash_password, verify_password
from dependencies import get_current_patient

router = APIRouter(prefix="/api/patients-auth", tags=["Patient Authentication"])


@router.post("/register", response_model=PatientAuthResponse)
async def register_patient(
    patient_data: PatientRegister,
    db: Session = Depends(get_db)
):
    existing = db.query(Patient).filter(Patient.iin == patient_data.iin).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Patient with this IIN already exists"
        )

    new_patient = Patient(
        doctor_id=None,
        iin=patient_data.iin,
        name=patient_data.name,
        age=patient_data.age,
        gender=patient_data.gender,
        disease="",
        notes=patient_data.notes,
        password_hash=hash_password(patient_data.password),
    )

    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)

    token = create_access_token(data={"sub": f"patient:{new_patient.id}", "type": "patient"})

    return {
        "token": token,
        "patient": PatientResponse(**new_patient.to_dict()),
    }


@router.post("/login", response_model=PatientAuthResponse)
async def login_patient(
    credentials: PatientLogin,
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.iin == credentials.iin).first()

    if not patient:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid IIN or password"
        )

    if not patient.password_hash or not verify_password(credentials.password, patient.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid IIN or password"
        )

    token = create_access_token(data={"sub": f"patient:{patient.id}", "type": "patient"})

    return {
        "token": token,
        "patient": PatientResponse(**patient.to_dict()),
    }


@router.get("/me", response_model=PatientResponse)
async def get_current_patient_profile(
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    db.refresh(current_patient)
    return PatientResponse(**current_patient.to_dict())


@router.put("/change-password")
async def change_patient_password(
    data: ChangePasswordSchema,
    current_patient: Patient = Depends(get_current_patient),
    db: Session = Depends(get_db)
):
    if not current_patient.password_hash or not verify_password(data.old_password, current_patient.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )

    current_patient.password_hash = hash_password(data.new_password)
    db.commit()

    return {"message": "Password changed successfully"}
