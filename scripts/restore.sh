#!/usr/bin/env bash
# TFGrid ERPNext - Restore Script
# Restores ERPNext site from backup

set -e

BACKUP_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup)
            BACKUP_FILE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Error: No backup file specified"
    echo "Usage: restore.sh --backup /path/to/backup.tar.gz"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️ WARNING: This will overwrite your current ERPNext data!"
echo "   Backup file: $BACKUP_FILE"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Load environment
cd /opt/erpnext
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

TEMP_DIR=$(mktemp -d)

echo "📦 Extracting backup..."
tar xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Read backup info
if [ -f "$TEMP_DIR/backup_info.json" ]; then
    BACKUP_SITE=$(jq -r '.site_name' "$TEMP_DIR/backup_info.json")
    echo "   Backup site: $BACKUP_SITE"
fi

cd /opt/erpnext/frappe_docker

# Find backup files
DB_BACKUP=$(ls "$TEMP_DIR"/*-database.sql.gz 2>/dev/null | head -1)
FILES_BACKUP=$(ls "$TEMP_DIR"/*-files.tar 2>/dev/null | head -1)
PRIVATE_BACKUP=$(ls "$TEMP_DIR"/*-private-files.tar 2>/dev/null | head -1)

if [ -z "$DB_BACKUP" ]; then
    echo "❌ Error: Database backup not found in archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "💾 Restoring database..."
# Copy backup to container
docker compose -f pwd.yml cp "$DB_BACKUP" backend:/tmp/database.sql.gz

# Restore database
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" restore /tmp/database.sql.gz

# Restore files if present
if [ -n "$FILES_BACKUP" ]; then
    echo "📁 Restoring public files..."
    docker compose -f pwd.yml cp "$FILES_BACKUP" backend:/tmp/files.tar
    docker compose -f pwd.yml exec -T backend tar xf /tmp/files.tar -C /home/frappe/frappe-bench/sites/$SITE_NAME/public/
fi

if [ -n "$PRIVATE_BACKUP" ]; then
    echo "📁 Restoring private files..."
    docker compose -f pwd.yml cp "$PRIVATE_BACKUP" backend:/tmp/private-files.tar
    docker compose -f pwd.yml exec -T backend tar xf /tmp/private-files.tar -C /home/frappe/frappe-bench/sites/$SITE_NAME/private/
fi

# Run migrations
echo "🔄 Running migrations..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" migrate

# Clear cache
echo "🧹 Clearing cache..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" clear-cache

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Restore complete!"
echo ""
echo "Please verify your site is working correctly."
