#!/bin/bash

# ProjectSend Backup Script

set -e

BACKUP_DIR="backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="projectsend_backup_${TIMESTAMP}"

echo "🔄 Starting ProjectSend backup..."
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if containers are running
if ! docker compose ps | grep -q "Up"; then
    echo "❌ Error: ProjectSend containers are not running."
    echo "   Start them with: docker compose up -d"
    exit 1
fi

echo "📊 Backing up database..."
# Backup database
docker compose exec -T mariadb mysqldump -u projectsend -p"${MYSQL_PASSWORD:-projectsendpass123}" projectsend > "$BACKUP_DIR/${BACKUP_NAME}_database.sql"

echo "📁 Backing up files and configuration..."
# Backup files and configuration
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_files.tar.gz" config/ data/ 2>/dev/null || true

echo "📋 Creating backup info file..."
# Create backup info file
cat > "$BACKUP_DIR/${BACKUP_NAME}_info.txt" << EOF
ProjectSend Backup Information
==============================
Backup Date: $(date)
Backup Name: $BACKUP_NAME

Files Included:
- Database: ${BACKUP_NAME}_database.sql
- Files & Config: ${BACKUP_NAME}_files.tar.gz

Restore Instructions:
1. Stop ProjectSend: docker compose down
2. Restore database: docker compose exec -T mariadb mysql -u projectsend -p projectsend < ${BACKUP_NAME}_database.sql
3. Extract files: tar -xzf ${BACKUP_NAME}_files.tar.gz
4. Start ProjectSend: docker compose up -d

Note: Make sure to use the same database password when restoring.
EOF

echo ""
echo "✅ Backup completed successfully!"
echo ""
echo "📁 Backup files created:"
echo "   - Database: $BACKUP_DIR/${BACKUP_NAME}_database.sql"
echo "   - Files: $BACKUP_DIR/${BACKUP_NAME}_files.tar.gz"
echo "   - Info: $BACKUP_DIR/${BACKUP_NAME}_info.txt"
echo ""
echo "💾 Total backup size:"
du -sh "$BACKUP_DIR/${BACKUP_NAME}"* | awk '{sum+=$1} END {print sum " total"}'

# Clean up old backups (keep last 5)
echo ""
echo "🧹 Cleaning up old backups (keeping last 5)..."
cd "$BACKUP_DIR"
ls -t projectsend_backup_*_database.sql 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
ls -t projectsend_backup_*_files.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
ls -t projectsend_backup_*_info.txt 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
cd ..

echo "✅ Backup process completed!"
