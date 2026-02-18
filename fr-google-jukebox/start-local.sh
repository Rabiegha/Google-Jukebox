#!/bin/bash

# Jukebox Backend - Quick Local Setup & Start Script
# Usage: ./start-local.sh

set -e

echo "🎵 Jukebox Backend - Local Setup & Start"
echo "=========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo "📋 Step 1: Creating .env from .env.example..."
    cp .env.example .env
    echo "✅ .env created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env with your credentials:"
    echo "   nano .env"
    echo ""
    echo "Required fields:"
    echo "  - GCLOUD_PROJECT_ID"
    echo "  - GCLOUD_PROJECT_NUMBER"
    echo "  - GEMINI_API_KEY"
    echo "  - REPLICATE_API_TOKEN"
    echo ""
    read -p "Press enter after editing .env (or Ctrl+C to cancel): "
fi

# Check if .env has required fields
echo "📝 Step 2: Checking .env configuration..."
required_vars=(
    "GCLOUD_PROJECT_ID"
    "GCLOUD_PROJECT_NUMBER"
    "GEMINI_API_KEY"
    "REPLICATE_API_TOKEN"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env || grep "^${var}=\$" .env > /dev/null 2>&1 || grep "^${var}=$" .env > /dev/null 2>&1; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "❌ Missing or empty required variables in .env:"
    printf '   - %s\n' "${missing_vars[@]}"
    echo ""
    echo "Please edit .env and fill in the required values."
    exit 1
fi

echo "✅ .env configuration looks good"
echo ""

# Start Docker Compose
echo "🚀 Step 3: Starting Docker services..."
docker-compose -f docker-compose.local.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check if backend is running
if docker-compose -f docker-compose.local.yml logs backend | grep -q "Uvicorn running"; then
    echo "✅ Backend is running!"
else
    echo "⚠️  Backend may still be starting, checking logs..."
fi

echo ""
echo "=========================================="
echo "✅ Local environment started successfully!"
echo "=========================================="
echo ""
echo "📚 Available Services:"
echo "  Backend API:        http://localhost:8000"
echo "  Swagger Docs:       http://localhost:8000/api/docs"
echo "  ReDoc:              http://localhost:8000/api/redoc"
echo "  Database Admin:     http://localhost:5050"
echo "    • Email:          admin@local.dev"
echo "    • Password:       admin"
echo "  Database:           localhost:5434"
echo "    • User:           postgres"
echo "    • Password:       postgres"
echo "    • Database:       jukebox_db"
echo ""
echo "📖 Useful Commands:"
echo "  View logs:          docker-compose -f docker-compose.local.yml logs -f backend"
echo "  Stop services:      docker-compose -f docker-compose.local.yml down"
echo "  Run shell:          docker-compose -f docker-compose.local.yml exec backend bash"
echo "  Run tests:          make test"
echo "  Format code:        make format"
echo ""
echo "💡 Pro tip: Use 'make dev' to start without this script"
echo ""
