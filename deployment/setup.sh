#!/usr/bin/env bash
# TFGrid ERPNext - Setup Script
# Installs Docker, Docker Compose, Caddy, and clones frappe_docker

set -e

echo "🚀 Setting up TFGrid ERPNext..."

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install prerequisites
echo "📦 Installing prerequisites..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    pwgen \
    git

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo "🐳 Installing Docker Compose plugin..."
    apt-get install -y docker-compose-plugin
else
    echo "✅ Docker Compose already installed"
fi

# Install Caddy
if ! command -v caddy &> /dev/null; then
    echo "🌐 Installing Caddy..."
    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt-get update
    apt-get install -y caddy
    systemctl enable caddy
else
    echo "✅ Caddy already installed"
fi

# Create app directories
echo "📁 Creating app directories..."
mkdir -p /opt/erpnext/{scripts,backups,config}
mkdir -p /var/log/erpnext

# Clone frappe_docker
echo "📥 Cloning frappe_docker..."
if [ -d /opt/erpnext/frappe_docker ]; then
    cd /opt/erpnext/frappe_docker
    git pull
else
    git clone https://github.com/frappe/frappe_docker /opt/erpnext/frappe_docker
fi

# Copy scripts from deployment source
echo "📋 Copying scripts..."
cp -r /tmp/app-source/scripts/* /opt/erpnext/scripts/ 2>/dev/null || true
chmod +x /opt/erpnext/scripts/*.sh 2>/dev/null || true

# Load environment variables
if [ -f /tmp/app-source/.env ]; then
    cp /tmp/app-source/.env /opt/erpnext/.env
fi

# Generate passwords if not set
cd /opt/erpnext
if [ -f .env ]; then
    source .env
fi

if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(pwgen -s 32 1)
    echo "DB_PASSWORD=$DB_PASSWORD" >> /opt/erpnext/.env
    echo "🔐 Generated DB_PASSWORD"
fi

if [ -z "$ADMIN_PASSWORD" ]; then
    ADMIN_PASSWORD=$(pwgen -s 16 1)
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> /opt/erpnext/.env
    echo "🔐 Generated ADMIN_PASSWORD"
    echo "📝 Admin password saved to /opt/erpnext/.env"
fi

# Set domain from tfgrid-compose variable or .env
DOMAIN="${TFGRID_DOMAIN:-${DOMAIN:-localhost}}"
SSL_EMAIL="${TFGRID_SSL_EMAIL:-${SSL_EMAIL:-}}"
SITE_NAME="${SITE_NAME:-$DOMAIN}"

# Update .env with final values
grep -q "^DOMAIN=" /opt/erpnext/.env 2>/dev/null && \
    sed -i "s/^DOMAIN=.*/DOMAIN=$DOMAIN/" /opt/erpnext/.env || \
    echo "DOMAIN=$DOMAIN" >> /opt/erpnext/.env

grep -q "^SITE_NAME=" /opt/erpnext/.env 2>/dev/null && \
    sed -i "s/^SITE_NAME=.*/SITE_NAME=$SITE_NAME/" /opt/erpnext/.env || \
    echo "SITE_NAME=$SITE_NAME" >> /opt/erpnext/.env

echo "✅ Setup complete"
echo "📁 App directory: /opt/erpnext"
echo "🌐 Domain: $DOMAIN"
echo "📝 Site name: $SITE_NAME"
