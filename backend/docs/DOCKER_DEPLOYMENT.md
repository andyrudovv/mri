# MRI Analysis Backend - Docker Deployment Guide

## 📋 Contents
1. [System Architecture](#system-architecture)
2. [Docker Setup](#docker-setup)
3. [Running the Application](#running-the-application)
4. [Container Management](#container-management)
5. [Database Operations](#database-operations)
6. [Troubleshooting](#troubleshooting)
7. [Production Considerations](#production-considerations)

## System Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Docker Network                          │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────┐                               │
│  │   FastAPI Container     │                               │
│  ├─────────────────────────┤                               │
│  │ - Python 3.12           │                               │
│  │ - FastAPI App           │                               │
│  │ - Port: 8000            │                               │
│  │ - Volume: /app (code)   │                               │
│  └──────────────┬──────────┘                               │
│                 │                                           │
│                 │ (TCP/5432)                                │
│                 ↓                                           │
│  ┌─────────────────────────┐                               │
│  │  PostgreSQL Container   │                               │
│  ├─────────────────────────┤                               │
│  │ - PostgreSQL 16         │                               │
│  │ - Port: 5432            │                               │
│  │ - Database: mri_db      │                               │
│  │ - Volume: postgres_data │                               │
│  └─────────────────────────┘                               │
│                                                             │
└────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   Host Machine       │
├──────────────────────┤
│ :8000 → backend:8000 │
│ :5432 → db:5432      │
└──────────────────────┘
```

## Docker Setup

### Prerequisites
- Docker Desktop installed ([Download](https://www.docker.com/products/docker-desktop))
- Docker Compose (included with Docker Desktop)
- 2GB+ available RAM
- 5GB+ available disk space

### Files Created

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Orchestrates PostgreSQL and FastAPI containers |
| `Dockerfile` | Builds the FastAPI application image |
| `.dockerignore` | Excludes unnecessary files from Docker build |
| `init.sql` | Initializes PostgreSQL database schema |
| `.env.example` | Template for environment variables |

### Environment Configuration

The `.env` file controls all settings:

```env
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password           # Change in production!
POSTGRES_DB=mri_db
DB_PORT=5432

# Application
SECRET_KEY=your-secret-key          # Change in production!
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
BACKEND_PORT=8000

# Security
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
DEBUG=False
```

## Running the Application

### Method 1: Automated Script

#### Windows
```bash
# Run the startup script
start-docker.bat

# Or
.\start-docker.bat
```

#### Linux/macOS
```bash
# Make script executable
chmod +x start-docker.sh

# Run the startup script
./start-docker.sh
```

### Method 2: Manual Docker Compose Commands

```bash
# Navigate to backend directory
cd backend

# Build and start all services
docker-compose up --build

# Start services in background
docker-compose up -d --build

# Stop all services
docker-compose down

# View running services
docker-compose ps

# View logs
docker-compose logs -f
```

### Accessing the Application

Once running, access:

| Service | URL |
|---------|-----|
| **Swagger UI** | http://localhost:8000/docs |
| **ReDoc** | http://localhost:8000/redoc |
| **PostgreSQL** | localhost:5432 |

### Test the API

```bash
# Quick health check
curl http://localhost:8000/docs

# Or use PowerShell
Invoke-WebRequest http://localhost:8000/docs
```

## Container Management

### View Container Status

```bash
# See all running containers
docker-compose ps

# See all containers (running and stopped)
docker-compose ps -a

# View container details
docker inspect mri_backend
docker inspect mri_postgres_db
```

### View Logs

```bash
# View all logs
docker-compose logs

# View backend logs only
docker-compose logs backend

# View database logs only
docker-compose logs db

# Follow logs in real-time
docker-compose logs -f

# View last 50 lines
docker-compose logs --tail=50
```

### Execute Commands in Containers

```bash
# Run commands in backend
docker-compose exec backend bash
docker-compose exec backend python -c "import sys; print(sys.version)"

# Access PostgreSQL
docker-compose exec db psql -U postgres -d mri_db

# Check Python version
docker-compose exec backend python --version

# List installed packages
docker-compose exec backend pip list
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend
docker-compose restart db

# Stop and start
docker-compose stop
docker-compose start
```

## Database Operations

### Connect to PostgreSQL

```bash
# From host machine
psql -h localhost -U postgres -d mri_db

# From within Docker
docker-compose exec db psql -U postgres -d mri_db

# List all databases
docker-compose exec db psql -U postgres -l

# List all tables
docker-compose exec db psql -U postgres -d mri_db -c "\dt"
```

### Database Backup

```bash
# Backup database to SQL file
docker-compose exec db pg_dump -U postgres -d mri_db > backup.sql

# Backup with compression
docker-compose exec db pg_dump -U postgres -d mri_db | gzip > backup.sql.gz

# Backup with timestamp
docker-compose exec db pg_dump -U postgres -d mri_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Database Restore

```bash
# Restore from backup
docker-compose exec -T db psql -U postgres -d mri_db < backup.sql

# Restore from compressed backup
gunzip -c backup.sql.gz | docker-compose exec -T db psql -U postgres -d mri_db
```

### Reset Database

```bash
# Clear all data (keep tables)
docker-compose exec db psql -U postgres -d mri_db \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Delete everything and restart
docker-compose down -v
docker-compose up -d
```

### Database Query Examples

```bash
# Count users
docker-compose exec db psql -U postgres -d mri_db -c "SELECT COUNT(*) FROM users;"

# List all users
docker-compose exec db psql -U postgres -d mri_db -c "SELECT id, name, email FROM users;"

# Count patients
docker-compose exec db psql -U postgres -d mri_db -c "SELECT COUNT(*) FROM patients;"

# View user-patient relationship
docker-compose exec db psql -U postgres -d mri_db -c \
  "SELECT u.name, COUNT(p.id) as patient_count FROM users u LEFT JOIN patients p ON u.id = p.doctor_id GROUP BY u.id, u.name;"
```

## Troubleshooting

### Container Won't Start

**Problem**: Container exits immediately
```bash
# Check logs
docker-compose logs backend
docker-compose logs db

# Rebuild without cache
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

### Database Connection Failed

**Problem**: Backend can't connect to PostgreSQL
```bash
# Verify database is running
docker-compose ps

# Check database logs
docker-compose logs db

# Test connection manually
docker-compose exec backend python -c "
from sqlalchemy import create_engine
try:
    engine = create_engine('postgresql://postgres:password@db:5432/mri_db')
    with engine.connect() as conn:
        result = conn.execute('SELECT 1')
        print('✓ Connected successfully')
except Exception as e:
    print(f'✗ Connection failed: {e}')
"
```

### Port Already in Use

**Problem**: "Port 8000 is already in use"
```bash
# Find process using port
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/macOS
lsof -i :8000
kill -9 <PID>
```

### Slow Performance

**Solutions**:
1. Check available RAM: `docker stats`
2. Increase Docker memory allocation in Docker Desktop settings
3. Check disk space: `docker system df`
4. Remove unused images: `docker image prune`

### Database Migration Issues

**Problem**: Tables not created
```bash
# Check initialization log
docker-compose logs db | grep "init.sql"

# Manually initialize (if needed)
docker-compose exec db psql -U postgres -d mri_db < init.sql

# Verify tables exist
docker-compose exec db psql -U postgres -d mri_db -c "\dt"
```

## Production Considerations

### Security Checklist

- [ ] Change `POSTGRES_PASSWORD` to strong password
- [ ] Generate new `SECRET_KEY` (use: `python -c "import secrets; print(secrets.token_urlsafe(32))"`)
- [ ] Set `DEBUG=False`
- [ ] Configure `CORS_ORIGINS` to specific domains
- [ ] Use SSL/TLS for production
- [ ] Enable database backups
- [ ] Set up logging and monitoring
- [ ] Configure health checks

### Production docker-compose.yml Modifications

```yaml
services:
  backend:
    restart: always
    # Use gunicorn instead of uvicorn for production
    command: gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    environment:
      DEBUG: "False"
      # Use environment variables from .env in production

  db:
    restart: always
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # From .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    # Add resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

### Monitoring & Logging

```bash
# Monitor resource usage
docker stats

# Save logs for analysis
docker-compose logs > app.log

# Real-time monitoring
docker stats --no-stream

# Container resource limits
docker-compose.yml with deploy.resources
```

### Backup Strategy

```bash
# Daily backup script
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/mri_backup_$DATE.sql.gz"

docker-compose exec -T db pg_dump -U postgres -d mri_db | gzip > $BACKUP_FILE

# Keep only last 7 days
find $BACKUP_DIR -name "mri_backup_*.sql.gz" -mtime +7 -delete
```

### Deployment Platforms

**Docker Hub/Registry**:
```bash
# Build image for registry
docker-compose build --pull

# Tag image
docker tag mri_backend myregistry/mri_backend:1.0.0

# Push to registry
docker push myregistry/mri_backend:1.0.0
```

**AWS ECS, Google Cloud Run, Azure Container Instances**:
These platforms support docker-compose and Docker images directly.

## Support & Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
