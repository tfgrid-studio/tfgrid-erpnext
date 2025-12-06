# TFGrid ERPNext

Open-source ERP system (Frappe/ERPNext) on ThreeFold Grid.

## Overview

Deploy a complete ERPNext installation with:
- **ERPNext** - Full-featured ERP system
- **Frappe Framework** - Python/JS full-stack framework
- **MariaDB** - Database backend
- **Redis** - Caching and queuing
- **Caddy** - Automatic HTTPS with Let's Encrypt

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

```bash
# Deploy with tfgrid-compose
tfgrid-compose up tfgrid-erpnext

# Or manually:
cp .env.example .env
nano .env  # Set your domain

tfgrid-compose up .
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DOMAIN` | Yes | Public domain for ERPNext |
| `SSL_EMAIL` | No | Email for Let's Encrypt |
| `SITE_NAME` | No | ERPNext site name (default: domain) |
| `ADMIN_PASSWORD` | No | Admin password (auto-generated) |
| `DB_PASSWORD` | No | Database password (auto-generated) |
| `ERPNEXT_VERSION` | No | ERPNext version (default: v15) |

### Example .env

```bash
DOMAIN=erp.example.com
SSL_EMAIL=admin@example.com
```

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

## License

Apache 2.0
