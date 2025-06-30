#!/bin/bash

# ProjectSend SSL Certificate Renewal Script
# This script renews Let's Encrypt certificates and reloads nginx

set -e

echo "🔄 Renewing SSL certificates..."

# Check if certbot directory exists
if [ ! -d "certbot/conf" ]; then
    echo "❌ Error: SSL certificates not found. Run setup-ssl.sh first."
    exit 1
fi

# Renew certificates
echo "📋 Checking certificate renewal..."
docker compose run --rm certbot renew

# Check if renewal was successful and restart nginx if needed
if [ $? -eq 0 ]; then
    echo "🔄 Restarting ProjectSend to reload certificates..."
    docker compose restart projectsend
    echo "✅ Certificate renewal completed successfully!"
else
    echo "⚠️  Certificate renewal failed or not needed."
fi

# Show certificate expiration dates
echo ""
echo "📅 Current certificate status:"
docker compose run --rm certbot certificates
