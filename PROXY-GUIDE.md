# Proxy Server Configuration Guide

## Overview
This repository supports four different reverse proxy solutions, each with the ability to use standard ports 80/443. Choose the proxy that best fits your needs.

## Available Proxy Options

### 1. Caddy (Recommended for Simplicity)
**Best for**: Simple setups, automatic SSL, minimal configuration

**Features**:
- Automatic HTTPS with Let's Encrypt
- Simple Caddyfile configuration
- Built-in Docker service discovery
- Lightweight and fast

**Start with ports 80/443**:
```bash
docker-compose --profile caddy-direct up -d
# OR
./start.sh databases caddy-direct
```

**Configuration**: Place certificates in `./certs/`:
- `docker.crt.pem` - Public certificate
- `docker.key.pem` - Private key

**Access**:
- HTTP: http://localhost:80
- HTTPS: https://localhost:443
- Admin: http://localhost:2019

---

### 2. Nginx Proxy (Advanced Users)
**Best for**: Traditional setups, complex routing, custom configurations

**Features**:
- Industry-standard reverse proxy
- Highly configurable
- Battle-tested performance
- Custom nginx.conf support

**Start with ports 80/443**:
```bash
docker-compose --profile nginx-direct up -d
# OR
./start.sh automation nginx-direct
```

**Configuration**: Place custom configs in `./nginx-proxy/conf.d/`

**Access**:
- HTTP: http://localhost:80
- HTTPS: https://localhost:443

---

### 3. Nginx Proxy Manager (GUI Management)
**Best for**: Visual management, non-technical users, dashboard lovers

**Features**:
- Beautiful web-based GUI
- Visual SSL certificate management
- Access control lists
- Proxy host management
- Stream/redirection support

**Start with ports 80/443**:
```bash
docker-compose --profile manager-direct up -d
# OR
./start.sh finance manager-direct
```

**Default Credentials**:
- Email: admin@example.com
- Password: changeme
- **IMPORTANT**: Change these on first login!

**Access**:
- HTTP: http://localhost:80
- HTTPS: https://localhost:443
- Dashboard: http://localhost:81

---

### 4. Traefik (Modern/Cloud-Native)
**Best for**: Microservices, Kubernetes-style setups, dynamic configuration

**Features**:
- Automatic service discovery
- Let's Encrypt integration
- Middleware support
- Modern dashboard
- Label-based configuration

**Start with ports 80/443**:
```bash
docker-compose --profile traefik-direct up -d
# OR
./start.sh ai traefik-direct
```

**Configuration**: Place configs in `./traefik/config/`

**Access**:
- HTTP: http://localhost:80
- HTTPS: https://localhost:443
- Dashboard: http://localhost:8087

---

## Port Management Strategy

### How It Works

Each proxy can be started in **two modes**:

#### 1. Direct Mode (Ports 80/443)
Use the `-direct` suffix to run a proxy with standard HTTP/HTTPS ports:

```bash
# Caddy with ports 80/443
docker-compose --profile caddy-direct up -d

# Nginx with ports 80/443
docker-compose --profile nginx-direct up -d

# Manager with ports 80/443
docker-compose --profile manager-direct up -d

# Traefik with ports 80/443
docker-compose --profile traefik-direct up -d
```

**Limitation**: Only ONE direct proxy can run at a time (Docker prevents port conflicts)

#### 2. Alternative Port Mode (Development)
Without the `-direct` suffix, proxies use alternative ports for simultaneous testing:

```bash
# Run multiple proxies simultaneously for testing
docker-compose --profile caddy --profile nginx --profile traefik up -d
```

Port assignments:
- Caddy: 8080/8443
- Nginx: 8081/8445
- Manager: 8082/8446
- Traefik: 8085/8447

---

## Common Scenarios

### Scenario 1: Production Single Proxy
**Goal**: Run one proxy with standard ports

```bash
# Choose your proxy (caddy, nginx, manager, or traefik)
docker-compose --profile databases --profile caddy-direct up -d
```

### Scenario 2: Development Testing
**Goal**: Test multiple proxies without conflicts

```bash
# Start all proxies with different ports
docker-compose --profile proxy up -d
```

Access them at:
- Caddy: http://localhost:8080
- Nginx: http://localhost:8081
- Manager: http://localhost:8082 (Dashboard: 8083)
- Traefik: http://localhost:8085 (Dashboard: 8086)

### Scenario 3: Switching Proxies
**Goal**: Try different proxies with ports 80/443

```bash
# Stop current proxy
docker-compose down

# Start different proxy
docker-compose --profile nginx-direct up -d
```

### Scenario 4: Complete Stack
**Goal**: Full environment with specific proxy

