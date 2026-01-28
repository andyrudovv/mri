# Quick Start Guide

## ⚡ 5-Minute Setup

### Step 1: PostgreSQL (2 minutes)

**Windows:**
1. Download from https://www.postgresql.org/download/windows/
2. Install with default settings
3. Remember the password you set for `postgres` user

**macOS:**
```bash
brew install postgresql
brew services start postgresql
```

**Linux:**
```bash
sudo apt-get install postgresql postgresql-contrib
```

### Step 2: Create Database (1 minute)

```bash
# Connect to PostgreSQL
psql -U postgres

# In psql prompt, type:
CREATE DATABASE mri_db;
\q
```

### Step 3: Setup Backend (2 minutes)

```bash
# Navigate to backend folder
cd backend

# Create .env file with your password
echo DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/mri_db > .env
echo SECRET_KEY=your-secret-key >> .env

# Install dependencies
pip install -r requirements.txt

# Start server
python -m uvicorn main:app --reload
```

**Server running!** 🎉
- API: http://localhost:8000
- Docs: http://localhost:8000/docs

## 📱 Frontend Configuration

The Flutter app is already configured to connect to `http://localhost:8000`

No changes needed! Just:
1. Make sure backend is running
2. Run the Flutter app

## 🧪 Quick Test

### In Swagger UI (http://localhost:8000/docs):

1. **Register Doctor**
   - Click "Try it out" on `POST /api/auth/register`
   - Fill in the form:
     ```
     name: Dr. John Doe
     email: john@example.com
     password: SecurePass123!
     specialization: Neurology
     ```
   - Click "Execute"
   - Copy the `token` from response

2. **Create Patient**
   - Click "Try it out" on `POST /api/patients`
   - Paste token in "Authorization" header
   - Fill form:
     ```
     name: John Smith
     age: 45
     gender: Male
     disease: Glioma
     notes: Test patient
     ```
   - Click "Execute"

3. **List Patients**
   - Click "Try it out" on `GET /api/patients`
   - Paste token in "Authorization" header
   - Click "Execute"

## 📝 File Structure

```
backend/
├── main.py                 # FastAPI app
├── database.py            # DB config
├── models.py              # SQLAlchemy models
├── schemas.py             # Pydantic schemas
├── security.py            # JWT & passwords
├── dependencies.py        # Auth middleware
├── .env                   # Configuration
├── requirements.txt       # Dependencies
├── routes/
│   ├── auth.py           # Login/Register
│   ├── patients.py       # Patient CRUD
│   └── analysis.py       # MRI Analysis
└── documentation files
```

## 🔌 Connection Details

**Frontend connects to:**
```
http://localhost:8000
```

**Database:**
```
Host: localhost
Port: 5432
Database: mri_db
User: postgres
Password: [your password]
```

## ⚠️ Troubleshooting

### "Cannot connect to database"
```bash
# Check PostgreSQL is running
# Windows: Services → PostgreSQL
# macOS: brew services list
# Linux: sudo systemctl status postgresql

# Check connection string in .env
# Should be: postgresql://postgres:YOUR_PASSWORD@localhost:5432/mri_db
```

### "ModuleNotFoundError"
```bash
pip install -r requirements.txt
```

### "Port 8000 already in use"
```bash
# Use different port
python -m uvicorn main:app --reload --port 8001
```

### "Invalid password"
```bash
# Reset postgres password
psql -U postgres
ALTER USER postgres WITH PASSWORD 'new_password';
\q
```

## 📊 API Endpoints Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/register` | Create doctor account |
| POST | `/api/auth/login` | Login doctor |
| GET | `/api/auth/me` | Get current doctor |
| PUT | `/api/auth/profile` | Update doctor info |
| GET | `/api/patients` | List all patients |
| POST | `/api/patients` | Create patient |
| GET | `/api/patients/{id}` | Get patient details |
| PUT | `/api/patients/{id}` | Update patient |
| DELETE | `/api/patients/{id}` | Delete patient |
| POST | `/api/analysis/predict/{id}` | Analyze MRI |
| GET | `/api/analysis/patient/{id}` | Get analysis history |

## 🔐 Authentication Flow

1. Register → Get `token`
2. Save `token`
3. Include in header: `Authorization: Bearer <token>`
4. Token lasts 30 minutes (configurable)

## 📚 Full Documentation

- **API_DOCUMENTATION.md** - Complete API reference
- **POSTGRES_SETUP.md** - Detailed PostgreSQL guide
- **API_TESTING.md** - Testing examples
- **BACKEND_SUMMARY.md** - Technical overview

## 🚀 Next Steps

1. ✅ Setup PostgreSQL
2. ✅ Install backend dependencies
3. ✅ Start backend server
4. ✅ Test endpoints in Swagger UI
5. Run Flutter app
6. Login and create patients
7. Upload MRI images

## 💡 Development Tips

**Live API documentation:** http://localhost:8000/docs
- Test all endpoints
- See request/response formats
- No external tools needed

**Database queries:**
```bash
psql -U postgres -d mri_db
SELECT * FROM doctors;
SELECT * FROM patients;
\q
```

**View server logs:**
```
Watching for file changes...
Uvicorn running on http://127.0.0.1:8000
```

## 🆘 Support

If you encounter issues:

1. Check that PostgreSQL is running
2. Verify .env file has correct DATABASE_URL
3. Ensure port 8000 is not in use
4. Check error messages in terminal
5. See POSTGRES_SETUP.md for database issues
6. See API_TESTING.md for API issues

---

**Ready to go!** 🎉

Start the backend and begin testing the MRI Analysis System.
