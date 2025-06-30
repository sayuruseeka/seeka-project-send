#!/bin/bash

# ProjectSend SSL Setup Script with Certbot
# This script helps you set up SSL certificates using Let's Encrypt Certbot

set -e

echo "🔒 ProjectSend SSL Setup with Certbot"
echo "====================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found."
    echo "   Please copy .env.example to .env and configure your domain settings."
    exit 1
fi

# Source environment variables
source .env

# Check required variables
if [ -z "$DOMAIN_NAME" ] || [ "$DOMAIN_NAME" = "your-domain.com" ]; then
    echo "❌ Error: DOMAIN_NAME not configured in .env file."
    echo "   Please set your actual domain name in the .env file."
    exit 1
fi

if [ -z "$CERTBOT_EMAIL" ] || [ "$CERTBOT_EMAIL" = "your-email@example.com" ]; then
    echo "❌ Error: CERTBOT_EMAIL not configured in .env file."
    echo "   Please set your email address in the .env file."
    exit 1
fi

echo "🌐 Domain: $DOMAIN_NAME"
echo "📧 Email: $CERTBOT_EMAIL"
echo ""

# Create necessary directories
echo "📁 Creating SSL directories..."
mkdir -p certbot/conf certbot/www
mkdir -p config/nginx/site-confs

# Check if ProjectSend is running
if ! docker compose ps | grep -q "projectsend.*Up"; then
    echo "⚠️  ProjectSend is not running. Starting it first..."
    docker compose up -d projectsend mariadb
    echo "⏳ Waiting for ProjectSend to start..."
    sleep 30
fi

# Create nginx configuration for ACME challenge
echo "🔧 Setting up nginx for ACME challenge..."
cat > config/nginx/site-confs/default.conf << 'EOF'
## Version 2024/07/16 - Modified for SSL setup

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    # ACME challenge location for Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;

    include /config/nginx/ssl.conf;

    set $root /app/www/public;
    if (!-d /app/www/public) {
        set $root /config/www;
    }
    root $root;
    index index.html index.htm index.php;

    location / {
        try_files $uri $uri/ /index.html /index.htm /index.php$is_args$args;
    }

    location ~ ^(.+\.php)(.*)$ {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        if (!-f $document_root$fastcgi_script_name) { return 404; }
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }

    # deny access to .htaccess/.htpasswd files
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Restart nginx to apply configuration
echo "🔄 Restarting ProjectSend to apply nginx configuration..."
docker compose restart projectsend

echo "⏳ Waiting for nginx to restart..."
sleep 10

# Test if the domain is accessible
echo "🌐 Testing domain accessibility..."
if ! curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN_NAME" | grep -q "200\|301\|302"; then
    echo "⚠️  Warning: Domain $DOMAIN_NAME may not be accessible."
    echo "   Make sure your domain points to this server's IP address."
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Obtain SSL certificate
echo "🔒 Obtaining SSL certificate from Let's Encrypt..."
docker compose run --rm certbot

# Check if certificate was obtained successfully
if [ -f "certbot/conf/live/$DOMAIN_NAME/fullchain.pem" ]; then
    echo "✅ SSL certificate obtained successfully!"
    
    # Update SSL configuration to use Let's Encrypt certificates
    echo "🔧 Updating SSL configuration..."
    cat > config/nginx/ssl.conf << EOF
## Version 2024/12/06 - Modified for Let's Encrypt
## Mozilla Recommendations with Let's Encrypt certificates

ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;

ssl_dhparam /config/nginx/dhparams.pem;

# intermediate configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;

# HSTS (63072000 seconds = 2 years)
add_header Strict-Transport-Security "max-age=63072000" always;

# Security headers
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "same-origin" always;
EOF

    # Restart ProjectSend to apply SSL configuration
    echo "🔄 Restarting ProjectSend with SSL configuration..."
    docker compose restart projectsend
    
    echo ""
    echo "🎉 SSL setup completed successfully!"
    echo ""
    echo "✅ Your ProjectSend is now accessible at:"
    echo "   🌐 https://$DOMAIN_NAME"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Test your SSL setup: https://www.ssllabs.com/ssltest/"
    echo "   2. Set up automatic certificate renewal (see renewal script)"
    echo "   3. Update your ProjectSend configuration if needed"
    echo ""
    
else
    echo "❌ Failed to obtain SSL certificate."
    echo "   Check the logs: docker compose logs certbot"
    echo "   Common issues:"
    echo "   - Domain not pointing to this server"
    echo "   - Port 80 not accessible from internet"
    echo "   - Firewall blocking connections"
    exit 1
fi
