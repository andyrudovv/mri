# 🐳 Docker Quick Reference Visual Guide

## 🚀 Getting Started in 30 Seconds

```
┌─────────────────────────────────────────────────────────┐
│  Step 1: Open Terminal                                  │
│  cd backend                                             │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Step 2: Run Startup Script                             │
│  Windows: start-docker.bat                              │
│  Linux/macOS: bash start-docker.sh                      │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Step 3: Wait 10 Seconds                                │
│  (Services starting up)                                 │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│  Step 4: Open Browser                                   │
│  http://localhost:8000/docs                             │
│  ✅ You're done!                                         │
└─────────────────────────────────────────────────────────┘
```

## 📋 Common Tasks Cheat Sheet

### Start Services
```bash
cd backend

# Windows
start-docker.bat

# Linux/macOS
bash start-docker.sh

# Or all platforms
docker-compose up --build
```

### Stop Services
```bash
docker-compose down          # Stop containers
docker-compose down -v       # Stop and delete data
```

### View Logs
```bash
docker-compose logs          # All logs
docker-compose logs -f       # Follow in real-time
docker-compose logs backend  # Backend only
docker-compose logs db       # Database only
```

### Database Access
```bash
# Interactive shell
docker-compose exec db psql -U postgres -d mri_db

# Single query
docker-compose exec db psql -U postgres -d mri_db -c "SELECT 1;"
```

### Reset Everything
```bash
docker-compose down -v       # Remove everything
docker-compose up --build    # Start fresh
```

## 🎯 Key Ports & URLs

| Service | URL | Port |
|---------|-----|------|
| API Documentation | http://localhost:8000/docs | 8000 |
| API (Alternative) | http://localhost:8000/redoc | 8000 |
| PostgreSQL | localhost:5432 | 5432 |
| FastAPI Backend | http://localhost:8000 | 8000 |

## 🐛 Quick Troubleshooting

```
❌ Services won't start
↓
docker-compose logs
↓
Find error message
↓
docker-compose down -v
docker-compose up --build

❌ Database connection failed
↓
Wait 10-15 seconds for PostgreSQL
↓
docker-compose logs db
↓
Check for initialization messages

❌ Port already in use
↓
Edit docker-compose.yml
↓
Change port: "9000:8000" (use 9000 instead)
↓
docker-compose up --build

❌ Data disappeared
↓
Check if you ran: docker-compose down -v
↓
If so: restore from backup or add data again
↓
(Always backup before running down -v!)
```

## 📊 Container States

```
Starting Up:
┌─────────────────────────┐
│ Checking dependencies   │ (1-2 sec)
├─────────────────────────┤
│ Starting PostgreSQL     │ (3-5 sec)
├─────────────────────────┤
│ Initializing database   │ (5-10 sec)
├─────────────────────────┤
│ Starting FastAPI        │ (2-3 sec)
├─────────────────────────┤
│ Ready! ✅              │
└─────────────────────────┘
Total: ~20 seconds
```

## 🔄 Docker Command Flow

```
                    ┌─────────────────┐
                    │   docker-compose│
                    │      up         │
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                ↓            ↓            ↓
          ┌─────────┐  ┌─────────┐  ┌──────────┐
          │  Build  │  │ Download│  │ Start    │
          │ images  │  │  images │  │containers│
          └────┬────┘  └────┬────┘  └────┬─────┘
               │             │            │
               │             │     ┌──────┴──────┐
               │             │     ↓             ↓
               │             │  ┌────────┐  ┌─────────┐
               │             │  │  db    │  │ backend │
               │             │  │container│ │container│
               │             │  └────────┘  └─────────┘
               │             │     ↓             ↓
               └─────────────┼─────┴─────────────┘
                             │
                      ┌──────┴──────┐
                      │   Ready!    │
                      │  Both up    │
                      └─────────────┘
```

## 📈 Service Health Check

```
PostgreSQL Health:
┌──────────────────────────────────┐
│ ✅ Running      (check port 5432)│
│ ✅ Responsive   (health check ok)│
│ ✅ Database     (mri_db exists)  │
│ ✅ Tables       (auto-created)   │
│ ✅ Data         (persisted)      │
└──────────────────────────────────┘

FastAPI Backend:
┌──────────────────────────────────┐
│ ✅ Running      (check port 8000)│
│ ✅ Responsive   (replies to /docs)
│ ✅ Connected    (to database)    │
│ ✅ Ready        (for requests)   │
└──────────────────────────────────┘
```

## 🎓 Docker Concepts

```
Image
┌─────────────────────────────────┐
│ Blueprint for containers        │
│ - Dockerfile defines it          │
│ - docker-compose.yml uses it    │
│ - Pulled from Docker Hub        │
└─────────────────────────────────┘
         │
         │ (Run)
         ↓
Container
┌─────────────────────────────────┐
│ Running instance of image       │
│ - Has filesystem                │
│ - Has running process           │
│ - Has network access            │
│ - Can be stopped/started        │
└─────────────────────────────────┘
         │
         │ (Multiple)
         ↓
Docker-Compose
┌─────────────────────────────────┐
│ Manages multiple containers     │
│ - Defines services              │
│ - Handles networking            │
│ - Manages volumes               │
│ - Handles startup order         │
└─────────────────────────────────┘
```

