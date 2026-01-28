# System Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MRI Analysis System                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
         ┌──────▼──────┐            ┌──────▼──────┐
         │   Flutter   │            │   FastAPI   │
         │  Frontend   │◄──────────►│   Backend   │
         └─────────────┘ HTTP REST  └──────┬──────┘
                │                          │
                │                    ┌─────▼─────┐
                │                    │PostgreSQL │
                │                    │ Database  │
                │                    └───────────┘
                │
         ┌──────▼──────┐
         │ ML Models   │
         │ (Keras)     │
         └─────────────┘
```

## Backend Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      FastAPI Application                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Auth       │  │   Patients   │  │   Analysis   │       │
│  │   Routes     │  │   Routes     │  │   Routes     │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                  │              │
│         └─────────┬───────┴──────────────────┘              │
│                   │                                         │
│         ┌─────────▼──────────┐                              │
│         │  Dependency Layer  │                              │
│         │ (get_current_user) │                              │
│         └─────────┬──────────┘                              │
│                   │                                         │
│         ┌─────────▼──────────┐                              │
│         │ Security Module    │                              │
│         │(JWT, Passwords)    │                              │
│         └─────────┬──────────┘                              │
│                   │                                         │
│         ┌─────────▼──────────┐                              │
│         │ Database Layer     │                              │
│         │ (SQLAlchemy ORM)   │                              │
│         └────────────────────┘                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                    ┌─────▼─────┐
                    │ PostgreSQL │
                    │ Database   │
                    └───────────┘
```

## Database Schema

```
┌──────────────────┐
│      doctors     │
├──────────────────┤
│ id (PK)          │
│ name             │
│ email (UNIQUE)   │
│ password_hash    │
│ specialization   │
│ profile_image    │
│ created_at       │
│ updated_at       │
└────────┬─────────┘
         │ 1:N
         │
    ┌────┴─────────────────┐
    │                       │
┌───▼──────────────┐  ┌────▼──────────────┐
│    patients      │  │ refresh_tokens    │
├──────────────────┤  ├───────────────────┤
│ id (PK)          │  │ id (PK)           │
│ doctor_id (FK)   │  │ doctor_id (FK)    │
│ name             │  │ token             │
│ age              │  │ expires_at        │
│ gender           │  │ created_at        │
│ disease          │  └───────────────────┘
│ notes            │
│ created_at       │
│ updated_at       │
└────┬─────────────┘
     │ 1:N
     │
┌────▼────────────────┐
│   mri_analyses      │
├─────────────────────┤
│ id (PK)             │
│ patient_id (FK)     │
│ image_path          │
│ predicted_class     │
│ probabilities       │
│ created_at          │
└─────────────────────┘
```

## Request Flow

### Registration/Login Flow
```
┌─────────────┐
│   Flutter   │
│  Frontend   │
└──────┬──────┘
       │ 1. POST /api/auth/register
       │    or
       │    POST /api/auth/login
       │
┌──────▼──────────────────┐
│  FastAPI Auth Routes    │
├─────────────────────────┤
│ Validate Input (schemas)│
│ Hash/Verify Password    │
│ Create JWT Tokens       │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  PostgreSQL Database    │
├─────────────────────────┤
│ Store Doctor Record     │
│ Return Doctor Data      │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  Response to Frontend   │
├─────────────────────────┤
│ - Access Token          │
│ - Refresh Token         │
│ - Doctor Info           │
└──────────────────────────┘
```

### Patient Management Flow
```
┌─────────────┐
│   Flutter   │
│  Frontend   │
└──────┬──────┘
       │ 1. POST /api/patients
       │    Headers: Authorization: Bearer <token>
       │    Body: Patient Data
       │
┌──────▼──────────────────┐
│  Dependency Injection   │
├─────────────────────────┤
│ Extract & Verify Token  │
│ Get Current Doctor      │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  Patient Routes         │
├─────────────────────────┤
│ Validate Input (schemas)│
│ Create Patient Record   │
│ Link to Doctor          │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  PostgreSQL Database    │
├─────────────────────────┤
│ INSERT Patient          │
│ Return Updated Doctor   │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  Response to Frontend   │
├─────────────────────────┤
│ Updated Doctor Object   │
│ with all Patients       │
└──────────────────────────┘
```

### MRI Analysis Flow
```
┌─────────────┐
│   Flutter   │
│  Frontend   │
└──────┬──────┘
       │ 1. Upload File
       │    POST /api/analysis/predict/{patient_id}
       │    Headers: Authorization: Bearer <token>
       │    Body: MRI Image
       │
┌──────▼──────────────────┐
│  Dependency Injection   │
├─────────────────────────┤
│ Verify Doctor Token     │
│ Verify Patient Ownership│
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  Analysis Routes        │
├─────────────────────────┤
│ Validate Image Type     │
│ Save Temporary File     │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  ML Model (Keras)       │
├─────────────────────────┤
│ Load Pre-trained Model  │
│ Process Image           │
│ Generate Predictions    │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  Database Storage       │
├─────────────────────────┤
│ Store Analysis Result   │
│ Store Probabilities     │
│ Clean Up Temp Files     │
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  Response to Frontend   │
├─────────────────────────┤
│ Analysis ID             │
│ Predicted Class         │
│ Probabilities           │
│ Timestamp               │
└──────────────────────────┘
```

