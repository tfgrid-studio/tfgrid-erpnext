#!/usr/bin/env bash
# TFGrid ERPNext - Configure Script
# Starts ERPNext containers and configures Caddy reverse proxy

set -e

echo "⚙️ Configuring TFGrid ERPNext..."

cd /opt/erpnext

# Load environment
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Get configuration values
DOMAIN="${TFGRID_DOMAIN:-${DOMAIN:-localhost}}"
SSL_EMAIL="${TFGRID_SSL_EMAIL:-${SSL_EMAIL:-}}"
SITE_NAME="${SITE_NAME:-$DOMAIN}"
DB_PASSWORD="${DB_PASSWORD}"
ADMIN_PASSWORD="${ADMIN_PASSWORD}"
ERPNEXT_VERSION="${ERPNEXT_VERSION:-v15}"
TIMEZONE="${TIMEZONE:-UTC}"

echo "🌐 Configuring for domain: $DOMAIN"
echo "📝 Site name: $SITE_NAME"

# Create frappe_docker .env file
cd /opt/erpnext/frappe_docker

cat > .env <<EOF
FRAPPE_VERSION=v15
ERPNEXT_VERSION=$ERPNEXT_VERSION
DB_PASSWORD=$DB_PASSWORD
SITE_NAME=$SITE_NAME
ADMIN_PASSWORD=$ADMIN_PASSWORD
LETSENCRYPT_EMAIL=$SSL_EMAIL
EOF

# Use the easy install compose file
echo "🐳 Starting ERPNext containers..."

# Create compose override for production
cat > compose.override.yaml <<EOF
services:
  frontend:
    ports:
      - "8080:8080"
    restart: always
  
  backend:
    restart: always
  
  queue-short:
    restart: always
  
  queue-long:
    restart: always
  
  scheduler:
    restart: always
  
  websocket:
    restart: always
  
  db:
    restart: always
  
  redis-cache:
    restart: always
  
  redis-queue:
    restart: always
EOF

# Start containers using pwd.yml (easy install)
docker compose -f pwd.yml up -d

# Wait for containers to start
echo "⏳ Waiting for containers to start..."
sleep 30

# Wait for site to be created
echo "⏳ Waiting for ERPNext to initialize (this may take several minutes)..."
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker compose -f pwd.yml exec -T backend bench --site $SITE_NAME list-apps 2>/dev/null | grep -q "erpnext"; then
        echo "✅ ERPNext site is ready"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo "⏳ Initializing ERPNext... ($ATTEMPT/$MAX_ATTEMPTS)"
    sleep 10
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "⚠️ ERPNext may still be initializing. Check logs with: tfgrid-compose logs"
fi

# Configure Caddy
echo "🔧 Configuring Caddy reverse proxy..."
if [ "$DOMAIN" = "localhost" ] || [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Local/IP - no SSL
    cat > /etc/caddy/Caddyfile <<EOF
# TFGrid ERPNext - Local/IP Configuration
http://$DOMAIN {
    reverse_proxy localhost:8080
    
    # Security headers
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        Referrer-Policy strict-origin-when-cross-origin
    }
    
    # Logging
    log {
        output file /var/log/caddy/erpnext.log
    }
}
EOF
else
    # Domain - with SSL
    cat > /etc/caddy/Caddyfile <<EOF
# TFGrid ERPNext - Production Configuration
$DOMAIN {
    reverse_proxy localhost:8080
    
    # Security headers
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        Referrer-Policy strict-origin-when-cross-origin
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }
    
    # Logging
    log {
        output file /var/log/caddy/erpnext.log
    }
$([ -n "$SSL_EMAIL" ] && echo "    tls $SSL_EMAIL")
}

# Redirect www to non-www
www.$DOMAIN {
    redir https://$DOMAIN{uri} permanent
}
EOF
fi

# Create Caddy log directory
mkdir -p /var/log/caddy

# Restart Caddy
echo "🔄 Restarting Caddy..."
systemctl restart caddy

# Save configuration info
cat > /opt/erpnext/config/info.json <<EOF
{
    "domain": "$DOMAIN",
    "site_name": "$SITE_NAME",
    "ssl_email": "$SSL_EMAIL",
    "configured_at": "$(date -Iseconds)",
    "erpnext_url": "https://$DOMAIN",
    "admin_user": "Administrator"
}
EOF

# Save admin credentials securely
cat > /opt/erpnext/config/credentials.txt <<EOF
ERPNext Admin Credentials
=========================
URL: https://$DOMAIN
Username: Administrator
Password: $ADMIN_PASSWORD

Keep this file secure!
EOF
chmod 600 /opt/erpnext/config/credentials.txt

echo ""
echo "✅ Configuration complete!"
echo ""
echo "📝 ERPNext Details:"
echo "   URL: https://$DOMAIN"
echo "   Username: Administrator"
echo "   Password: (see /opt/erpnext/config/credentials.txt)"
echo ""
echo "🔧 Management Commands:"
echo "   Logs: tfgrid-compose logs"
echo "   Backup: tfgrid-compose backup"
echo "   Shell: tfgrid-compose shell"
echo "   Bench: tfgrid-compose bench <command>"
