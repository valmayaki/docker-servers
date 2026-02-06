# Docker Servers Development Setup

## Overview
This repository provides a comprehensive Docker Compose setup for development and production environments with services organized by profile. Developers can selectively start services based on their needs.

## Quick Start

### Option 1: Start Everything
```bash
# Start all services with default profiles
docker-compose --profile databases --profile development --profile automation --profile ai --profile finance --proxy up -d
```

### Option 2: Start Specific Categories
```bash
# Databases only
docker-compose --profile databases up -d

# Development tools
docker-compose --profile development up -d

# AI/ML services
docker-compose --profile ai up -d

# Automation tools
docker-compose --profile automation up -d

# Finance management
docker-compose --profile finance up -d
```

### Option 3: Proxy Selection with Port Management

**🌟 NEW: Smart Port Management System**
The repository now includes an intelligent port management system that allows any proxy to use the standard ports 80/443 automatically.

#### Automatic Port Management
```bash
# Start port manager + proxy of choice
./start.sh proxy-manager          # Manages ports 80/443 automatically
./start.sh proxy-manager caddy     # Start Caddy with port 80/443
./start.sh proxy-manager nginx     # Start Nginx with port 80/443
./start.sh proxy-manager manager     # Start Proxy Manager with port 80/443
./start.sh proxy-manager traefik     # Start Traefik with port 80/443
```

#### Manual Port Assignment (Alternative Ports)
If you prefer not to use the port manager, you can still use alternative ports:

```bash
# Direct access (uses alternative ports)
./start.sh proxy caddy-direct        # Caddy on ports 8080/8443
./start.sh proxy nginx-direct        # Nginx on ports 8081/8445
./start.sh proxy manager-direct        # Manager on ports 8082/8446
./start.sh proxy traefik-direct        # Traefik on ports 8085/8447
```

#### How Port Management Works:
1. **Port Manager Service**: Runs automatically to detect and manage port conflicts
2. **Priority System**: First proxy started gets ports 80/443
3. **Direct Access Mode**: When port-manager is active, proxies can use 80/443 via special `-direct` profiles
4. **Seamless Switching**: Stop/start proxies automatically without manual intervention

#### Proxy Options:
| Proxy | Standard Ports | Alt Ports | Direct Mode | Manager Required |
|--------|----------------|------------|-------------|----------------|
| Caddy | 80, 443 | 8080, 8443 | caddy-direct | Yes |
| Nginx | 80, 443 | 8081, 8445 | nginx-direct | Yes |
| Manager | 80, 443 | 8082, 8446 | manager-direct | Yes |
| Traefik | 80, 443 | 8085, 8447 | traefik-direct | Yes |

## Service Breakdown

### Database Services (`--profile databases`)
- **MySQL**: Port 33069 (Standard)
- **MySQL 8**: Port 33068 (Latest)
- **PostgreSQL**: Port 54320 (Primary)
- **PostgreSQL + pgvector**: Port 54321 (AI/Vector)
- **pgAdmin**: Port 5011 (Database GUI)

### Development Services (`--profile development`)
- **Node.js**: Port 3000
- **Image Registry**: Port 5200
- **pgAdmin**: Port 5011 (Also available with databases)

### AI/ML Services (`--profile ai`)
- **Ollama**: Port 11434 (LLM Engine)
- **Open WebUI**: Port 8090 (Chat Interface)
- **pgvector**: Included for vector storage

### Automation Services (`--profile automation`)
- **n8n**: Port 5678 (Workflow Automation) - Custom build with Playwright & Puppeteer
- **Redis**: Port 6379 (Cache)
- **RabbitMQ**: Ports 5672, 15672 (Queue)

### Finance Services (`--profile finance`)
- **Firefly III**: Port 8081 (Personal Finance)
- **MariaDB**: Included for Firefly

### Networking Services (`--profile networking`)
- **DNSMasq**: Port 53 (DNS Server)
- **Pi-hole**: Network Mode (Ad-blocker)

## Environment Configuration

### Required Environment Files
Create these files before starting:

#### `./n8n/.env`
```
# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=post
DB_POSTGRESDB_PASSWORD=your_secure_password

# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_auth_password
WEBHOOK_URL=http://localhost:5678/
```

#### `./firefly/.env`
```
# Firefly Configuration
APP_ENV=local
APP_DEBUG=false
APP_LOG_LEVEL=info
DB_CONNECTION=mysql
DB_HOST=firefly_db
DB_PORT=3306
DB_DATABASE=firefly
DB_USERNAME=firefly
DB_PASSWORD=your_db_password
STATIC_CRON_TOKEN=your_32_character_token_here
```

#### `./firefly/.db.env`
```
# Database Credentials
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=firefly
MYSQL_USER=firefly
MYSQL_PASSWORD=your_db_password
```

### Optional Environment Variables
```bash
# Database GUI Access
export PGADMIN_EMAIL=your@email.com
export PGADMIN_PASSWORD=your_gui_password

# DNS Services
export DNS_USER=admin
export DNS_PASS=your_dns_password
```

## Port Reference

