from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Patient
from schemas import PatientRegister, PatientLogin, PatientAuthResponse, PatientResponse
from security import create_access_token
import hashlib

router = APIRouter(prefix="/api/patients-auth", tags=["Patient Authentication"])


def _generate_patient_token(name: str, disease: str) -> str:
    """Generate a simple token for patient authentication"""
    return hashlib.sha256(f"{name.lower()}:{disease.lower()}".encode()).hexdigest()[:32]


@router.post("/register", response_model=PatientAuthResponse)
async def register_patient(
    patient_data: PatientRegister,
    db: Session = Depends(get_db)
):
    """Register a new patient (self-registration)"""

    # Check if patient with same name already exists
    existing_patient = db.query(Patient).filter(
        Patient.name == patient_data.name
    ).first()

    if existing_patient:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Patient with this name already exists"
        )

    # Create new patient (without doctor_id for self-registration)
    # Disease will be updated after first analysis
    new_patient = Patient(
        doctor_id=None,  # Self-registered patient
        name=patient_data.name,
        age=patient_data.age,
        gender=patient_data.gender,
        disease="No Tumor",  # Default value, will be updated after analysis
        notes=patient_data.notes,
    )

    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)

    # Create token
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
    """Login a patient"""
    
    # Find patient by name and disease
    patient = db.query(Patient).filter(
        Patient.name == credentials.name,
        Patient.disease == credentials.disease
    ).first()
    
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid name or disease"
        )
    
    # Create token
    token = create_access_token(data={"sub": f"patient:{patient.id}", "type": "patient"})
    
    return {
        "token": token,
        "patient": PatientResponse(**patient.to_dict()),
    }


@router.get("/me", response_model=PatientResponse)
async def get_current_patient(
    patient_id: int,
    db: Session = Depends(get_db)
):
    """Get current authenticated patient's profile"""
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found"
        )
    
    return PatientResponse(**patient.to_dict())
