#!/bin/bash
# MRI Analysis Backend Startup Script for Linux/macOS

echo ""
echo "==================================="
echo " MRI Analysis Backend Startup"
echo "==================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Check Python version
python3 --version

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/upgrade dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Warning: .env file not found. Creating from template..."
    cat > .env << EOF
DATABASE_URL=postgresql://postgres:password@localhost:5432/mri_db
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
EOF
    echo ""
    echo "Please edit .env file with your PostgreSQL credentials"
    echo ""
fi

# Start the server
echo "Starting FastAPI server..."
echo ""
echo "API will be available at: http://localhost:8000"
echo "Docs at: http://localhost:8000/docs"
echo ""

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
