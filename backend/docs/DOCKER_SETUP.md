# Docker Setup Guide for MRI Analysis Backend

## Overview
This guide explains how to run the MRI Analysis API with PostgreSQL using Docker and Docker Compose.

## Prerequisites
- Docker Desktop installed ([download here](https://www.docker.com/products/docker-desktop))
- Docker Compose (included with Docker Desktop)
- At least 2GB of available RAM for containers

## Quick Start

### 1. Build and Start Containers
```bash
# Navigate to backend directory
cd backend

# Build and start all services
docker-compose up --build
```

This command will:
- Build the FastAPI backend image
- Start PostgreSQL container
- Start the FastAPI backend container
- Automatically create the database and tables

### 2. Verify Services are Running
```bash
# Check running containers
docker ps
```

You should see:
- `mri_postgres_db` - PostgreSQL database
- `mri_backend` - FastAPI backend

### 3. Access the API
- **API Documentation**: http://localhost:8000/docs
- **Alternative API Docs**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health (if implemented)

## Environment Configuration

### Using .env File
The application uses environment variables from `.env` file:

```env
# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=mri_db
DB_PORT=5432

# API
SECRET_KEY=your-super-secret-key-change-this-in-production-12345
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
BACKEND_PORT=8000
```

### Update Credentials (Production)
1. Copy `.env.example` to `.env`
2. Update sensitive values:
   - `POSTGRES_PASSWORD` - Strong database password
   - `SECRET_KEY` - Generate a strong secret key
   - `CORS_ORIGINS` - Restrict to your Flutter app URL

## Common Commands

### Start Services
```bash
# Start in foreground (see logs)
docker-compose up

# Start in background
docker-compose up -d
```

### Stop Services
```bash
# Stop all containers
docker-compose down

# Stop and remove volumes (WARNING: loses database data)
docker-compose down -v
```

### View Logs
```bash
# View all logs
docker-compose logs -f

# View backend logs only
docker-compose logs -f backend

# View database logs only
docker-compose logs -f db
```

### Execute Commands in Container
```bash
# Access backend shell
docker-compose exec backend bash

# Access PostgreSQL
docker-compose exec db psql -U postgres -d mri_db
```

### Rebuild Containers
```bash
# Rebuild without using cache
docker-compose up --build --force-recreate

# Rebuild specific service
docker-compose build --no-cache backend
```

## Database Management

### Connect to PostgreSQL Directly
```bash
# From host machine
psql -h localhost -U postgres -d mri_db -p 5432

# From within Docker network
docker-compose exec db psql -U postgres -d mri_db
```

### Backup Database
```bash
# Export database dump
docker-compose exec db pg_dump -U postgres -d mri_db > backup.sql

# Restore from backup
docker-compose exec -T db psql -U postgres -d mri_db < backup.sql
```

### Reset Database
```bash
# Remove database volume and restart
docker-compose down -v
docker-compose up
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker-compose logs backend
docker-compose logs db

# Rebuild from scratch
docker-compose down -v
docker-compose up --build
```

### Database Connection Timeout
- Ensure PostgreSQL container is healthy: `docker-compose ps`
- Check if port 5432 is already in use: `netstat -an | findstr :5432` (Windows)
- Wait 10-15 seconds for database to fully initialize

### Port Already in Use
```bash
# Change port in docker-compose.yml
# Or kill process using the port
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :8000
kill -9 <PID>
```

### Permission Denied Errors
- On Linux, you may need to add your user to docker group:
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker
  ```

### Slow Performance
- Check Docker desktop resource allocation
- Ensure sufficient disk space
- Consider using named volumes instead of bind mounts on Windows

## Production Deployment

### Security Checklist
- [ ] Change `POSTGRES_PASSWORD` to a strong password
- [ ] Change `SECRET_KEY` to a randomly generated value
- [ ] Set `DEBUG=False` in environment
- [ ] Configure `CORS_ORIGINS` to specific domains only
- [ ] Use SSL/TLS for database connections
- [ ] Set up proper backup strategy
- [ ] Configure logging and monitoring

### Production docker-compose.yml
```yaml
services:
  db:
    restart: always
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # From secrets
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - mri_network

  backend:
    restart: always
    command: gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
    # Add health checks, resource limits, etc.
```

### Database Backups
```bash
# Automated daily backup
0 2 * * * /usr/local/bin/docker-compose -f /path/to/docker-compose.yml exec -T db pg_dump -U postgres -d mri_db | gzip > /backups/mri_$(date +\%Y\%m\%d).sql.gz
```

## Development Workflow

### Modify Code and Reload
The containers use volumes with hot-reload:
```bash
# Edit your code, backend will reload automatically
# or manually restart the backend service
docker-compose restart backend
```

### Add New Python Dependencies
```bash
# Add to requirements.txt, then rebuild
docker-compose build backend
docker-compose up -d
```

### Database Migrations
If using Alembic:
```bash
docker-compose run --rm backend alembic upgrade head
```

## Network Architecture

```
┌─────────────┐
│   Flutter   │
│    App      │
└──────┬──────┘
       │ HTTP
       ↓
┌─────────────────────┐
│   Docker Network    │
├─────────────────────┤
│  ┌─────────────┐    │
│  │   FastAPI   │    │
│  │   Backend   │    │
│  │  :8000      │    │
│  └──────┬──────┘    │
│         │ TCP       │
│         ↓           │
│  ┌─────────────┐    │
│  │ PostgreSQL  │    │
│  │  :5432      │    │
│  └─────────────┘    │
└─────────────────────┘
```

## Additional Resources
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
