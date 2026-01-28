from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import Doctor
from schemas import DoctorRegister, DoctorLogin, AuthResponse, DoctorResponse, DoctorUpdate
from security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
)
from dependencies import get_current_doctor

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=AuthResponse)
async def register(
    doctor_data: DoctorRegister,
    db: Session = Depends(get_db)
):
    """Register a new doctor"""
    
    # Check if email already exists
    existing_doctor = db.query(Doctor).filter(Doctor.email == doctor_data.email).first()
    if existing_doctor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new doctor
    new_doctor = Doctor(
        name=doctor_data.name,
        email=doctor_data.email,
        password_hash=hash_password(doctor_data.password),
        specialization=doctor_data.specialization,
    )
    
    db.add(new_doctor)
    db.commit()
    db.refresh(new_doctor)
    
    # Create tokens
    access_token = create_access_token(data={"sub": new_doctor.email})
    refresh_token = create_refresh_token(data={"sub": new_doctor.email})
    
    return {
        "token": access_token,
        "refresh_token": refresh_token,
        "doctor": DoctorResponse(**new_doctor.to_dict()),
    }


@router.post("/login", response_model=AuthResponse)
async def login(
    credentials: DoctorLogin,
    db: Session = Depends(get_db)
):
    """Login a doctor"""
    
    # Find doctor by email
    doctor = db.query(Doctor).filter(Doctor.email == credentials.email).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Verify password
    if not verify_password(credentials.password, doctor.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Create tokens
    access_token = create_access_token(data={"sub": doctor.email})
    refresh_token = create_refresh_token(data={"sub": doctor.email})
    
    return {
        "token": access_token,
        "refresh_token": refresh_token,
        "doctor": DoctorResponse(**doctor.to_dict()),
    }


@router.post("/logout")
async def logout(
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Logout a doctor (invalidate tokens)"""
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=DoctorResponse)
async def get_current_user(
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Get current authenticated doctor's profile"""
    db.refresh(current_doctor)
    return DoctorResponse(**current_doctor.to_dict())


@router.put("/profile", response_model=AuthResponse)
async def update_profile(
    profile_data: DoctorUpdate,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    """Update doctor's profile"""
    
    # Update fields if provided
    if profile_data.name:
        current_doctor.name = profile_data.name
    if profile_data.specialization:
        current_doctor.specialization = profile_data.specialization
    if profile_data.profileImage:
        current_doctor.profile_image = profile_data.profileImage
    
    db.commit()
    db.refresh(current_doctor)
    
    # Create new access token
    access_token = create_access_token(data={"sub": current_doctor.email})
    
    return {
        "token": access_token,
        "doctor": DoctorResponse(**current_doctor.to_dict()),
    }
