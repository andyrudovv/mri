from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base


class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    specialization = Column(String(255), nullable=False)
    profile_image = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patients = relationship("Patient", back_populates="doctor", cascade="all, delete-orphan")
    tokens = relationship("RefreshToken", back_populates="doctor", cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "specialization": self.specialization,
            "profileImage": self.profile_image,
            "patients": [p.to_dict() for p in self.patients],
            "createdAt": self.created_at.isoformat(),
        }


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    name = Column(String(255), nullable=False)
    age = Column(Integer, nullable=False)
    gender = Column(String(50), nullable=False)
    disease = Column(String(255), nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    doctor = relationship("Doctor", back_populates="patients")
    analyses = relationship("MRIAnalysis", back_populates="patient", cascade="all, delete-orphan")

    def to_dict(self):
        latest_analysis = self.analyses[-1] if self.analyses else None
        return {
            "id": self.id,
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "disease": self.disease,
            "notes": self.notes,
            "createdAt": self.created_at.isoformat(),
            "url": latest_analysis.image_path if latest_analysis else None,
        }


class MRIAnalysis(Base):
    __tablename__ = "mri_analyses"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    image_path = Column(String(500), nullable=False)
    predicted_class = Column(String(255), nullable=False)
    probabilities = Column(String(1000), nullable=False)  # JSON stored as string
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    patient = relationship("Patient", back_populates="analyses")

    def to_dict(self):
        return {
            "id": self.id,
            "patientId": self.patient_id,
            "imagePath": self.image_path,
            "predictedClass": self.predicted_class,
            "probabilities": self.probabilities,
            "createdAt": self.created_at.isoformat(),
        }


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    token = Column(String(500), unique=True, index=True, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    doctor = relationship("Doctor", back_populates="tokens")
