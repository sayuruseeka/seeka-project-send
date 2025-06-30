# ProjectSend Docker Compose Setup

This repository contains a Docker Compose configuration for running ProjectSend, a self-hosted file sharing application, along with a MariaDB database.

## What is ProjectSend?

ProjectSend is a self-hosted application that lets you upload files and assign them to specific clients that you create yourself. It's secure, private, and easy to use - no more depending on external services or email to send files.

## Features

- Self-hosted file sharing solution
- Client management system
- Secure file uploads and downloads
- User-friendly web interface
- Email notifications
- File expiration dates
- Download statistics

## Prerequisites

- Docker and Docker Compose installed on your system
- At least 1GB of available disk space
- Port 80 available (or modify the port mapping)

## Quick Start

1. Clone or download this repository
2. Navigate to the project directory
3. Start the services:

```bash
docker compose up -d
```

4. Wait for the containers to start (about 30-60 seconds)
5. Open your web browser and navigate to `http://localhost`
6. Follow the ProjectSend setup wizard

## SSL Setup (Production)

For production use with a domain name and SSL certificate:

1. Configure your domain in `.env`:
```bash
cp .env.example .env
# Edit .env and set DOMAIN_NAME and CERTBOT_EMAIL
```

2. Run the SSL setup script:
```bash
./setup-ssl.sh
```

3. Access your secure site at `https://your-domain.com`

For detailed SSL setup instructions, see [SSL-SETUP.md](SSL-SETUP.md).

## Configuration

### Environment Variables

The Docker Compose file includes the following key configurations:

**ProjectSend Container:**
- `PUID=1000` - User ID for file permissions
- `PGID=1000` - Group ID for file permissions  
- `TZ=Etc/UTC` - Timezone setting

**MariaDB Container:**
- `MYSQL_ROOT_PASSWORD=rootpassword123` - Root password for MariaDB
- `MYSQL_DATABASE=projectsend` - Database name for ProjectSend
- `MYSQL_USER=projectsend` - Database user for ProjectSend
- `MYSQL_PASSWORD=projectsendpass123` - Database password for ProjectSend

### Database Connection Settings

When setting up ProjectSend through the web interface, use these database settings:

- **Database Type:** MySQL
- **Database Host:** `mariadb` (container name)
- **Database Name:** `projectsend`
- **Database User:** `projectsend`
- **Database Password:** `projectsendpass123`

### Volumes

The setup creates the following persistent volumes:

- `./config` - ProjectSend configuration files
- `./data` - Files uploaded to ProjectSend
- `./mariadb` - MariaDB database files

## Security Considerations

⚠️ **Important Security Notes:**

1. **Change Default Passwords:** The default database passwords in this setup are for demonstration only. Change them before deploying to production.

2. **Use HTTPS:** For production use, consider setting up a reverse proxy (like Nginx or Traefik) with SSL certificates.

3. **Firewall:** Ensure your firewall is properly configured to only allow necessary access.

4. **Regular Updates:** Keep your Docker images updated regularly.

## Customization

### Changing Ports

To use a different port, modify the ports section in `docker-compose.yml`:

```yaml
ports:
  - "8080:80"  # This would make ProjectSend available on port 8080
```

### PHP Configuration

To customize PHP settings (like max upload size), you can edit the file at:
`./config/php/projectsend.ini` after the first run.

### Scheduled Tasks

To add crontab for scheduled tasks, add them to:
`./config/crontabs/abc` and restart the container.

## Troubleshooting

### Container Won't Start
- Check if ports are already in use: `netstat -tulpn | grep :80`
- Verify Docker and Docker Compose are properly installed
- Check container logs: `docker compose logs projectsend`

### Database Connection Issues
- Ensure the MariaDB container is running: `docker compose ps`
- Check database logs: `docker compose logs mariadb`
- Verify database credentials match between containers

### File Upload Issues
- Check PHP configuration in `./config/php/projectsend.ini`
- Verify disk space is available
- Check file permissions on the `./data` directory

## Useful Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f projectsend
docker compose logs -f mariadb

# Restart services
docker compose restart

# Update images
docker compose pull
docker compose up -d
```

## Backup

To backup your ProjectSend installation:

1. **Database Backup:**
```bash
docker compose exec mariadb mysqldump -u projectsend -p projectsend > backup.sql
```

2. **Files Backup:**
```bash
tar -czf projectsend-backup.tar.gz config/ data/ mariadb/
```

## Support

- [ProjectSend Official Website](http://www.projectsend.org)
- [LinuxServer.io ProjectSend Documentation](https://docs.linuxserver.io/images/docker-projectsend/)
- [ProjectSend GitHub Repository](https://github.com/projectsend/projectsend)

## License

This Docker Compose configuration is provided as-is. ProjectSend itself is licensed under the GPL v2 license.
