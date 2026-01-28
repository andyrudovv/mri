@echo off
REM MRI Analysis Backend Startup Script for Windows

echo.
echo ===================================
echo  MRI Analysis Backend Startup
echo ===================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if requirements are installed
python -m pip show fastapi >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing dependencies...
    python -m pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo Error: Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Check if .env file exists
if not exist .env (
    echo Warning: .env file not found. Creating from template...
    echo DATABASE_URL=postgresql://postgres:password@localhost:5432/mri_db > .env
    echo SECRET_KEY=your-secret-key-change-in-production >> .env
    echo.
    echo Please edit .env file with your PostgreSQL credentials
    echo.
)

REM Start the server
echo Starting FastAPI server...
echo.
echo API will be available at: http://localhost:8000
echo Docs at: http://localhost:8000/docs
echo.

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

pause
