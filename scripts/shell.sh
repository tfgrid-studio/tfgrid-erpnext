#!/usr/bin/env bash
# TFGrid ERPNext - Shell Script
# Opens an interactive shell in the backend container

echo "🐚 Opening ERPNext backend shell..."
echo "   Type 'exit' to leave"
echo ""

cd /opt/erpnext/frappe_docker 2>/dev/null || cd /opt/erpnext

docker compose -f pwd.yml exec backend /bin/bash
