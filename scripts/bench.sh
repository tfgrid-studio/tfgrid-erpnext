#!/usr/bin/env bash
# TFGrid ERPNext - Bench Command Script
# Runs bench commands inside the backend container

if [ $# -eq 0 ]; then
    echo "Usage: bench.sh <command>"
    echo ""
    echo "Examples:"
    echo "  bench.sh --site erp.example.com list-apps"
    echo "  bench.sh --site erp.example.com migrate"
    echo "  bench.sh --site erp.example.com clear-cache"
    echo "  bench.sh --site erp.example.com set-admin-password <password>"
    echo "  bench.sh version"
    exit 1
fi

cd /opt/erpnext/frappe_docker 2>/dev/null || cd /opt/erpnext

# Run bench command
docker compose -f pwd.yml exec -T backend bench "$@"
