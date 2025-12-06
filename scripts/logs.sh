#!/usr/bin/env bash
# TFGrid ERPNext - Logs Script

SERVICE="${1:-all}"
FOLLOW=""

# Check for --follow flag
for arg in "$@"; do
    if [ "$arg" = "--follow" ] || [ "$arg" = "-f" ]; then
        FOLLOW="-f"
    fi
done

cd /opt/erpnext/frappe_docker 2>/dev/null || cd /opt/erpnext

case "$SERVICE" in
    frontend|web|nginx)
        echo "📋 Frontend logs:"
        docker compose -f pwd.yml logs $FOLLOW frontend
        ;;
    backend|gunicorn)
        echo "📋 Backend logs:"
        docker compose -f pwd.yml logs $FOLLOW backend
        ;;
    scheduler)
        echo "📋 Scheduler logs:"
        docker compose -f pwd.yml logs $FOLLOW scheduler
        ;;
    worker|queue-short|queue-long)
        echo "📋 Worker logs:"
        docker compose -f pwd.yml logs $FOLLOW queue-short queue-long
        ;;
    db|database|mariadb)
        echo "📋 Database logs:"
        docker compose -f pwd.yml logs $FOLLOW db
        ;;
    redis|cache)
        echo "📋 Redis logs:"
        docker compose -f pwd.yml logs $FOLLOW redis-cache redis-queue
        ;;
    caddy|proxy)
        echo "📋 Caddy logs:"
        if [ -n "$FOLLOW" ]; then
            tail -f /var/log/caddy/erpnext.log
        else
            tail -100 /var/log/caddy/erpnext.log
        fi
        ;;
    all|"")
        echo "📋 All ERPNext logs (last 50 lines each):"
        echo ""
        echo "=== Frontend ==="
        docker compose -f pwd.yml logs --tail 50 frontend 2>&1
        echo ""
        echo "=== Backend ==="
        docker compose -f pwd.yml logs --tail 50 backend 2>&1
        echo ""
        echo "=== Scheduler ==="
        docker compose -f pwd.yml logs --tail 50 scheduler 2>&1
        echo ""
        echo "=== Caddy ==="
        tail -50 /var/log/caddy/erpnext.log 2>/dev/null || echo "No Caddy logs yet"
        ;;
    *)
        echo "Unknown service: $SERVICE"
        echo "Usage: logs.sh [frontend|backend|scheduler|worker|db|redis|caddy|all] [--follow]"
        exit 1
        ;;
esac
