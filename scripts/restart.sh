#!/usr/bin/env bash
# TFGrid ERPNext - Restart Script

echo "🔄 Restarting ERPNext services..."

cd /opt/erpnext/frappe_docker 2>/dev/null || cd /opt/erpnext

echo "Restarting containers..."
docker compose -f pwd.yml restart

echo "Restarting Caddy..."
systemctl restart caddy

echo ""
echo "✅ Services restarted"
echo ""
echo "Check status with: tfgrid-compose healthcheck"