| Service | External Port | Internal Port | Profile |
|---------|---------------|--------------|---------|
| caddy | 80, 443, 2019 | 80, 443, 2019 | proxy+caddy |
| nginx-proxy | 8080, 8443 | 80, 443 | proxy+nginx |
| proxy-manager | 8081, 8082, 8444 | 80, 81, 443 | proxy+manager |
| traefik | 8085, 8445, 8086 | 80, 443, 8080 | proxy+traefik |
| mysql | 33069 | 3306 | databases |
| mysql8 | 33068 | 3306 | databases |
| pgsql | 54320 | 5432 | databases |
| pgvector | 54321 | 5432 | databases+ai |
| n8n | 5678 | 5678 | automation |
| ollama | 11434 | 11434 | ai |
| open-webui | 8090 | 8080 | ai |
| firefly_app | 8081 | 8080 | finance |
| pgadmin | 5011 | 80 | development+databases |
| redis | 6379 | 6379 | cache+automation |
| rabbitmq | 5672, 15672 | 5672, 15672 | queue+automation |
| nodejs | 3000 | 3000 | development |
| image-registry | 5200 | 5000 | development |

## Common Workflows

### Full Development Stack
```bash
# Start complete development environment
docker-compose --profile databases --profile development --profile automation --profile ai up -d
# Then choose your proxy:
docker-compose --profile caddy up -d  # OR nginx, manager, traefik
```

### AI Development
```bash
# AI/ML development setup
docker-compose --profile databases --profile ai up -d
docker-compose --profile caddy up -d
```

### Automation Testing
```bash
# Workflow automation testing
docker-compose --profile automation --profile databases up -d
docker-compose --profile nginx up -d
```

### Production Deployment
```bash
# Production-ready setup
docker-compose --profile databases --profile automation --profile finance up -d
docker-compose --profile caddy up -d  # Choose production proxy
```

## Security Notes

⚠️ **Important**: Replace default passwords before deploying to production!

- Database passwords use `secret` as placeholder
- Generate unique `STATIC_CRON_TOKEN` (32 characters)
- Use environment variables for sensitive data
- Consider using Docker secrets in production

## SSL/TLS Setup

### Automatic Certificates (Recommended)
Place certificates in `./certs/`:
- `docker.crt.pem` - Public certificate
- `docker.key.pem` - Private key

### Manual Configuration
Edit proxy service configurations to use Let's Encrypt or other certificate providers.

## Troubleshooting

### Port Conflicts
If ports are already in use:
1. Check: `lsof -i :80` and `lsof -i :443`
2. Stop conflicting services: `docker-compose down`
3. Choose different proxy profile

### Service Dependencies
Services with dependencies will automatically start in correct order:
- n8n → n8n_db
- open-webui → ollama
- firefly_app → firefly_db
- pgvector → pgsql

### Volume Permissions
```bash
# Fix permission issues
sudo chown -R $USER:$USER ./volumes/
chmod -R 755 ./volumes/
```

## Custom n8n Build (Playwright & Puppeteer)

The n8n service uses a custom Docker image that includes browser automation capabilities.

### Included Packages
- **n8n-nodes-playwright**: Browser automation using Playwright ([GitHub](https://github.com/valmayaki/n8n-playwright))
- **n8n-nodes-puppeteer**: Browser automation using Puppeteer (from npm)
- **Chromium**: System-installed browser for headless automation

### Building the Custom Image
```bash
# Build the custom n8n image
docker compose build n8n

# Rebuild without cache (after Dockerfile changes)
docker compose build --no-cache n8n
```

### Starting n8n
```bash
# Start n8n with automation profile
docker compose --profile automation up -d n8n

# Or start with databases
docker compose --profile automation --profile databases up -d
```

### Verifying Installation
```bash
# Check installed packages
docker exec -it n8n sh -c "ls /usr/local/lib/node_modules/n8n/node_modules | grep -E 'playwright|puppeteer'"
```

### Browser Configuration
The image is pre-configured to use system Chromium:
- `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser`
- `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser`

### Usage Notes
- Both Playwright and Puppeteer nodes will appear in n8n's node palette
- Browsers run in headless mode by default
- For custom scripts, use the Playwright node's "Run Custom Script" operation

## Advanced Usage

### Custom Networks
Services use isolated networks for security:
- `databases` - Database communication
- `ai` - AI/ML services
- `automation` - Workflow services
- `firefly_iii` - Finance isolation

### Health Checks
Database services include health checks:
```bash
# Check service health
docker-compose ps
docker healthcheck postgresql_container
```

## Development Tips

1. **Start Small**: Begin with databases, add services as needed
2. **Use Profiles**: Mix and match service categories
3. **Monitor Resources**: Use `docker stats` to track usage
4. **Persistent Data**: All data stored in `./service/data/` directories
5. **Environment First**: Configure `.env` files before starting

## Getting Help

- Check service logs: `docker-compose logs [service_name]`
- Restart services: `docker-compose restart [service_name]`
- Stop all: `docker-compose down`
- Clean volumes: `docker-compose down -v` (⚠️ deletes data!)

## Repository Structure

```
docker-servers/
├── docker-compose.yml          # Main configuration
├── n8n/.env                # n8n configuration
├── firefly/.env              # Firefly app config
├── firefly/.db.env           # Firefly database config
├── certs/                    # SSL certificates
├── [service]/data/           # Persistent data
└── README.md                 # This file
```

This modular approach allows developers to run exactly what they need without manual service installation or port conflicts.