```bash
# Development stack with Caddy
./start.sh databases caddy-direct
./start.sh development
./start.sh ai

# OR all at once
docker-compose --profile databases --profile development --profile ai --profile caddy-direct up -d
```

---

## Proxy Comparison

| Feature | Caddy | Nginx | Manager | Traefik |
|---------|-------|-------|---------|---------|
| Ease of Use | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Auto SSL | ✅ | ❌ | ✅ | ✅ |
| GUI | ❌ | ❌ | ✅ | ✅ |
| Performance | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Config Style | File | File | GUI | Labels |
| Best For | Simple | Advanced | Visual | Cloud-Native |
| Resource Usage | Low | Low | Medium | Medium |
| Learning Curve | Easy | Medium | Easy | Medium |

---

## SSL/TLS Configuration

### Option 1: Custom Certificates (All Proxies)
Place your certificates in `./certs/`:
```
./certs/
  ├── docker.crt.pem    # Public certificate
  └── docker.key.pem    # Private key
```

### Option 2: Let's Encrypt (Caddy, Manager, Traefik)
These proxies support automatic Let's Encrypt certificates:

**Caddy**: Automatic via Caddyfile
**Manager**: Configure via GUI (Certificates tab)
**Traefik**: Configure via `./traefik/config/`

### Option 3: Self-Signed (Development)
Generate self-signed certificates:
```bash
openssl req -x509 -newkey rsa:4096 -keyout ./certs/docker.key.pem -out ./certs/docker.crt.pem -days 365 -nodes
```

---

## Troubleshooting

### Port Already in Use
**Error**: "Bind for 0.0.0.0:80 failed: port is already allocated"

**Solution**:
```bash
# Check what's using the port
lsof -i :80
lsof -i :443

# Stop conflicting services
docker-compose down

# Or stop system services (macOS/Linux)
sudo systemctl stop nginx    # Linux
sudo brew services stop nginx # macOS
```

### Multiple Proxies Running
**Problem**: Accidentally started multiple direct proxies

**Solution**:
```bash
# Stop all services
docker-compose down

# Start only the one you need
docker-compose --profile caddy-direct up -d
```

### Proxy Not Accessible
**Check**:
1. Service is running: `docker-compose ps`
2. Ports are mapped: `docker port <container_name>`
3. Firewall allows traffic: `sudo ufw allow 80/tcp`
4. No port conflicts: `netstat -tulpn | grep :80`

### SSL Certificate Errors
**For custom certificates**:
1. Verify file permissions: `chmod 644 ./certs/*.pem`
2. Check certificate validity: `openssl x509 -in ./certs/docker.crt.pem -text -noout`
3. Ensure paths are correct in docker-compose.yml

---

## Best Practices

### 1. Choose One Proxy for Production
Don't run multiple proxies in production. Pick one that fits your needs:
- **Caddy**: Simple, automatic SSL
- **Nginx**: Maximum control
- **Manager**: GUI preference
- **Traefik**: Microservices

### 2. Use Profiles Consistently
```bash
# Good: Explicit profile
docker-compose --profile caddy-direct up -d

# Avoid: No profile (won't start any proxy)
docker-compose up -d
```

### 3. Environment Variables
Use `.env` file for sensitive data:
```bash
# .env
PROXY_SSL_EMAIL=your@email.com
PROXY_DOMAIN=example.com
```

### 4. Health Monitoring
Check proxy health regularly:
```bash
# View logs
docker-compose logs proxy-caddy-direct
docker-compose logs proxy-nginx-direct

# Check status
docker-compose ps
```

### 5. Backup Configuration
Regularly backup:
- `./certs/` - SSL certificates
- `./nginx-proxy-manager/data/` - Manager config
- `./traefik/config/` - Traefik config

---

## Quick Reference

| Task | Command |
|------|---------|
| Start Caddy (80/443) | `docker-compose --profile caddy-direct up -d` |
| Start Nginx (80/443) | `docker-compose --profile nginx-direct up -d` |
| Start Manager (80/443) | `docker-compose --profile manager-direct up -d` |
| Start Traefik (80/443) | `docker-compose --profile traefik-direct up -d` |
| Stop all | `docker-compose down` |
| View logs | `docker-compose logs [service]` |
| Restart proxy | `docker-compose restart [service]` |

---

## Additional Resources

- **Caddy**: https://caddyserver.com/docs/
- **Nginx**: https://nginx.org/en/docs/
- **Nginx Proxy Manager**: https://nginxproxymanager.com/
- **Traefik**: https://doc.traefik.io/traefik/

---

## Support

For issues or questions:
1. Check logs: `docker-compose logs [proxy-service]`
2. Review configuration files
3. Consult official documentation
4. Check repository issues on GitHub