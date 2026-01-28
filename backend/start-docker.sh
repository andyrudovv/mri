#!/bin/bash
# Docker startup script for MRI Analysis Backend

echo "🚀 Starting MRI Analysis Backend with Docker..."
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Desktop first."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "✓ Created .env file. Please update it with your settings."
fi

# Pull latest images
echo "📦 Pulling latest Docker images..."
docker-compose pull

# Build images
echo "🔨 Building Docker images..."
docker-compose build

# Start services
echo "▶️  Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✅ Services started successfully!"
    echo ""
    echo "📊 Service Status:"
    docker-compose ps
    echo ""
    echo "🌐 API Documentation: http://localhost:8000/docs"
    echo "📊 Alternative Docs: http://localhost:8000/redoc"
    echo ""
    echo "📝 Database:"
    echo "   Host: localhost"
    echo "   Port: 5432"
    echo "   User: postgres"
    echo "   Database: mri_db"
    echo ""
    echo "💡 View logs with: docker-compose logs -f"
    echo "🛑 Stop services with: docker-compose down"
else
    echo "❌ Failed to start services. Check logs with: docker-compose logs"
    exit 1
fi
