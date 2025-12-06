#!/usr/bin/env bash
# TFGrid ERPNext - Migration Script
# Runs database migrations

set -e

# Load environment
cd /opt/erpnext
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

if [ -z "$SITE_NAME" ]; then
    echo "❌ Error: SITE_NAME not found in .env"
    exit 1
fi

echo "🔄 Running ERPNext migrations..."
echo "   Site: $SITE_NAME"

cd /opt/erpnext/frappe_docker

# Enable maintenance mode
echo "🔧 Enabling maintenance mode..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" set-maintenance-mode on

# Run migrations
echo "💾 Running migrations..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" migrate

# Clear cache
echo "🧹 Clearing cache..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" clear-cache

# Disable maintenance mode
echo "🔧 Disabling maintenance mode..."
docker compose -f pwd.yml exec -T backend bench --site "$SITE_NAME" set-maintenance-mode off

echo ""
echo "✅ Migrations complete!"
