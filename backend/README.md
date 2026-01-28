# Backend Documentation Index

## Quick Links

### � Docker (Recommended)
- [DOCKER_SETUP.md](docs/DOCKER_SETUP.md) - **Recommended!** Complete Docker setup guide
- [DOCKER_COMMANDS.md](docs/DOCKER_COMMANDS.md) - Docker commands reference and cheat sheet

### 🚀 Getting Started (Traditional)
- [QUICKSTART.md](docs/QUICKSTART.md) - 5-minute setup guide (without Docker)
- [POSTGRES_SETUP.md](docs/POSTGRES_SETUP.md) - PostgreSQL installation and configuration

### 📚 Comprehensive Guides
- [API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md) - Complete API reference with all endpoints
- [BACKEND_SUMMARY.md](docs/BACKEND_SUMMARY.md) - Technical overview and features
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design and data flow diagrams

### 🧪 Testing & Examples
- [API_TESTING.md](docs/API_TESTING.md) - cURL examples, PowerShell scripts, Python examples

### 📁 Source Code
- [main.py](main.py) - FastAPI application entry point
- [database.py](database.py) - Database configuration
- [models.py](models.py) - SQLAlchemy ORM models
- [schemas.py](schemas.py) - Pydantic request/response schemas
- [security.py](security.py) - JWT and password utilities
- [dependencies.py](dependencies.py) - FastAPI dependency injection
- [routes/auth.py](routes/auth.py) - Authentication endpoints
- [routes/patients.py](routes/patients.py) - Patient management endpoints
- [routes/analysis.py](routes/analysis.py) - MRI analysis endpoints

## Quick Start with Docker (Recommended)

### 1. One-Line Setup
```bash
# Windows
start-docker.bat

# Linux/macOS
bash start-docker.sh
```

### 2. Or Manual Setup
```bash
cd backend
docker-compose up --build
```

### 3. Access Services
- **API Docs**: http://localhost:8000/docs
- **Database**: localhost:5432 (postgres:password)

### Additional Resources
- [DOCKER_SETUP.md](docs/DOCKER_SETUP.md) - Complete Docker guide
- [DOCKER_COMMANDS.md](docs/DOCKER_COMMANDS.md) - Command reference
- [DOCKER_DEPLOYMENT.md](docs/DOCKER_DEPLOYMENT.md) - Deployment guide
- [DOCKER_IMPLEMENTATION.md](DOCKER_IMPLEMENTATION.md) - Implementation summary

## Traditional Setup (Without Docker)

See [QUICKSTART.md](docs/QUICKSTART.md) and [POSTGRES_SETUP.md](docs/POSTGRES_SETUP.md)
- Backup/restore procedures

**Key sections:**
- Platform-specific installation
- User and privilege management
- Connection string configuration
- Troubleshooting guide

### API_DOCUMENTATION.md
**Best for:** Complete API reference and integration
- All 15+ API endpoints
- Request/response examples
- Authentication details
- Error handling
- Database schema
- Security considerations

**Key sections:**
- Authentication flow
- Patient management CRUD
- MRI analysis endpoints
- Error codes and messages
- Development tips

### BACKEND_SUMMARY.md
**Best for:** Understanding the technical architecture
- File structure and organization
- Database schema relationships
- Security features implemented
- Integration points with frontend

**Key sections:**
- Files created and purpose
- Route documentation
- Database design
- Feature list
- Security features

### ARCHITECTURE.md
**Best for:** Visual understanding of system design
- ASCII diagrams of system architecture
- Database schema relationships
- Request/response flows
- Authentication flow visualization
- Deployment architecture
- Security layers

**Key sections:**
- High-level architecture diagram
- Backend architecture components
- Database schema diagram
- Various request flows (Auth, Patients, Analysis)
- Production deployment setup

### API_TESTING.md
**Best for:** Testing endpoints with various tools
- cURL command examples (all 12 endpoints)
- PowerShell examples for Windows users
- Python script examples
- Postman collection setup
- Performance testing
- Integration testing

**Key sections:**
- 12 working cURL examples
- PowerShell version
- Full Python script
- Postman import guide
- Error response examples

## File Structure

```
backend/
├── QUICKSTART.md                 # Start here!
├── POSTGRES_SETUP.md             # Database setup
├── API_DOCUMENTATION.md          # API reference
├── BACKEND_SUMMARY.md            # Technical summary
├── ARCHITECTURE.md               # System diagrams
├── API_TESTING.md                # Testing examples
│
├── main.py                       # FastAPI app
├── database.py                   # DB connection
├── models.py                     # SQLAlchemy models
├── schemas.py                    # Pydantic schemas
├── security.py                   # JWT & password
├── dependencies.py               # Auth middleware
├── .env                          # Configuration
├── requirements.txt              # Dependencies
├── run.bat                       # Windows startup
├── run.sh                        # Linux/macOS startup
│
└── routes/
    ├── __init__.py
    ├── auth.py                   # Login/Register
    ├── patients.py               # Patient CRUD
    └── analysis.py               # MRI Analysis
```

## Setup Sequence

### 1️⃣ First Time Setup
Read in this order:
1. QUICKSTART.md (5 minutes)
2. POSTGRES_SETUP.md (if stuck on database)
3. Run the server

### 2️⃣ API Testing
1. API_DOCUMENTATION.md (understand endpoints)
2. Go to http://localhost:8000/docs
3. Test endpoints in Swagger UI

### 3️⃣ Advanced Development
1. ARCHITECTURE.md (understand design)
2. BACKEND_SUMMARY.md (code overview)
3. Look at source files (models.py, routes/, etc.)

