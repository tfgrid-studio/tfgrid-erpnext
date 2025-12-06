#!/usr/bin/env bash
# TFGrid ERPNext - Backup Script
# Creates site backup using bench

set -e

BACKUP_DIR="/opt/erpnext/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SITE_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --site)
            SITE_NAME="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Load environment
cd /opt/erpnext
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Use site from .env if not specified
SITE_NAME="${SITE_NAME:-$SITE_NAME}"

if [ -z "$SITE_NAME" ]; then
    echo "❌ Error: Site name not specified and not found in .env"
    echo "Usage: backup.sh --site <sitename>"
    exit 1
fi

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "📦 Creating ERPNext backup..."
echo "   Site: $SITE_NAME"

cd /opt/erpnext/frappe_docker

# Run bench backup
echo "💾 Running bench backup..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" backup --with-files

# Find the latest backup files
echo "📁 Copying backup files..."
BACKUP_FILES=$(docker compose -f pwd.yml exec -T backend ls -t /home/frappe/frappe-bench/sites/$SITE_NAME/private/backups/ | head -3)

# Create a combined backup archive
TEMP_DIR=$(mktemp -d)

for file in $BACKUP_FILES; do
    docker compose -f pwd.yml cp backend:/home/frappe/frappe-bench/sites/$SITE_NAME/private/backups/$file "$TEMP_DIR/"
done

# Add configuration
cp /opt/erpnext/.env "$TEMP_DIR/env.backup" 2>/dev/null || true

# Create metadata
cat > "$TEMP_DIR/backup_info.json" <<EOF
{
    "created_at": "$(date -Iseconds)",
    "site_name": "$SITE_NAME",
    "hostname": "$(hostname)"
}
EOF

# Create final archive
OUTPUT_FILE="$BACKUP_DIR/erpnext_backup_${SITE_NAME}_$TIMESTAMP.tar.gz"
tar czf "$OUTPUT_FILE" -C "$TEMP_DIR" .

# Cleanup
rm -rf "$TEMP_DIR"

# Show result
FINAL_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo ""
echo "✅ Backup complete!"
echo "   File: $OUTPUT_FILE"
echo "   Size: $FINAL_SIZE"
echo ""
echo "To restore: tfgrid-compose restore --backup $OUTPUT_FILE"