## 📚 When to Read What

```
I want to...                → Read this file

Start it now                → This page (Quick Reference)
                            → DOCKER_SETUP.md

Understand what happened    → DOCKER_DEPLOYMENT.md
                            → ARCHITECTURE.md

Learn Docker commands       → DOCKER_COMMANDS.md

Fix a problem              → DOCKER_SETUP.md (Troubleshooting)
                            → DOCKER_COMMANDS.md (Diagnosis)

Deploy to production       → DOCKER_DEPLOYMENT.md
                            → Security Checklist

Integrate everything       → INTEGRATION_GUIDE.md

Get the full picture       → DOCKER_COMPLETE.md
```

## 🔍 Monitor Running Services

### Real-time Monitoring
```bash
# See resource usage
docker stats

# See container info
docker-compose ps

# See network info
docker network ls
docker network inspect mri_network

# See volumes
docker volume ls
docker volume inspect mri_backend_postgres_data
```

### Check Logs in Real-time
```bash
# All services
docker-compose logs -f

# Specific service with timestamps
docker-compose logs -f --timestamps backend

# Last 100 lines
docker-compose logs --tail=100
```

## 💾 Backup & Restore

### Quick Backup
```bash
# Backup now
docker-compose exec db pg_dump -U postgres -d mri_db > backup.sql

# Restore later
docker-compose exec -T db psql -U postgres -d mri_db < backup.sql
```

### Automated Backup (Daily)
```bash
# Save this as backup.sh
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec db pg_dump -U postgres -d mri_db | gzip > backup_$DATE.sql.gz
```

## 🛠️ Maintenance Tasks

### Clean Up Unused Docker Resources
```bash
docker system prune           # Remove unused containers, images, volumes
docker image prune            # Remove unused images
docker volume prune           # Remove unused volumes
docker network prune          # Remove unused networks
```

### Update Images
```bash
docker-compose pull           # Download latest images
docker-compose build --no-cache  # Rebuild without cache
docker-compose up --build     # Rebuild and start
```

### Check Disk Usage
```bash
docker system df              # Show Docker disk usage
docker system df -v           # Verbose disk usage
```

## 📞 Documentation Navigation

```
START HERE
    │
    ├─ DOCKER_SETUP.md (5-minute start)
    │
    ├─ INTEGRATION_GUIDE.md (full system)
    │
    └─ Then choose based on need:
       │
       ├─ DOCKER_COMMANDS.md (learn commands)
       │
       ├─ DOCKER_DEPLOYMENT.md (production)
       │
       └─ DOCKER_COMPLETE.md (final checklist)
```

## ✨ Tips & Tricks

### Tip 1: Keep Logs Handy
```bash
docker-compose logs > debug.log
# Then review debug.log when something goes wrong
```

### Tip 2: Test Database Connection
```bash
docker-compose exec backend python -c "
from sqlalchemy import create_engine
engine = create_engine('postgresql://postgres:password@db:5432/mri_db')
with engine.connect() as conn:
    print('✓ Connected!')
"
```

### Tip 3: Quick Restart
```bash
docker-compose restart       # Restart all
docker-compose restart db    # Restart specific service
```

### Tip 4: Run Commands in Container
```bash
docker-compose exec backend python --version
docker-compose exec backend pip list
docker-compose exec backend ls -la
```

### Tip 5: Execute Scripts
```bash
docker-compose exec -T db psql -U postgres -d mri_db < init.sql
```

## 🎯 Success Indicators

✅ When you see these, you're good!

```
[+] Running 2/2
  ✔ Container mri_postgres_db  Running
  ✔ Container mri_backend      Running

FastAPI Backend:
  INFO:     Uvicorn running on http://0.0.0.0:8000

Database:
  ✓ Database connection successful

API:
  http://localhost:8000/docs  ← Works!
```

## 🎊 You're All Set!

```
Docker Setup: ✅
Backend: ✅
Database: ✅
API: ✅ Ready at http://localhost:8000/docs
Documentation: ✅

Next: Open Flutter app and test!
```

---

## 📞 Quick Links

- **Setup Guide**: Read `DOCKER_SETUP.md`
- **Command Reference**: Read `DOCKER_COMMANDS.md`
- **Full Integration**: Read `INTEGRATION_GUIDE.md`
- **Troubleshooting**: See each guide's troubleshooting section

## 🚀 Remember

- Always backup before running `down -v`
- Wait 10-15 seconds for database on first start
- Check logs with `docker-compose logs` when stuck
- Refer to documentation - it's comprehensive!

**Happy coding!** 🎉
