#!/usr/bin/env bash
# TFGrid ERPNext - Health Check Script

set -e

ERRORS=0

echo "🔍 Running ERPNext health checks..."

# Check Docker is running
if ! systemctl is-active --quiet docker; then
    echo "❌ Docker is not running"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Docker is running"
fi

cd /opt/erpnext/frappe_docker 2>/dev/null || cd /opt/erpnext

# Check frontend container
if docker compose -f pwd.yml ps --format '{{.Name}}' 2>/dev/null | grep -q "frontend"; then
    FRONTEND_STATUS=$(docker compose -f pwd.yml ps frontend --format '{{.Status}}' 2>/dev/null | head -1)
    if echo "$FRONTEND_STATUS" | grep -qi "up"; then
        echo "✅ Frontend container is running"
    else
        echo "❌ Frontend container status: $FRONTEND_STATUS"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Frontend container not found"
    ERRORS=$((ERRORS + 1))
fi

# Check backend container
if docker compose -f pwd.yml ps --format '{{.Name}}' 2>/dev/null | grep -q "backend"; then
    BACKEND_STATUS=$(docker compose -f pwd.yml ps backend --format '{{.Status}}' 2>/dev/null | head -1)
    if echo "$BACKEND_STATUS" | grep -qi "up"; then
        echo "✅ Backend container is running"
    else
        echo "❌ Backend container status: $BACKEND_STATUS"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Backend container not found"
    ERRORS=$((ERRORS + 1))
fi

# Check database container
if docker compose -f pwd.yml ps --format '{{.Name}}' 2>/dev/null | grep -q "db"; then
    DB_STATUS=$(docker compose -f pwd.yml ps db --format '{{.Status}}' 2>/dev/null | head -1)
    if echo "$DB_STATUS" | grep -qi "up"; then
        echo "✅ Database container is running"
    else
        echo "❌ Database container status: $DB_STATUS"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Database container not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Redis containers
for redis in redis-cache redis-queue; do
    if docker compose -f pwd.yml ps --format '{{.Name}}' 2>/dev/null | grep -q "$redis"; then
        echo "✅ $redis container is running"
    else
        echo "⚠️ $redis container not found"
    fi
done

# Check Caddy is running
if systemctl is-active --quiet caddy; then
    echo "✅ Caddy is running"
else
    echo "❌ Caddy is not running"
    ERRORS=$((ERRORS + 1))
fi

# Check ERPNext HTTP response
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
    echo "✅ ERPNext HTTP check passed (status: $HTTP_CODE)"
else
    echo "❌ ERPNext HTTP check failed (status: $HTTP_CODE)"
    ERRORS=$((ERRORS + 1))
fi

# Check disk space
DISK_USAGE=$(df /opt/erpnext 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -lt 90 ]; then
    echo "✅ Disk usage: ${DISK_USAGE}%"
else
    echo "⚠️ Disk usage is high: ${DISK_USAGE}%"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All health checks passed"
    exit 0
else
    echo "❌ $ERRORS health check(s) failed"
    exit 1
fi
