# MRI Analysis System — Architecture & Documentation

## Table of Contents
1. [Model Metrics](#1-model-metrics)
2. [System Architecture (Component Diagram)](#2-system-architecture)
3. [HTTP API Diagram (Frontend → Backend)](#3-http-api-diagram)
4. [Backend Architecture](#4-backend-architecture)
5. [ERD Diagram](#5-erd-diagram)
6. [Sequence Diagrams](#6-sequence-diagrams)

---

## 1. Model Metrics

### Ensemble Model (4 classes: Glioma, Meningioma, No Tumor, Pituitary)

| Metric | Description | Formula |
|--------|-------------|---------|
| **Accuracy** | Overall correct predictions | TP+TN / (TP+TN+FP+FN) |
| **Precision** | Positive predictive value per class | TP / (TP+FP) |
| **Recall (Sensitivity)** | True positive rate per class | TP / (TP+FN) |
| **Specificity** | True negative rate per class | TN / (TN+FP) |
| **F1-score** | Harmonic mean of Precision & Recall | 2·(P·R)/(P+R) |
| **ROC-AUC** | Area under receiver operating curve | One-vs-Rest per class |

### Confusion Matrix (4×4)

```
                 Predicted
              Gli  Men  NoT  Pit
Actual Gli  [ TP   .    .    .  ]
       Men  [  .   TP   .    .  ]
       NoT  [  .    .   TP   .  ]
       Pit  [  .    .    .   TP ]
```

### EfficientNetV2S Model (30 classes: Diagnosis × MRI Sequence)

Same metrics apply in a **30×30 confusion matrix**, evaluated with macro/weighted averaging for Precision, Recall, F1.

---

## 2. System Architecture

```mermaid
graph TB
    subgraph Client["Frontend (Flutter Web)"]
        UI[Flutter UI<br/>Chrome / Web]
    end

    subgraph Server["Backend (Docker)"]
        API[FastAPI Server<br/>uvicorn :8000]
        TF[TensorFlow/Keras<br/>Inference Engine]
        SMTP[SMTP Service<br/>Email OTP]
        GEMINI[Google Gemini API<br/>AI Summary Generation]
    end

    subgraph Database["Database (Docker)"]
        PG[(PostgreSQL 16<br/>mri_db)]
    end

    subgraph Storage["File Storage"]
        UPLOADS[/uploads/<br/>MRI Images/]
        MODELS[/ai/trained/<br/>Keras Models/]
    end

    UI -->|HTTP REST API| API
    API -->|SQLAlchemy ORM| PG
    API -->|Load & Predict| TF
    API -->|Read/Write Files| UPLOADS
    TF -->|Load Weights| MODELS
    API -->|Send OTP Email| SMTP
    API -->|Generate Summary| GEMINI

    style Client fill:#E3F2FD,stroke:#0077B6
    style Server fill:#FFF3E0,stroke:#E65100
    style Database fill:#E8F5E9,stroke:#2E7D32
    style Storage fill:#F3E5F5,stroke:#6A1B9A
```

---

## 3. HTTP API Diagram

```mermaid
graph LR
    subgraph Flutter["Flutter Frontend"]
        AUTH_PAGE[AuthPage]
        OTP_PAGE[OTP Page]
        HOME[HomePage]
        ANALYSIS[AnalysisPage]
        PATIENT_HOME[PatientHomePage]
        PROFILE[ProfilePage]
    end

    subgraph Backend["FastAPI Backend /api"]
        subgraph AuthRoutes["/api/auth"]
            R_REG[POST /register]
            R_LOGIN[POST /login]
            R_OTP_SEND[POST /send-otp]
            R_OTP_VERIFY[POST /verify-otp]
            R_ME[GET /me]
            R_PROFILE[PUT /profile]
            R_CHPWD[PUT /change-password]
            R_LOGOUT[POST /logout]
        end

        subgraph PatientAuth["/api/patients-auth"]
            PA_REG[POST /register]
            PA_LOGIN[POST /login]
            PA_ME[GET /me]
            PA_CHPWD[PUT /change-password]
        end

        subgraph Patients["/api/patients"]
            P_LIST[GET /]
            P_CREATE[POST /]
            P_CHECK[GET /check-iin/:iin]
            P_GET[GET /:id]
            P_UPDATE[PUT /:id]
            P_DELETE[DELETE /:id]
        end

        subgraph Analysis["/api/analysis"]
            A_PREDICT[POST /predict/:patient_id]
            A_PREDICT_P[POST /predict-patient]
            A_HISTORY[GET /patient/:patient_id]
            A_MY[GET /my-analyses]
            A_MODELS[GET /models]
            A_SUMMARY[POST /generate-summary]
            A_IMAGE[GET /image/:filename]
        end
    end

    AUTH_PAGE --> R_REG
    AUTH_PAGE --> R_LOGIN
    OTP_PAGE --> R_OTP_SEND
    OTP_PAGE --> R_OTP_VERIFY
    HOME --> R_ME
    HOME --> P_LIST
    HOME --> P_CREATE
    HOME --> P_DELETE
    ANALYSIS --> A_PREDICT
    ANALYSIS --> A_HISTORY
    ANALYSIS --> A_SUMMARY
    PATIENT_HOME --> PA_LOGIN
    PATIENT_HOME --> A_PREDICT_P
    PATIENT_HOME --> A_MY
    PATIENT_HOME --> A_SUMMARY
    PROFILE --> R_PROFILE
    PROFILE --> R_CHPWD
```

---

## 4. Backend Architecture

```mermaid
graph TB
    subgraph Entrypoint["main.py"]
        APP[FastAPI App]
        CORS[CORS Middleware]
        TABLES["Base.metadata.create_all()"]
    end

    subgraph Routes["Route Modules"]
        AUTH["routes/auth.py<br/>/api/auth"]
        PATIENTS["routes/patients.py<br/>/api/patients"]
        PATIENTS_AUTH["routes/patients_auth.py<br/>/api/patients-auth"]
        ANALYSIS_R["routes/analysis.py<br/>/api/analysis"]
    end

    subgraph Core["Core Modules"]
        MODELS_PY["models.py<br/>SQLAlchemy ORM"]
        SCHEMAS["schemas.py<br/>Pydantic Validation"]
        SECURITY["security.py<br/>JWT + Argon2"]
        DEPS["dependencies.py<br/>Auth Dependencies"]
        DB["database.py<br/>Engine + Session"]
        EMAIL["email_service.py<br/>SMTP OTP"]
    end

    subgraph AI["AI Layer"]
        ENSEMBLE["MRI_ENSEMBLED.keras<br/>VGG16+ResNet50+CNN<br/>4 classes"]
        EFFNET["finetuned_efficientnet.keras<br/>EfficientNetV2S<br/>30 classes (dual-head)"]
        GEMINI_SVC["Gemini API Client<br/>google-genai SDK"]
    end

    subgraph Infra["Infrastructure"]
        POSTGRES[(PostgreSQL 16)]
        FILESYSTEM[/uploads/ + /ai/trained/]
    end

    APP --> CORS
    APP --> AUTH
    APP --> PATIENTS
    APP --> PATIENTS_AUTH
    APP --> ANALYSIS_R

    AUTH --> SECURITY
    AUTH --> EMAIL
    AUTH --> DEPS
    PATIENTS --> DEPS
    PATIENTS_AUTH --> SECURITY
    ANALYSIS_R --> AI
    ANALYSIS_R --> GEMINI_SVC

    Routes --> MODELS_PY
    Routes --> SCHEMAS
    MODELS_PY --> DB
    DB --> POSTGRES
    ANALYSIS_R --> FILESYSTEM

    style Entrypoint fill:#E3F2FD
    style Routes fill:#FFF9C4
    style Core fill:#F3E5F5
    style AI fill:#FFEBEE
    style Infra fill:#E8F5E9
```

---

## 5. ERD Diagram

```mermaid
erDiagram
    DOCTORS {
        int id PK
        varchar name
        varchar email UK
        varchar password_hash
        varchar specialization
        varchar profile_image
        boolean email_verified
        varchar otp_code
        timestamp otp_expires_at
        timestamp created_at
        timestamp updated_at
    }

    PATIENTS {
        int id PK
        int doctor_id FK
        varchar iin UK
        varchar name
        int age
        varchar gender
        varchar disease
        text notes
        varchar password_hash
        timestamp created_at
        timestamp updated_at
    }

    MRI_ANALYSES {
        int id PK
        int patient_id FK
        varchar image_path
        varchar predicted_class
        jsonb probabilities
        timestamp created_at
    }

    REFRESH_TOKENS {
        int id PK
        int doctor_id FK
        varchar token UK
        timestamp expires_at
        timestamp created_at
    }

    DOCTORS ||--o{ PATIENTS : "has many"
    DOCTORS ||--o{ REFRESH_TOKENS : "has many"
    PATIENTS ||--o{ MRI_ANALYSES : "has many"
```

---

## 6. Sequence Diagrams

### 6.1 Doctor Registration + Email OTP Verification

```mermaid
sequenceDiagram
    participant F as Flutter App
    participant B as FastAPI Backend
    participant DB as PostgreSQL
    participant E as SMTP (Gmail)

    F->>B: POST /api/auth/register {name, email, password, specialization}
    B->>DB: Check email uniqueness
    DB-->>B: OK (no duplicate)
    B->>DB: INSERT Doctor (email_verified=false)
    B->>B: Generate 6-digit OTP
    B->>DB: UPDATE Doctor SET otp_code, otp_expires_at
    B->>E: Send OTP email
    E-->>F: Email with code arrives
    B-->>F: 200 {token, doctor: {emailVerified: false}}
    
    Note over F: Show OTP Verification Page

    F->>B: POST /api/auth/verify-otp {email, otp}
    B->>DB: SELECT Doctor WHERE email
    B->>B: Validate OTP + expiry
    B->>DB: UPDATE Doctor SET email_verified=true, otp_code=null
    B-->>F: 200 {verified: true}
    
    Note over F: Navigate to HomePage
```

### 6.2 MRI Analysis (Doctor uploads for Patient)

```mermaid
sequenceDiagram
    participant F as Flutter App
    participant B as FastAPI Backend
    participant TF as TensorFlow
    participant G as Gemini API
    participant DB as PostgreSQL
    participant FS as File Storage

    F->>B: POST /api/analysis/predict/{patient_id}<br/>File + model_type [Bearer token]
    B->>B: Validate token → Doctor
    B->>DB: Verify patient belongs to doctor
    B->>FS: Save uploaded image
    B->>TF: Load model & predict (256×256)
    TF-->>B: Probabilities array
    B->>B: Determine predicted_class
    B->>G: generate_content(probabilities, system_prompt)
    G-->>B: Patient-friendly explanation text
    B->>DB: INSERT MRI_Analysis
    B->>DB: UPDATE Patient.disease
    B-->>F: 200 {predictedClass, probabilities, aiSummary, imagePath}

    Note over F: Display results + AI Summary
```

### 6.3 Patient Self-Service Analysis

```mermaid
sequenceDiagram
    participant F as Flutter App (Patient)
    participant B as FastAPI Backend
    participant TF as TensorFlow
    participant DB as PostgreSQL

    F->>B: POST /api/analysis/predict-patient<br/>File + model_type [Bearer patient token]
    B->>B: Validate token → Patient
    B->>TF: Predict MRI image
    TF-->>B: Probabilities
    B->>DB: INSERT MRI_Analysis
    B-->>F: 200 {predictedClass, probabilities, aiSummary}

    F->>B: POST /api/analysis/generate-summary<br/>{predictedClass, probabilities}
    B->>B: Call Gemini (if configured)
    B-->>F: 200 {aiSummary: "generative text"}
```

### 6.4 Doctor Login with OTP (unverified email)

```mermaid
sequenceDiagram
    participant F as Flutter App
    participant B as FastAPI Backend
    participant DB as PostgreSQL
    participant E as SMTP

    F->>B: POST /api/auth/login {email, password}
    B->>DB: SELECT Doctor by email
    B->>B: Verify password (Argon2)
    B->>B: Check email_verified == false
    B->>B: Generate new OTP
    B->>DB: UPDATE otp_code, otp_expires_at
    B->>E: Send OTP email
    B-->>F: 200 {token, doctor: {emailVerified: false}}

    Note over F: Redirect to OTP page
    
    F->>B: POST /api/auth/verify-otp {email, otp}
    B->>B: Validate code & expiry
    B->>DB: SET email_verified = true
    B-->>F: 200 {verified: true}
    
    Note over F: Navigate to HomePage
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.29+ (Web/Chrome) |
| Backend | Python 3.12, FastAPI, Uvicorn |
| Database | PostgreSQL 16 (Alpine) |
| ORM | SQLAlchemy 2.0+ |
| Auth | JWT (python-jose), Argon2 (passlib) |
| AI Models | TensorFlow/Keras (VGG16, ResNet50V2, CNN ensemble; EfficientNetV2S) |
| AI Summary | Google Gemini API (google-genai SDK) |
| Email | SMTP (Gmail app password) |
| Container | Docker Compose |
| Image Input | JPEG, PNG, WebP, DICOM (.dcm → pydicom conversion) |

---

## AI Models Summary

### Ensemble Model (`MRI_ENSEMBLED.keras`)
- **Architecture**: Concatenation of VGG16 + ResNet50V2 + Custom CNN → BatchNorm → GlobalAveragePooling2D → Dense(512, ReLU) → Dense(4, linear logits)
- **Input**: 256×256×3
- **Output**: 4 logits → softmax applied at inference
- **Classes**: `glioma`, `meningioma`, `notumor`, `pituitary`
- **Loss**: CategoricalCrossentropy (from_logits=True)

### EfficientNetV2S Dual-Head (`finetuned_efficientnet.keras`)
- **Architecture**: EfficientNetV2S (ImageNet pretrained) → Dual head:
  - Head 1: Classification → Dense(30, softmax)
  - Head 2: Localization → Gaussian heatmap (sigmoid)
- **Input**: 256×256×3
- **Output**: 30-class softmax probabilities
- **Classes**: 10 diagnoses × 3 MRI sequences (T1, T2, T1C+)
  - Glioma, Meningioma, Astrocytoma, Ependymoma, Oligodendroglioma, Schwannoma, Neurocytoma, Hemangiopericytoma, Normal, Other
- **Training**: 2-phase (frozen backbone → full fine-tune)
