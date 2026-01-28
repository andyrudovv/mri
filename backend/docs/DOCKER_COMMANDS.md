# Docker Commands Cheat Sheet

## Basic Commands

### Start Services
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Start with fresh build
docker-compose up --build

# Force recreate containers
docker-compose up --force-recreate
```

### Stop Services
```bash
# Stop all containers
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v
```

### View Status
```bash
# List running containers
docker-compose ps

# List all containers (including stopped)
docker-compose ps -a

# View container logs
docker-compose logs

# View specific service logs
docker-compose logs backend
docker-compose logs db

# Follow logs in real-time
docker-compose logs -f
docker-compose logs -f backend

# Show last 100 lines
docker-compose logs --tail=100
```

## Container Interaction

### Execute Commands
```bash
# Run bash in backend container
docker-compose exec backend bash

# Run Python command
docker-compose exec backend python -c "import sys; print(sys.version)"

# Access PostgreSQL
docker-compose exec db psql -U postgres -d mri_db

# Run without allocating pseudo-TTY (for scripts)
docker-compose exec -T db pg_dump -U postgres -d mri_db
```

### View Container Details
```bash
# Inspect service
docker-compose exec backend env

# Check disk usage
docker-compose exec backend du -sh /app

# List installed Python packages
docker-compose exec backend pip list
```

## Database Commands

### PostgreSQL Access
```bash
# Connect to database
docker-compose exec db psql -U postgres -d mri_db

# List databases
docker-compose exec db psql -U postgres -l

# List tables
docker-compose exec db psql -U postgres -d mri_db -c "\dt"

# Run SQL query
docker-compose exec db psql -U postgres -d mri_db -c "SELECT * FROM users;"
```

### Backup & Restore
```bash
# Backup database
docker-compose exec db pg_dump -U postgres -d mri_db > backup.sql

# Backup with compression
docker-compose exec db pg_dump -U postgres -d mri_db | gzip > backup.sql.gz

# Restore from backup
docker-compose exec -T db psql -U postgres -d mri_db < backup.sql

# Restore from compressed backup
gunzip -c backup.sql.gz | docker-compose exec -T db psql -U postgres -d mri_db
```

### Reset Database
```bash
# Delete all data (keep structure)
docker-compose exec db psql -U postgres -d mri_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# Delete everything including volumes
docker-compose down -v
docker-compose up
```

## Build & Rebuild

### Build Images
```bash
# Build all services
docker-compose build

# Build specific service
docker-compose build backend
docker-compose build db

# Build without cache
docker-compose build --no-cache

# Build specific service without cache
docker-compose build --no-cache backend
```

### View Images
```bash
# List images
docker images

# Remove image
docker rmi image_name

# Remove unused images
docker image prune
```

## Volume Management

### Inspect Volumes
```bash
# List all volumes
docker volume ls

# Inspect volume
docker volume inspect mri_backend_postgres_data

# Remove unused volumes
docker volume prune

# Remove specific volume
docker volume rm mri_backend_postgres_data
```

## Network Management

### Network Inspection
```bash
# List networks
docker network ls

# Inspect network
docker network inspect mri_network

# Test container connectivity
docker-compose exec backend ping db
docker-compose exec backend curl -I http://db:5432
```

## Troubleshooting Commands

### Container Health Check
```bash
# Check if container is running
docker-compose ps

# View container stats
docker stats

# View container resource usage
docker stats --no-stream
```

### Debug Logs
```bash
# View system logs
docker-compose logs -f

# View backend with timestamps
docker-compose logs -f --timestamps backend

# View recent logs (last 1000 lines)
docker-compose logs --tail=1000

# Save logs to file
docker-compose logs > docker_logs.txt 2>&1
```

### Verify Database Connectivity
```bash
# From backend container
docker-compose exec backend python -c "
from sqlalchemy import create_engine
engine = create_engine('postgresql://postgres:password@db:5432/mri_db')
with engine.connect() as conn:
    result = conn.execute('SELECT 1')
    print('Connected:', result.fetchone())
"
```

### Check Network
```bash
# Ping database from backend
docker-compose exec backend ping db

# Check database port
docker-compose exec backend nc -zv db 5432

# List network interfaces
docker-compose exec backend ip addr show
```

## Cleanup Commands

### Remove Everything
```bash
# Stop and remove containers, networks, volumes
docker-compose down -v

# Remove all unused Docker resources
docker system prune

# Remove all unused resources including volumes
docker system prune -a --volumes
```

### Selective Cleanup
```bash
# Remove only stopped containers
docker container prune

# Remove only dangling images
docker image prune

# Remove only unused volumes
docker volume prune

# Remove only unused networks
docker network prune
```

## Performance & Monitoring

### Resource Monitoring
```bash
# Real-time resource usage
docker stats

# CPU and memory for specific container
docker stats mri_backend

# View processes in container
docker top mri_backend

# View resource limits
docker inspect mri_backend | grep -A 20 '"MemorySwap"'
```

### Container Inspection
```bash
# View full container configuration
docker inspect mri_backend

# View environment variables
docker inspect mri_backend | grep -A 20 Env

# View port mappings
docker inspect mri_backend | grep -A 5 '"Ports"'

# View volume mounts
docker inspect mri_backend | grep -A 10 '"Mounts"'
```

## Advanced Commands

### Custom Docker Run
```bash
# Run one-off command
docker-compose run --rm backend python script.py

# Run with different entrypoint
docker-compose exec backend /bin/bash

# Run with specific environment variable
docker-compose exec -e DEBUG=True backend python -c "import os; print(os.getenv('DEBUG'))"
```

### Service Management
```bash
# Restart specific service
docker-compose restart backend

# Pause services
docker-compose pause

# Unpause services
docker-compose unpause

# Scale service (if not limited)
docker-compose up -d --scale backend=2
```

## Tips & Best Practices

1. **Always use `-d` flag for background running**: `docker-compose up -d`
2. **Check logs before asking for help**: `docker-compose logs`
3. **Rebuild when changing Dockerfile**: `docker-compose up --build`
4. **Use `-v` flag to clean volumes**: `docker-compose down -v`
5. **Save important data before volume cleanup**: Always backup first!
6. **Use meaningful container names**: Already configured in docker-compose.yml
7. **Monitor resource usage**: Run `docker stats` regularly
8. **Keep images updated**: `docker pull postgres:16-alpine`
