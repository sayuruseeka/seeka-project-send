#!/bin/bash

# ProjectSend Docker Compose Startup Script

set -e

echo "🚀 Starting ProjectSend with Docker Compose..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Error: docker compose is not available. Please install Docker Compose and try again."
    exit 1
fi

# Check if .env file exists, if not copy from example
if [ ! -f .env ]; then
    echo "📝 No .env file found. Creating one from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Created .env file. Please review and modify the passwords before continuing."
        echo ""
        echo "⚠️  IMPORTANT: Edit the .env file to change the default passwords!"
        echo "   Default passwords are not secure for production use."
        echo ""
        read -p "Press Enter to continue after reviewing the .env file, or Ctrl+C to exit..."
    else
        echo "❌ Error: .env.example file not found."
        exit 1
    fi
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p config data mysql

# Set proper permissions (if running as root, this helps with permission issues)
if [ "$EUID" -eq 0 ]; then
    echo "🔧 Setting directory permissions..."
    chown -R 1000:1000 config data mysql
fi

# Pull the latest images
echo "📥 Pulling latest Docker images..."
docker compose pull

# Start the services
echo "🐳 Starting ProjectSend services..."
docker compose up -d

# Wait a moment for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
if docker compose ps | grep -q "Up"; then
    echo ""
    echo "✅ ProjectSend is starting up!"
    echo ""
    echo "🌐 Access ProjectSend at: http://localhost"
    echo ""
    echo "📊 Database connection settings for setup:"
    echo "   Database Type: MySQL"
    echo "   Database Host: mysql"
    echo "   Database Name: projectsend"
    echo "   Database User: projectsend"
    echo "   Database Password: (check your .env file)"
    echo ""
    echo "📋 Useful commands:"
    echo "   View logs: docker compose logs -f"
    echo "   Stop services: docker compose down"
    echo "   Restart services: docker compose restart"
    echo ""
    echo "⚠️  Note: It may take a few minutes for ProjectSend to be fully ready."
    echo "   If you see a 502 error, wait a moment and refresh the page."
else
    echo ""
    echo "❌ Error: Services failed to start properly."
    echo "   Check the logs with: docker compose logs"
    exit 1
fi
