# API Testing Examples

## Using cURL from Command Line

### 1. Register a New Doctor

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. Sarah Johnson",
    "email": "sarah.johnson@hospital.com",
    "password": "SecurePassword123!",
    "specialization": "Neurology"
  }'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "doctor": {
    "id": 1,
    "name": "Dr. Sarah Johnson",
    "email": "sarah.johnson@hospital.com",
    "specialization": "Neurology",
    "profileImage": null,
    "patients": [],
    "createdAt": "2024-01-28T10:00:00"
  }
}
```

### 2. Login Doctor

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "sarah.johnson@hospital.com",
    "password": "SecurePassword123!"
  }'
```

### 3. Get Current Doctor Profile

Save the token from login response and use it:

```bash
curl -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 4. Update Doctor Profile

```bash
curl -X PUT http://localhost:8000/api/auth/profile \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. Sarah Johnson MD",
    "specialization": "Neurosurgery",
    "profileImage": "https://example.com/profile.jpg"
  }'
```

### 5. Create a Patient

```bash
curl -X POST http://localhost:8000/api/patients \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "age": 45,
    "gender": "Male",
    "disease": "Glioma",
    "notes": "Patient has history of headaches"
  }'
```

### 6. Get All Patients

```bash
curl -X GET http://localhost:8000/api/patients \
  -H "Authorization: Bearer <your_token>"
```

### 7. Get Specific Patient

```bash
curl -X GET http://localhost:8000/api/patients/1 \
  -H "Authorization: Bearer <your_token>"
```

### 8. Update Patient

```bash
curl -X PUT http://localhost:8000/api/patients/1 \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 46,
    "notes": "Updated patient notes"
  }'
```

### 9. Delete Patient

```bash
curl -X DELETE http://localhost:8000/api/patients/1 \
  -H "Authorization: Bearer <your_token>"
```

### 10. Upload and Analyze MRI

```bash
curl -X POST http://localhost:8000/api/analysis/predict/1 \
  -H "Authorization: Bearer <your_token>" \
  -F "file=@/path/to/mri_image.jpg"
```

### 11. Get Patient Analyses History

```bash
curl -X GET http://localhost:8000/api/analysis/patient/1 \
  -H "Authorization: Bearer <your_token>"
```

### 12. Logout

```bash
curl -X POST http://localhost:8000/api/auth/logout \
  -H "Authorization: Bearer <your_token>"
```

## Using PowerShell (Windows)

### Register Doctor

```powershell
$body = @{
    name = "Dr. Sarah Johnson"
    email = "sarah.johnson@hospital.com"
    password = "SecurePassword123!"
    specialization = "Neurology"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/api/auth/register" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body
```

### Create Patient

```powershell
$token = "your_token_here"
$body = @{
    name = "John Smith"
    age = 45
    gender = "Male"
    disease = "Glioma"
    notes = "Patient history"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/api/patients" `
  -Method POST `
  -Headers @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
  } `
  -Body $body
```

## Using Python Requests

### Full Example Script

```python
import requests
import json

BASE_URL = "http://localhost:8000"

# 1. Register
registration_data = {
    "name": "Dr. Sarah Johnson",
    "email": "sarah.johnson@hospital.com",
    "password": "SecurePassword123!",
    "specialization": "Neurology"
}

response = requests.post(
    f"{BASE_URL}/api/auth/register",
    json=registration_data
)

result = response.json()
token = result['token']
print(f"Registered successfully. Token: {token}")

# 2. Create patient
patient_data = {
    "name": "John Smith",
    "age": 45,
    "gender": "Male",
    "disease": "Glioma",
    "notes": "Patient notes"
}

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

response = requests.post(
    f"{BASE_URL}/api/patients",
    json=patient_data,
    headers=headers
)

patient_result = response.json()
patient_id = patient_result['patients'][0]['id']
print(f"Patient created with ID: {patient_id}")

# 3. Upload MRI
with open('path/to/mri.jpg', 'rb') as f:
    files = {'file': f}
    response = requests.post(
        f"{BASE_URL}/api/analysis/predict/{patient_id}",
        files=files,
        headers={"Authorization": f"Bearer {token}"}
    )

analysis = response.json()
print(f"Analysis complete: {analysis}")
```

## Using Postman

1. **Create a new Collection** for MRI Analysis API

2. **Add Authorization** (for all requests):
   - Type: Bearer Token
   - Token: `{{token}}` (use Postman environment variable)

3. **Save token from login response**:
   - In Tests tab of login request:
   ```javascript
   var jsonData = pm.response.json();
   pm.environment.set("token", jsonData.token);
   ```

4. **Import these requests and organize by folder:**
   - Authentication
   - Patients
   - Analysis

## Debugging Tips

### Check Request/Response
```bash
# Verbose mode
curl -v -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer <token>"

# Show headers only
curl -i -X GET http://localhost:8000/api/auth/me \
  -H "Authorization: Bearer <token>"
```

### View Response Body Pretty
```bash
curl -X GET http://localhost:8000/api/patients \
  -H "Authorization: Bearer <token>" | python -m json.tool
```

### Save Response to File
```bash
curl -X GET http://localhost:8000/api/patients \
  -H "Authorization: Bearer <token>" > response.json
```

## Common Error Responses

### Unauthorized (401)
```json
{
  "detail": "Invalid or expired token"
}
```
**Fix:** Check token is valid and not expired

### Not Found (404)
```json
{
  "detail": "Patient not found"
}
```
**Fix:** Verify patient ID exists and belongs to authenticated doctor

### Bad Request (400)
```json
{
  "detail": "Invalid image type"
}
```
**Fix:** Check request data format and content type

### Duplicate Email (400)
```json
{
  "detail": "Email already registered"
}
```
**Fix:** Use a different email address

## Performance Testing

Load test with Apache Bench:
```bash
# 100 requests, 10 concurrent
ab -n 100 -c 10 http://localhost:8000/health
```

## Integration Testing

Combine multiple operations:

```bash
#!/bin/bash

# Set variables
EMAIL="test$(date +%s)@example.com"
PASSWORD="TestPass123!"
BASE_URL="http://localhost:8000"

echo "1. Registering doctor..."
RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Dr. Test\",
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"specialization\": \"Neurology\"
  }")

TOKEN=$(echo $RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Token: $TOKEN"

echo "2. Creating patient..."
curl -s -X POST $BASE_URL/api/patients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Patient",
    "age": 40,
    "gender": "Male",
    "disease": "Glioma"
  }' | python -m json.tool

echo "3. Listing patients..."
curl -s -X GET $BASE_URL/api/patients \
  -H "Authorization: Bearer $TOKEN" | python -m json.tool
```

Save as `test.sh` and run: `bash test.sh`
