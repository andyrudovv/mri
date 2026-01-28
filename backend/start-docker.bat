@echo off
REM Docker startup script for MRI Analysis Backend (Windows)

echo.
echo ========================================
echo  MRI Analysis Backend - Docker Startup
echo ========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose is not installed
    echo Please install Docker Desktop which includes Docker Compose
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo [WARNING] .env file not found
    echo Creating .env from .env.example...
    copy .env.example .env >nul
    echo [OK] .env file created. Please update it with your settings.
    echo.
)

REM Pull latest images
echo [*] Pulling latest Docker images...
docker-compose pull

REM Build images
echo [*] Building Docker images...
docker-compose build

REM Start services
echo [*] Starting services...
docker-compose up -d

REM Wait for services
echo [*] Waiting for services to be ready...
timeout /t 10 /nobreak

REM Check status
echo.
echo [*] Checking service status...
docker-compose ps

echo.
echo ========================================
echo  Startup Complete
echo ========================================
echo.
echo [OK] Services are running!
echo.
echo API Documentation:   http://localhost:8000/docs
echo Alternative Docs:    http://localhost:8000/redoc
echo.
echo Database Connection:
echo   Host: localhost
echo   Port: 5432
echo   User: postgres
echo   Database: mri_db
echo.
echo Useful Commands:
echo   View logs:      docker-compose logs -f
echo   Stop services:  docker-compose down
echo   View status:    docker-compose ps
echo.
pause