### 4️⃣ Integration Testing
1. API_TESTING.md (all testing methods)
2. Run test scripts
3. Debug with examples

## Quick Reference

### Critical Files

**main.py** - The entry point
```python
# Run with:
python -m uvicorn main:app --reload
```

**models.py** - Database structure
```python
# Contains: Doctor, Patient, MRIAnalysis, RefreshToken
```

**routes/auth.py** - Authentication (5 endpoints)
```python
# Register, Login, Logout, Get Profile, Update Profile
```

**routes/patients.py** - Patient CRUD (5 endpoints)
```python
# List, Create, Get, Update, Delete
```

**routes/analysis.py** - MRI Analysis (2 endpoints)
```python
# Predict, Get History
```

### Key Endpoints

```
# Authentication
POST   /api/auth/register      → Get access token
POST   /api/auth/login         → Get access token
GET    /api/auth/me            → Current doctor
PUT    /api/auth/profile       → Update doctor
POST   /api/auth/logout        → Invalidate token

# Patients
GET    /api/patients           → List patients
POST   /api/patients           → Create patient
GET    /api/patients/{id}      → Get patient
PUT    /api/patients/{id}      → Update patient
DELETE /api/patients/{id}      → Delete patient

# Analysis
POST   /api/analysis/predict/{id}    → Analyze MRI
GET    /api/analysis/patient/{id}    → Get analyses
```

### Database Connection

```
Host:     localhost
Port:     5432
Database: mri_db
User:     postgres
Password: [YOUR_PASSWORD]

Connection String:
postgresql://postgres:PASSWORD@localhost:5432/mri_db
```

### Environment Variables (.env)

```
DATABASE_URL=postgresql://postgres:password@localhost:5432/mri_db
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

## Common Tasks

### Starting the Server

**Windows:**
```bash
run.bat
```

**Linux/macOS:**
```bash
bash run.sh
```

**Manual:**
```bash
pip install -r requirements.txt
python -m uvicorn main:app --reload
```

### Testing an Endpoint

**Option 1: Swagger UI**
- Open http://localhost:8000/docs
- Click endpoint, "Try it out"
- Enter data and execute

**Option 2: cURL**
```bash
curl -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Option 3: Python**
```python
import requests
response = requests.get(
    "http://localhost:8000/api/auth/me",
    headers={"Authorization": f"Bearer {token}"}
)
print(response.json())
```

### Database Tasks

**Connect to database:**
```bash
psql -U postgres -d mri_db
```

**View tables:**
```sql
SELECT * FROM doctors;
SELECT * FROM patients;
SELECT * FROM mri_analyses;
```

**Reset database:**
```bash
# Delete database
dropdb -U postgres mri_db

# Recreate
createdb -U postgres mri_db

# Restart server (tables auto-created)
```

## Debugging

### "Port already in use"
```bash
# Use different port
python -m uvicorn main:app --reload --port 8001
```

### "Cannot connect to database"
1. Check PostgreSQL is running
2. Verify DATABASE_URL in .env
3. Test connection: `psql -U postgres -d mri_db`

### "Module not found"
```bash
pip install -r requirements.txt
```

### "Invalid token"
1. Token may be expired (30 minutes)
2. Login again to get new token
3. Check token format: `Bearer <token>`

## Frontend Integration

The Flutter frontend is already configured:
- Connects to `http://localhost:8000`
- AuthService handles all API calls
- Token stored in SharedPreferences
- Ready to use!

### To connect frontend:
1. Ensure backend is running
2. Run Flutter app
3. Register/Login in app
4. Create patients
5. Upload MRI images

## Production Checklist

Before deploying to production:

- [ ] Change `SECRET_KEY` to strong random string
- [ ] Set `DATABASE_URL` to production database
- [ ] Enable HTTPS (SSL/TLS)
- [ ] Set specific CORS origins
- [ ] Use environment variables for secrets
- [ ] Enable request logging
- [ ] Setup database backups
- [ ] Configure rate limiting
- [ ] Use production ASGI server (Gunicorn)
- [ ] Monitor server health

See ARCHITECTURE.md for production deployment setup.

## Support Resources

### For Database Issues
→ See POSTGRES_SETUP.md

### For API Issues
→ See API_DOCUMENTATION.md

### For Testing
→ See API_TESTING.md

### For Architecture Questions
→ See ARCHITECTURE.md

### For Troubleshooting
→ See QUICKSTART.md (Troubleshooting section)

## Additional Resources

- FastAPI Documentation: https://fastapi.tiangolo.com/
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- SQLAlchemy Documentation: https://docs.sqlalchemy.org/
- JWT Documentation: https://tools.ietf.org/html/rfc7519

## Summary

- **QUICKSTART.md** = Your first stop (5 minutes)
- **POSTGRES_SETUP.md** = If database help needed
- **API_DOCUMENTATION.md** = For complete API reference
- **API_TESTING.md** = For testing examples
- **ARCHITECTURE.md** = For understanding design
- **BACKEND_SUMMARY.md** = For technical overview

---

**Status:** ✅ Complete & Ready for Production

**Features Implemented:**
- ✅ Doctor authentication (register/login)
- ✅ Patient management (CRUD)
- ✅ MRI analysis integration
- ✅ JWT security
- ✅ PostgreSQL database
- ✅ Comprehensive API documentation
- ✅ Error handling
- ✅ CORS support
- ✅ Automatic schema creation

**Next Steps:**
1. Set up PostgreSQL (POSTGRES_SETUP.md)
2. Start backend (QUICKSTART.md)
3. Test endpoints (API_TESTING.md or Swagger UI)
4. Connect Flutter frontend
5. Deploy to production (ARCHITECTURE.md)
