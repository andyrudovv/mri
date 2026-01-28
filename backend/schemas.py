from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime


class PatientCreate(BaseModel):
    name: str
    age: int = Field(..., ge=0, le=150)
    gender: str
    disease: str
    notes: Optional[str] = None


class PatientUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = Field(None, ge=0, le=150)
    gender: Optional[str] = None
    disease: Optional[str] = None
    notes: Optional[str] = None


class PatientResponse(BaseModel):
    id: int
    name: str
    age: int
    gender: str
    disease: str
    notes: Optional[str]
    createdAt: str

    class Config:
        from_attributes = True


class DoctorRegister(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8, description="Password must be at least 8 characters")
    specialization: str = Field(..., min_length=2)


class DoctorLogin(BaseModel):
    email: EmailStr
    password: str


class DoctorUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2)
    specialization: Optional[str] = Field(None, min_length=2)
    profileImage: Optional[str] = None


class DoctorResponse(BaseModel):
    id: int
    name: str
    email: str
    specialization: str
    profileImage: Optional[str]
    patients: List[PatientResponse] = []
    createdAt: str

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    token: str
    refresh_token: Optional[str] = None
    doctor: DoctorResponse


class TokenData(BaseModel):
    email: Optional[str] = None
    exp: Optional[datetime] = None


class MRIAnalysisResponse(BaseModel):
    id: int
    patientId: int
    imagePath: str
    predictedClass: str
    probabilities: str
    createdAt: str

    class Config:
        from_attributes = True
