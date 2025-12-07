# TFGrid ERPNext

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/tfgrid-studio/tfgrid-erpnext)](https://github.com/tfgrid-studio/tfgrid-erpnext/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/tfgrid-studio/tfgrid-erpnext)](https://github.com/tfgrid-studio/tfgrid-erpnext/issues)

Open-source ERP system (Frappe/ERPNext) on ThreeFold Grid.

## Overview

Deploy a complete ERPNext installation with:
- **ERPNext** - Full-featured ERP system
- **Frappe Framework** - Python/JS full-stack framework
- **MariaDB** - Database backend
- **Redis** - Caching and queuing
- **Caddy** - Automatic HTTPS with Let's Encrypt
- **Automatic DNS** - Optional DNS A record creation (Name.com, Namecheap, Cloudflare)

## Features

- 📊 **Accounting** - Complete financial management
- 📦 **Inventory** - Stock management and tracking
- 🛒 **Sales & Purchase** - Order management
- 🏭 **Manufacturing** - Production planning
- 👥 **HR & Payroll** - Employee management
- 📋 **Projects** - Task and project tracking
- 🛠️ **Asset Management** - Track company assets
- 📈 **CRM** - Customer relationship management

## Quick Start

### Basic Deployment (Interactive)

The easiest way to deploy - answers questions interactively:

```bash
tfgrid-compose up tfgrid-erpnext -i
```

This will prompt you for:
1. Domain name
2. DNS provider (optional automatic setup)
3. Company information
4. Admin credentials
5. Resource allocation
6. Node selection

### One-Line Deployment

Deploy with all settings on the command line:

```bash
tfgrid-compose up tfgrid-erpnext \
  --env DOMAIN=erp.example.com \
  --env SSL_EMAIL=admin@example.com \
  --env COMPANY_NAME="My Company" \
  --env COUNTRY="United States" \
  --env CURRENCY=USD
```

### Full Deployment Example

Complete deployment with DNS automation and all options:

```bash
# With Name.com DNS (recommended - fully automated)
tfgrid-compose up tfgrid-erpnext \
  --env DOMAIN=erp.example.com \
  --env DNS_PROVIDER=name.com \
  --env NAMECOM_USERNAME=myuser \
  --env NAMECOM_API_TOKEN=your-token \
  --env COMPANY_NAME="My Business"

# With Cloudflare DNS and company setup (recommended - fully automated)
tfgrid-compose up tfgrid-erpnext \
  --env DOMAIN=erp.example.com \
  --env SSL_EMAIL=admin@example.com \
  --env DNS_PROVIDER=cloudflare \
  --env CLOUDFLARE_API_TOKEN=your-cf-token \
  --env COMPANY_NAME="Acme Corporation" \
  --env COMPANY_ABBR=ACME \
  --env COUNTRY="United States" \
  --env CURRENCY=USD \
  --env TIMEZONE=America/New_York \
  --env WORKER_COUNT=4 \
  --env GUNICORN_WORKERS=8 \
  --cpu 4 \
  --memory 8192 \
  --disk 200

# With GoDaddy DNS (recommended - fully automated)
tfgrid-compose up tfgrid-erpnext \
  --env DOMAIN=erp.example.com \
  --env DNS_PROVIDER=godaddy \
  --env GODADDY_API_KEY=your-api-key \
  --env GODADDY_API_SECRET=your-api-secret \
  --env COMPANY_NAME="My Business"
```

## Configuration

### Environment Variables

#### Domain & DNS

> **Recommended:** Use `name.com`, `cloudflare`, or `godaddy` for fully automated DNS setup. Namecheap requires manual IP whitelisting in their dashboard before API calls work.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DOMAIN` | **Yes** | - | Public domain for ERPNext |
| `SSL_EMAIL` | No | - | Email for Let's Encrypt |
| `DNS_PROVIDER` | No | `manual` | DNS provider: `manual`, `name.com`, `cloudflare`, `godaddy`, `namecheap` |
| `NAMECOM_USERNAME` | If name.com | - | Name.com username |
| `NAMECOM_API_TOKEN` | If name.com | - | Name.com API token |
| `CLOUDFLARE_API_TOKEN` | If cloudflare | - | Cloudflare API token |
| `GODADDY_API_KEY` | If godaddy | - | GoDaddy API key |
| `GODADDY_API_SECRET` | If godaddy | - | GoDaddy API secret |
| `NAMECHEAP_API_USER` | If namecheap | - | Namecheap API username (requires IP whitelisting) |
| `NAMECHEAP_API_KEY` | If namecheap | - | Namecheap API key (requires IP whitelisting) |

#### ERPNext Settings

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SITE_NAME` | No | from domain | ERPNext site name |
| `ADMIN_PASSWORD` | No | auto-generated | Admin password |
| `ERPNEXT_VERSION` | No | `latest` | ERPNext version |

#### Company Setup

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `COMPANY_NAME` | No | - | Company name for initial setup |
| `COMPANY_ABBR` | No | - | Company abbreviation |
| `COUNTRY` | No | `United States` | Country for localization |
| `CURRENCY` | No | `USD` | Default currency |
| `TIMEZONE` | No | `America/New_York` | Server timezone |

#### Database

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_PASSWORD` | No | auto-generated | MariaDB password |
| `DB_ROOT_PASSWORD` | No | auto-generated | MariaDB root password |

#### Performance

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `WORKER_COUNT` | No | `2` | Number of background workers |
| `GUNICORN_WORKERS` | No | `4` | Number of Gunicorn workers |

#### Backup

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `BACKUP_RETENTION_DAYS` | No | `30` | Days to keep backups |

## Commands

| Command | Description |
|---------|-------------|
| `tfgrid-compose backup` | Create site backup |
| `tfgrid-compose restore --backup <file>` | Restore from backup |
| `tfgrid-compose list-backups` | List available backups |
| `tfgrid-compose logs [service]` | View logs |
| `tfgrid-compose shell` | Open backend shell |
| `tfgrid-compose bench <cmd>` | Run bench commands |
| `tfgrid-compose migrate` | Run database migrations |
| `tfgrid-compose restart` | Restart services |

## Resource Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| Memory | 4 GB | 8 GB |
| Disk | 50 GB | 100 GB |

## Architecture

```
┌─────────────┐     ┌───────────────┐     ┌──────────────┐
│   Internet  │────▶│  Caddy :443   │────▶│  Frontend    │
│             │     │  (auto-SSL)   │     │  (nginx)     │
└─────────────┘     └───────────────┘     └──────┬───────┘
                                                 │
                    ┌────────────────────────────┼────────────────────────────┐
                    │                            │                            │
              ┌─────▼─────┐              ┌───────▼───────┐            ┌───────▼───────┐
              │  Backend  │              │   Scheduler   │            │    Workers    │
              │ (gunicorn)│              │               │            │ (queue-short) │
              └─────┬─────┘              └───────────────┘            │ (queue-long)  │
                    │                                                 └───────────────┘
          ┌─────────┼─────────┐
          │         │         │
    ┌─────▼───┐ ┌───▼───┐ ┌───▼───┐
    │ MariaDB │ │ Redis │ │ Redis │
    │   DB    │ │ Cache │ │ Queue │
    └─────────┘ └───────┘ └───────┘
```

## Default Credentials

After deployment, find credentials in:
```
/opt/erpnext/config/credentials.txt
```

Default username: `Administrator`

## Backup & Restore

### Create Backup
```bash
tfgrid-compose backup
# Output: /opt/erpnext/backups/erpnext_backup_<site>_YYYYMMDD_HHMMSS.tar.gz
```

### Restore from Backup
```bash
tfgrid-compose restore --backup /path/to/backup.tar.gz
```

### Backup Contents
- Database dump (SQL)
- Public files (attachments, images)
- Private files (backups, reports)
- Configuration

## Bench Commands

Run Frappe bench commands:
```bash
# List installed apps
tfgrid-compose bench --site erp.example.com list-apps

# Clear cache
tfgrid-compose bench --site erp.example.com clear-cache

# Reset admin password
tfgrid-compose bench --site erp.example.com set-admin-password newpassword

# Install an app
tfgrid-compose bench --site erp.example.com install-app hrms
```

## Troubleshooting

### Check Service Status
```bash
tfgrid-compose healthcheck
```

### View Logs
```bash
tfgrid-compose logs                # All logs
tfgrid-compose logs backend        # Backend logs
tfgrid-compose logs scheduler      # Scheduler logs
tfgrid-compose logs db             # Database logs
```

### Common Issues

**"Site not found" error**
- Wait for initialization to complete (can take 5-10 minutes)
- Check backend logs: `tfgrid-compose logs backend`

**Slow performance**
- Ensure adequate memory (4GB minimum)
- Check Redis is running: `tfgrid-compose logs redis`

**Database connection errors**
- Check MariaDB is running: `tfgrid-compose logs db`
- Verify credentials in `.env`

## Updating ERPNext

```bash
# Pull latest images
cd /opt/erpnext/frappe_docker
docker compose -f pwd.yml pull

# Restart with new images
docker compose -f pwd.yml up -d

# Run migrations
tfgrid-compose migrate
```

## Support

- **📚 Documentation:** [docs.tfgrid.studio](https://docs.tfgrid.studio)
- **🐛 Issues:** [GitHub Issues](https://github.com/tfgrid-studio/tfgrid-erpnext/issues)
- **💬 Discussions:** [GitHub Discussions](https://github.com/orgs/tfgrid-studio/discussions)
- **📧 Contact:** [tfgrid.studio/contact](https://tfgrid.studio/contact)

## License

Apache 2.0
