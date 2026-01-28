# MRI Analysis Backend API

FastAPI-based REST API for MRI image analysis with doctor and patient management using PostgreSQL.

## Features

- **Doctor Authentication**: Register, login, and profile management
- **Patient Management**: CRUD operations for patient records
- **MRI Analysis**: Upload and analyze MRI images using deep learning models
- **JWT Security**: Secure token-based authentication
- **Database**: PostgreSQL with SQLAlchemy ORM
- **CORS Support**: Cross-origin requests enabled

## Project Structure

```
backend/
├── main.py                 # FastAPI application entry point
├── database.py            # Database configuration and session management
├── models.py              # SQLAlchemy database models
├── schemas.py             # Pydantic request/response schemas
├── security.py            # JWT token and password hashing utilities
├── dependencies.py        # FastAPI dependency injection
├── requirements.txt       # Python dependencies
├── .env                   # Environment variables
└── routes/
    ├── __init__.py
    ├── auth.py           # Authentication endpoints
    ├── patients.py       # Patient management endpoints
    └── analysis.py       # MRI analysis endpoints
```

## Database Models

### Doctor
- **id** (Integer, Primary Key)
- **name** (String, Required)
- **email** (String, Unique, Required)
- **password_hash** (String, Required)
- **specialization** (String, Required)
- **profile_image** (String, Optional)
- **created_at** (DateTime)
- **updated_at** (DateTime)
- **Relationships**: patients, tokens

### Patient
- **id** (Integer, Primary Key)
- **doctor_id** (Integer, Foreign Key)
- **name** (String, Required)
- **age** (Integer, Required)
- **gender** (String, Required)
- **disease** (String, Required)
- **notes** (Text, Optional)
- **created_at** (DateTime)
- **updated_at** (DateTime)
- **Relationships**: doctor, analyses

### MRIAnalysis
- **id** (Integer, Primary Key)
- **patient_id** (Integer, Foreign Key)
- **image_path** (String)
- **predicted_class** (String)
- **probabilities** (String, JSON)
- **created_at** (DateTime)
- **Relationships**: patient

### RefreshToken
- **id** (Integer, Primary Key)
- **doctor_id** (Integer, Foreign Key)
- **token** (String, Unique)
- **expires_at** (DateTime)
- **created_at** (DateTime)
- **Relationships**: doctor

## Installation

### Prerequisites
- Python 3.9+
- PostgreSQL 12+
- pip or conda

### Setup Steps

1. **Install dependencies**
```bash
pip install -r requirements.txt
```

2. **Create PostgreSQL database**
```sql
CREATE DATABASE mri_db;
```

3. **Configure environment variables**
Edit `.env` file with your settings:
```
DATABASE_URL=postgresql://user:password@localhost:5432/mri_db
SECRET_KEY=your-super-secret-key-here
```

4. **Run migrations** (tables are created automatically on first run)

5. **Start the server**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Authentication (`/api/auth`)

#### Register Doctor
```
POST /api/auth/register
Content-Type: application/json

{
  "name": "Dr. John Doe",
  "email": "john@example.com",
  "password": "SecurePassword123!",
  "specialization": "Neurology"
}

Response:
{
  "token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "doctor": {
    "id": 1,
    "name": "Dr. John Doe",
    "email": "john@example.com",
    "specialization": "Neurology",
    "profileImage": null,
    "patients": [],
    "createdAt": "2024-01-28T10:00:00"
  }
}
```

#### Login Doctor
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}

Response: Same as register
```

#### Get Current Doctor
```
GET /api/auth/me
Authorization: Bearer <access_token>

Response: Doctor object
```

#### Update Profile
```
PUT /api/auth/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Dr. Jane Doe",
  "specialization": "Neurosurgery",
  "profileImage": "https://example.com/image.jpg"
}

Response: Updated doctor object
```

#### Logout
```
POST /api/auth/logout
Authorization: Bearer <access_token>

Response:
{
  "message": "Logged out successfully"
}
```

### Patients (`/api/patients`)

#### Get All Patients
```
GET /api/patients
Authorization: Bearer <access_token>

Response:
{
  "patients": [
    {
      "id": 1,
      "name": "John Smith",
      "age": 45,
      "gender": "Male",
      "disease": "Glioma",
      "notes": "Patient notes here",
      "createdAt": "2024-01-28T10:00:00"
    }
  ]
}
```

#### Create Patient
```
POST /api/patients
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "John Smith",
  "age": 45,
  "gender": "Male",
  "disease": "Glioma",
  "notes": "Optional notes"
}

Response: Updated doctor object with new patient
```

#### Get Specific Patient
```
GET /api/patients/{patient_id}
Authorization: Bearer <access_token>

Response: Patient object
```

#### Update Patient
```
PUT /api/patients/{patient_id}
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Updated Name",
  "age": 46,
  "disease": "Updated Disease"
}

Response: Updated patient object
```

#### Delete Patient
```
DELETE /api/patients/{patient_id}
Authorization: Bearer <access_token>

Response:
{
  "message": "Patient deleted successfully"
}
```

### MRI Analysis (`/api/analysis`)

#### Analyze MRI Image
```
POST /api/analysis/predict/{patient_id}
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

Body:
  file: <image_file>

Response:
{
  "id": 1,
  "patientId": 1,
  "imagePath": "/tmp/tmpxxxxx.jpg",
  "predictedClass": "glioma",
  "probabilities": "{\"glioma\": 0.95, \"meningioma\": 0.03, ...}",
  "createdAt": "2024-01-28T10:00:00"
}
```

#### Get Patient Analyses
```
GET /api/analysis/patient/{patient_id}
Authorization: Bearer <access_token>

Response: Array of analysis objects
```

### Health Check

#### Check API Status
```
GET /health

Response:
{
  "status": "healthy"
}
```

## Authentication

All protected endpoints require a JWT access token in the Authorization header:

```
Authorization: Bearer <access_token>
```

Tokens are obtained through the login or register endpoints.

## Error Handling

The API returns standard HTTP status codes with error details:

```
{
  "detail": "Error message describing what went wrong"
}
```

Common status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (invalid/missing token)
- `404` - Not Found
- `500` - Server Error

## Development

### Running with hot reload
```bash
uvicorn main:app --reload
```

### Interactive API documentation
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Database shell
```bash
psql -U postgres -d mri_db
```

## Security Considerations

1. **Change SECRET_KEY** in production
2. **Use HTTPS** in production
3. **Set restrictive CORS** origins
4. **Use environment variables** for sensitive data
5. **Hash passwords** using bcrypt (already implemented)
6. **Implement rate limiting** for production
7. **Use secure cookies** with HttpOnly and Secure flags
8. **Validate all inputs** (already done with Pydantic)

## Future Enhancements

- [ ] Email verification
- [ ] Password reset functionality
- [ ] Refresh token rotation
- [ ] API key authentication
- [ ] Rate limiting
- [ ] Request logging
- [ ] Detailed error tracking
- [ ] Analytics and reporting
- [ ] Multi-language support
- [ ] WebSocket support for real-time updates

## License

This project is part of the MRI Analysis System.
