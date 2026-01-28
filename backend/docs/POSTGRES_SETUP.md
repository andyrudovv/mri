# PostgreSQL Setup Guide

## Installation

### Windows

1. **Download PostgreSQL installer** from https://www.postgresql.org/download/windows/

2. **Run installer and follow wizard:**
   - Accept default installation directory
   - Keep all components selected
   - Set a strong password for `postgres` user (remember this!)
   - Keep default port 5432
   - Complete installation

3. **Verify installation:**
   ```bash
   psql --version
   ```

### macOS (using Homebrew)

```bash
brew install postgresql
brew services start postgresql
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

## Initial Setup

### 1. Connect to PostgreSQL
```bash
psql -U postgres
```
(You'll be prompted for the password you set during installation)

### 2. Create database and user

```sql
-- Create database
CREATE DATABASE mri_db;

-- Create user (optional, for security)
CREATE USER mri_admin WITH ENCRYPTED PASSWORD 'secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mri_db TO mri_admin;

-- Connect to database
\c mri_db

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO mri_admin;

-- Exit
\q
```

### 3. Update .env file

```
DATABASE_URL=postgresql://mri_admin:secure_password@localhost:5432/mri_db
```

## Quick Start for Development

### Using postgres user (simpler for development):

1. **Create database:**
   ```bash
   createdb -U postgres mri_db
   ```

2. **Update .env:**
   ```
   DATABASE_URL=postgresql://postgres:your_password@localhost:5432/mri_db
   ```

3. **Verify connection:**
   ```bash
   psql -U postgres -d mri_db -c "SELECT version();"
   ```

## Common Commands

```bash
# Connect to database
psql -U postgres -d mri_db

# List all databases
\l

# List all tables
\dt

# Describe a table
\d table_name

# Exit psql
\q

# Backup database
pg_dump -U postgres mri_db > backup.sql

# Restore database
psql -U postgres mri_db < backup.sql
```

## Troubleshooting

### "role postgres does not exist"
**Solution:** 
```bash
# Windows CMD
psql -U postgres

# If that fails, use:
psql -U "postgres"
```

### "password authentication failed"
**Solution:** 
- Reset postgres password:
  ```bash
  psql -U postgres
  ALTER USER postgres WITH PASSWORD 'new_password';
  ```

### "could not connect to server"
**Solution:**
- Make sure PostgreSQL service is running:
  ```bash
  # Windows
  net start postgresql-x64-15
  
  # macOS
  brew services start postgresql
  
  # Linux
  sudo systemctl start postgresql
  ```

### "database does not exist"
**Solution:**
```bash
createdb -U postgres mri_db
```

## Useful psql Commands

```sql
-- Check current database
SELECT current_database();

-- Check current user
SELECT current_user;

-- List all users
\du

-- Change password
ALTER USER postgres WITH PASSWORD 'new_password';

-- Drop database
DROP DATABASE mri_db;

-- Check table structure
\d doctors
\d patients
\d mri_analyses
```

## Connection Testing

Test the connection from Python:

```python
import psycopg2

try:
    conn = psycopg2.connect(
        dbname="mri_db",
        user="postgres",
        password="your_password",
        host="localhost",
        port="5432"
    )
    print("Connection successful!")
    conn.close()
except psycopg2.Error as e:
    print(f"Connection failed: {e}")
```

## Running the Application

Once database is set up:

```bash
# Install dependencies
pip install -r requirements.txt

# Update .env with correct DATABASE_URL
# Then start the server
uvicorn main:app --reload
```

Tables will be created automatically on first run!
