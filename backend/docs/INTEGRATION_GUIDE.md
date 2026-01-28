# Complete MRI Analysis System - Integration Guide

## 📊 System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Flutter Frontend                             │
│  • Doctor Login/Registration                                        │
│  • Patient Management                                               │
│  • MRI Upload & Analysis                                            │
│  • Patient Cards in Sidebar                                         │
└────────────────────┬────────────────────────────────────────────────┘
                     │ HTTP API (Provider Package)
                     ↓
┌─────────────────────────────────────────────────────────────────────┐
│                  FastAPI Backend (Docker)                           │
├─────────────────────────────────────────────────────────────────────┤
│  Routes:                                                             │
│  • /api/auth/* - Authentication & Doctor Management                │
│  • /api/patients/* - Patient CRUD Operations                        │
│  • /api/analysis/* - MRI Analysis                                   │
│  • /predict - MRI Prediction                                        │
└────────────────────┬────────────────────────────────────────────────┘
                     │ SQLAlchemy ORM
                     ↓
┌─────────────────────────────────────────────────────────────────────┐
│                PostgreSQL Database (Docker)                         │
├─────────────────────────────────────────────────────────────────────┤
│  Tables:                                                             │
│  • users (Doctors)                                                   │
│  • patients (Patient Records)                                        │
│  • analysis (MRI Results)                                            │
└─────────────────────────────────────────────────────────────────────┘
```

## 🎯 What's Implemented

### Frontend (Flutter)
✅ **Authentication System**
- Doctor login/registration
- JWT token management
- Auto-logout on token expiration
- Secure token storage

✅ **Account Management**
- Doctor profile with specialization
- Profile image support
- Token-based sessions

✅ **Patient Management**
- Add patients with: name, age, gender, disease, notes
- Beautiful patient cards in sidebar
- Color-coded disease tags
- Patient deletion
- Disease color coding:
  - Red: Glioma
  - Orange: Meningioma
  - Purple: Pituitary
  - Green: No Tumor

✅ **MRI Analysis**
- MRI image selection
- Upload and analysis
- Results display
- Patient-specific results

### Backend (FastAPI + PostgreSQL)

✅ **Authentication Routes**
```
POST /api/auth/register          - Doctor registration
POST /api/auth/login             - Doctor login
POST /api/auth/logout            - Doctor logout
GET  /api/auth/me                - Get current doctor info
PUT  /api/auth/profile           - Update profile
```

✅ **Patient Routes**
```
POST /api/patients               - Create patient
GET  /api/patients               - List doctor's patients
GET  /api/patients/{id}          - Get patient details
PUT  /api/patients/{id}          - Update patient
DELETE /api/patients/{id}        - Delete patient
```

✅ **Analysis Routes**
```
POST /api/analysis/upload        - Upload MRI for analysis
GET  /api/analysis/{patient_id}  - Get patient analysis history
```

✅ **Database Schema**
- Users table (doctors)
- Patients table (with doctor_id foreign key)
- Analysis table (with patient_id and doctor_id)
- Proper indexes for performance

## 🚀 Getting Started

### Prerequisites
- Docker Desktop installed
- Flutter SDK installed
- Windows/macOS/Linux system

### Step 1: Start Backend with Docker

```bash
cd backend

# Windows
start-docker.bat

# Linux/macOS
bash start-docker.sh
```

**Verify**: Open http://localhost:8000/docs - should see Swagger UI

### Step 2: Update Frontend API URL

The frontend is already configured to connect to `http://localhost:8000` or `http://127.0.0.1:8000`

In `lib/services/auth_service.dart`:
```dart
static const String _baseUrl = 'http://127.0.0.1:8000';
```

### Step 3: Run Flutter App

```bash
cd frontend

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 📋 API Endpoints Reference

### Authentication

```bash
# Register
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. John",
    "email": "john@example.com",
    "password": "password123",
    "specialization": "Neurology"
  }'

# Response:
{
  "token": "eyJhbGc...",
  "doctor": {
    "id": 1,
    "name": "Dr. John",
    "email": "john@example.com",
    "specialization": "Neurology",
    "patients": []
  }
}

# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'

# Get Current Doctor
curl -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Patient Management

```bash
# Create Patient
curl -X POST http://localhost:8000/api/patients \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "age": 45,
    "gender": "Male",
    "disease": "Glioma",
    "notes": "Initial assessment"
  }'

# List Patients
curl -X GET http://localhost:8000/api/patients \
  -H "Authorization: Bearer YOUR_TOKEN"

# Delete Patient
curl -X DELETE http://localhost:8000/api/patients/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### MRI Analysis

```bash
# Upload and Analyze MRI
curl -X POST http://localhost:8000/api/analysis/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@path/to/mri.jpg" \
  -F "patient_id=1"

# Get Analysis History
curl -X GET http://localhost:8000/api/analysis/patient/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔧 Configuration

### Backend Configuration (.env)

```env
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=mri_db
DB_PORT=5432

# Security
SECRET_KEY=your-secret-key  # Change in production!
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Frontend Connection
CORS_ORIGINS=http://localhost:5173,*  # Allow Flutter dev server
```

### Frontend Configuration (lib/services/auth_service.dart)

```dart
static const String _baseUrl = 'http://127.0.0.1:8000';  // Match backend URL
```

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| [DOCKER_SETUP.md](docs/DOCKER_SETUP.md) | Docker quick start |
| [DOCKER_COMMANDS.md](docs/DOCKER_COMMANDS.md) | Docker command reference |
| [DOCKER_DEPLOYMENT.md](docs/DOCKER_DEPLOYMENT.md) | Production deployment |
| [API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md) | Complete API reference |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture diagrams |

## ✅ Testing Workflow

### 1. Test Registration
1. Open Flutter app
2. Click "Register"
3. Fill in doctor details
4. Click "Register"
5. Should see home page with empty patient list

### 2. Test Patient Addition
1. Click "+" button in sidebar
2. Fill in patient details
3. Click "Add"
4. Patient should appear in sidebar

### 3. Test MRI Analysis
1. Select a patient (or add one)
2. Click "Select MRI Image"
3. Choose an image
4. Click "Get Analysis"
5. Results should display

### 4. Test Logout
1. Click menu (three dots)
2. Click "Logout"
3. Should return to login page

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check logs
docker-compose logs backend

# Rebuild
docker-compose down -v
docker-compose up --build
```

### Frontend can't connect to backend
- Verify backend is running: http://localhost:8000/docs
- Check firewall settings
- Try updating API URL to `http://localhost:8000` if using `127.0.0.1`

### Database connection error
- Wait 10-15 seconds for PostgreSQL to initialize
- Check: `docker-compose logs db`

### Port already in use
- Kill process: `lsof -i :8000` (macOS/Linux)
- Or change port in `docker-compose.yml`

## 📈 Performance Considerations

### Database
- Indexes on foreign keys for fast lookups
- Connection pooling enabled
- Query optimization for large datasets

### Backend
- Uvicorn with multiple workers in production
- CORS enabled for frontend communication
- JWT authentication for security

### Frontend
- Provider package for efficient state management
- Auto-login on app startup
- Secure token storage

## 🔒 Security Features

### Authentication
- JWT tokens with expiration
- Password hashing with bcrypt
- Refresh tokens supported

### Database
- SQL injection prevention (SQLAlchemy)
- Proper foreign keys
- User data isolation per doctor

### API
- CORS protection
- Rate limiting ready
- Input validation
- Error handling

## 📱 Mobile Deployment

For deploying the Flutter app:

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web
```

Update API URL for production:
```dart
static const String _baseUrl = 'https://your-api-domain.com';
```

## ☁️ Cloud Deployment

### AWS
- Use ECS for containers
- RDS for PostgreSQL
- ALB for load balancing

### Google Cloud
- Cloud Run for backend
- Cloud SQL for PostgreSQL
- Cloud Storage for images

### Azure
- App Service for FastAPI
- Azure Database for PostgreSQL
- Blob Storage for files

Docker images can be pushed to any registry:
```bash
docker build -t my-registry/mri-backend:1.0.0 .
docker push my-registry/mri-backend:1.0.0
```

## 📞 Support Resources

- [Docker Documentation](https://docs.docker.com)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Flutter Documentation](https://flutter.dev)
- [PostgreSQL Documentation](https://postgresql.org/docs)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org)

## ✨ Next Steps

1. ✅ Start Docker: `start-docker.bat` or `bash start-docker.sh`
2. ✅ Run Flutter: `flutter run`
3. ✅ Test registration and patient management
4. ✅ Deploy to production when ready

## 🎉 You're All Set!

Your complete MRI Analysis system is ready to use. Start with the quick start guide and refer to the documentation as needed.

For any issues, check the troubleshooting section or review the relevant documentation file.

Happy coding! 🚀