## Authentication Flow

```
┌─────────────────────────────────────────────────────────┐
│                    JWT Authentication                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Login/Register                                       │
│     └─► Create JWT Token (valid 30 minutes)             │
│     └─► Return to Frontend                              │
│                                                          │
│  2. Store Token                                          │
│     └─► Stored in Flutter's SharedPreferences           │
│                                                          │
│  3. API Request                                          │
│     └─► Include Token: Authorization: Bearer <token>   │
│                                                          │
│  4. Backend Verification                                │
│     └─► Extract Token from Header                       │
│     └─► Decode JWT (verify signature + expiration)      │
│     └─► Get Doctor from Database                        │
│     └─► Proceed with Request or Return 401              │
│                                                          │
│  5. Token Expiration                                     │
│     └─► Auto re-login or use Refresh Token              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Deployment Architecture (Production)

```
┌─────────────────────────────────────────────────────────┐
│                   Client Devices                         │
│              (iOS, Android, Web)                         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ HTTPS
                       │
        ┌──────────────▼──────────────┐
        │   Load Balancer/Nginx       │
        │    (SSL/TLS Termination)    │
        └──────────────┬──────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
    ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
    │FastAPI  │  │FastAPI  │  │FastAPI  │
    │Instance │  │Instance │  │Instance │
    │    1    │  │    2    │  │    N    │
    └────┬────┘  └────┬────┘  └────┬────┘
         │             │             │
         └─────────────┼─────────────┘
                       │
                ┌──────▼──────┐
                │   Gunicorn  │
                │   Workers   │
                └──────┬──────┘
                       │
        ┌──────────────▼──────────────┐
        │   PostgreSQL Database       │
        │   (with Backup & Replication)
        └─────────────────────────────┘
```

## File Upload Flow

```
┌─────────────────────────────────────────────────────────┐
│                   MRI Image Upload                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. User selects image from device                      │
│                                                         │
│  2. Flutter sends multipart request                     │
│     ├─ File: MRI image (JPEG/PNG)                       │
│     └─ Headers: Authorization, Content-Type            │
│                                                         │
│  3. Backend receives upload                             │
│     ├─ Validate file type & size                        │
│     ├─ Save to temporary location                       │
│     └─ Verify patient ownership                         │
│                                                         │
│  4. ML Model Processing                                 │
│     ├─ Load image (256x256 pixels)                      │
│     ├─ Normalize pixel values                           │
│     ├─ Apply Keras preprocessing                        │
│     └─ Run prediction                                   │
│                                                         │
│  5. Store Results                                       │
│     ├─ Save analysis record in DB                       │
│     ├─ Store predicted class & probabilities            │
│     └─ Delete temporary file                            │
│                                                         │
│  6. Return Results                                      │
│     ├─ Send analysis to frontend                        │
│     └─ Display predictions to user                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Security Layers                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 1: Input Validation                              │
│  └─► Pydantic Schemas validate all requests             │
│                                                         │
│  Layer 2: Authentication                                │
│  └─► JWT tokens with signature verification            │
│                                                         │
│  Layer 3: Authorization                                 │
│  └─► Dependency injection checks resource ownership    │
│                                                         │
│  Layer 4: Password Security                             │
│  └─► Bcrypt hashing with salt                          │
│                                                         │
│  Layer 5: Database Security                             │
│  └─► SQL injection prevention (ORM parameterization)   │
│                                                         │
│  Layer 6: HTTPS/TLS                                     │
│  └─► Encrypted communication (production)              │
│                                                         │
│  Layer 7: CORS                                          │
│  └─► Origin validation for browser requests            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Summary

```
┌─────────────┐
│   Flutter   │ (Mobile/Web App)
└──────┬──────┘
       │
       │ JSON (HTTP/HTTPS)
       │
┌──────▼──────────────┐
│    FastAPI          │ (REST API)
│   - Routes          │
│   - Validation      │
│   - Business Logic  │
└──────┬──────────────┘
       │
       │ SQL Queries
       │
┌──────▼──────────────┐
│   PostgreSQL        │ (Data Storage)
│   - Doctors         │
│   - Patients        │
│   - Analyses        │
└─────────────────────┘

┌──────────────────┐
│   ML Models      │ (Keras)
│   - Prediction   │
└──────────────────┘
```

## Scalability Considerations

### Horizontal Scaling
- Run multiple FastAPI instances behind load balancer
- Share PostgreSQL database connection pool
- Cache frequently accessed data (Redis optional)

### Vertical Scaling
- Increase server resources (CPU/RAM)
- Optimize database queries with indexes
- Implement pagination for large datasets

### Optimization
- Image compression before ML processing
- Database query optimization
- Connection pooling
- Caching layer for predictions

---

**Note:** This architecture supports the current MVP and scales for production deployment with minor modifications.
