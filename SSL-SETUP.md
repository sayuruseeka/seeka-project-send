# SSL Setup Guide for ProjectSend

This guide explains how to set up SSL/TLS certificates for your ProjectSend installation using Let's Encrypt and Certbot.

## Prerequisites

1. **Domain Name**: You need a domain name pointing to your server's public IP
2. **Port Access**: Ports 80 and 443 must be accessible from the internet
3. **ProjectSend Running**: Your ProjectSend instance should be running

## Quick SSL Setup

### 1. Configure Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` and set:
```bash
DOMAIN_NAME=your-domain.com
CERTBOT_EMAIL=your-email@example.com
```

### 2. Run SSL Setup Script

```bash
./setup-ssl.sh
```

This script will:
- Configure nginx for ACME challenge
- Obtain SSL certificate from Let's Encrypt
- Update SSL configuration
- Restart services with SSL enabled

### 3. Access Your Site

After successful setup, access your ProjectSend at:
- **HTTPS**: `https://your-domain.com` (secure)
- **HTTP**: `http://your-domain.com` (redirects to HTTPS)

## Manual SSL Setup

If you prefer manual setup or need to troubleshoot:

### Step 1: Update Docker Compose

The `docker-compose.yml` already includes:
- Port 443 mapping for HTTPS
- Certbot service configuration
- Volume mounts for certificates

### Step 2: Configure nginx for ACME Challenge

Create/update `config/nginx/site-confs/default.conf`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name your-domain.com;
    
    # ACME challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    server_name your-domain.com;
    
    include /config/nginx/ssl.conf;
    
    # ProjectSend configuration
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
    
    location ~ /\.ht {
        deny all;
    }
}
```

### Step 3: Obtain Certificate

```bash
# Create directories
mkdir -p certbot/conf certbot/www

# Start services
docker compose up -d

# Obtain certificate
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d your-domain.com
```

### Step 4: Update SSL Configuration

Update `config/nginx/ssl.conf`:

```nginx
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;

ssl_dhparam /config/nginx/dhparams.pem;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;

# HSTS
add_header Strict-Transport-Security "max-age=63072000" always;

# Security headers
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "same-origin" always;
```

### Step 5: Restart Services

```bash
docker compose restart projectsend
```

## Certificate Renewal

### Automatic Renewal

Set up a cron job for automatic renewal:

```bash
# Edit crontab
crontab -e

# Add this line to check for renewal twice daily
0 12,0 * * * /path/to/your/project/renew-ssl.sh >> /var/log/certbot-renewal.log 2>&1
```

### Manual Renewal

```bash
./renew-ssl.sh
```

Or manually:

```bash
docker compose run --rm certbot renew
docker compose restart projectsend
```

## Troubleshooting

### Common Issues

1. **Domain not accessible**
   - Ensure your domain points to the server's public IP
   - Check DNS propagation: `nslookup your-domain.com`

2. **Port 80/443 blocked**
   - Check firewall settings
   - Ensure ports are open: `netstat -tulpn | grep :80`

3. **Certificate validation failed**
   - Verify domain ownership
   - Check ACME challenge accessibility: `curl http://your-domain.com/.well-known/acme-challenge/test`

4. **nginx configuration errors**
   - Test configuration: `docker compose exec projectsend nginx -t`
   - Check logs: `docker compose logs projectsend`

### Useful Commands

```bash
# Check certificate status
docker compose run --rm certbot certificates

# Test certificate renewal
docker compose run --rm certbot renew --dry-run

# View nginx logs
docker compose logs projectsend

# Test SSL configuration
curl -I https://your-domain.com
```

## Security Considerations

1. **Keep certificates updated**: Set up automatic renewal
2. **Use strong ciphers**: The configuration uses Mozilla's intermediate profile
3. **Enable HSTS**: Included in the SSL configuration
4. **Regular security headers**: Added to prevent common attacks
5. **Monitor expiration**: Set up alerts for certificate expiration

## Testing Your SSL Setup

1. **SSL Labs Test**: https://www.ssllabs.com/ssltest/
2. **Certificate transparency**: https://crt.sh/
3. **Security headers**: https://securityheaders.com/

Your SSL setup should achieve an A+ rating on SSL Labs with proper configuration.
