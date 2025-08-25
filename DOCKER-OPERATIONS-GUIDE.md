# Docker Operations Guide - Hugo Contact Form

Complete guide for managing the Hugo Contact Form Docker container on `https://contact.connexxo.com`

## 📋 Table of Contents

- [Quick Reference](#quick-reference)
- [Starting the Service](#starting-the-service)
- [Stopping the Service](#stopping-the-service)
- [Restarting the Service](#restarting-the-service)
- [Updating/Redeploying](#updatingredeploying)
- [Monitoring & Logs](#monitoring--logs)
- [Troubleshooting](#troubleshooting)
- [Emergency Procedures](#emergency-procedures)

## 🚀 Quick Reference

```bash
# Start
./manage-service.sh start

# Stop
./manage-service.sh stop

# Restart
./manage-service.sh restart

# Update (rebuild and restart)
./manage-service.sh update

# View logs
./manage-service.sh logs

# Check status
./manage-service.sh status
```

## 🟢 Starting the Service

### Method 1: Using Management Script (Recommended)

```bash
cd ~/hugo-contact
./manage-service.sh start
```

This script will:
- Build the Docker image (if needed)
- Start the container
- Run health checks
- Display status

For updates with code changes:
```bash
./manage-service.sh update
```

### Method 2: Manual Start

```bash
cd ~/hugo-contact

# Start in background (detached mode)
docker-compose -f docker-compose.build.yml up -d

# Or start with build (if code changed)
docker-compose -f docker-compose.build.yml up --build -d
```

### Verify Service is Running

```bash
# Check container status
docker-compose -f docker-compose.build.yml ps

# Test health endpoint
curl http://localhost:8080/health

# Test from outside
curl https://contact.connexxo.com/health
```

## 🔴 Stopping the Service

### Graceful Stop

```bash
cd ~/hugo-contact

# Stop and remove container
docker-compose -f docker-compose.build.yml down

# Stop but keep container (can restart faster)
docker-compose -f docker-compose.build.yml stop
```

### Emergency Stop

```bash
# Force stop if graceful stop fails
docker-compose -f docker-compose.build.yml kill

# Find and stop by container name
docker stop hugo-contact-prod
```

## 🔄 Restarting the Service

### Quick Restart (No Code Changes)

```bash
cd ~/hugo-contact

# Restart existing container
docker-compose -f docker-compose.build.yml restart

# Or stop and start
docker-compose -f docker-compose.build.yml stop
docker-compose -f docker-compose.build.yml start
```

### Full Restart (With Rebuild)

```bash
# If code or configuration changed
./deploy-docker.sh

# Or manually
docker-compose -f docker-compose.build.yml down
docker-compose -f docker-compose.build.yml up --build -d
```

## 🔧 Updating/Redeploying

### Step 1: Update Code/Configuration

```bash
# Edit environment variables
nano .env

# Or upload new code files via FTP/SSH
# - main.go
# - Dockerfile
# - etc.
```

### Step 2: Rebuild and Deploy

```bash
cd ~/hugo-contact

# Use management script (recommended)
./manage-service.sh update

# Or manually rebuild
docker-compose -f docker-compose.build.yml build --no-cache
docker-compose -f docker-compose.build.yml up -d
```

### Step 3: Verify Update

```bash
# Check logs for startup
docker-compose -f docker-compose.build.yml logs --tail=50

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/form-token.js
```

## 📊 Monitoring & Logs

### View Logs

```bash
# Live logs (follow mode)
docker-compose -f docker-compose.build.yml logs -f

# Last 100 lines
docker-compose -f docker-compose.build.yml logs --tail=100

# Logs from last hour
docker-compose -f docker-compose.build.yml logs --since=1h

# Save logs to file
docker-compose -f docker-compose.build.yml logs > contact-form-logs.txt
```

### Monitor Container

```bash
# Container status
docker-compose -f docker-compose.build.yml ps

# Resource usage
docker stats hugo-contact-prod

# Inspect container
docker inspect hugo-contact-prod
```

### Remote Monitoring

```bash
# From your local machine
curl -I https://contact.connexxo.com/health
curl -I https://contact.connexxo.com/form-token.js

# Or visit status page
https://contact.connexxo.com/status.html
```

## 🛠️ Troubleshooting

### Container Won't Start

```bash
# Check for errors
docker-compose -f docker-compose.build.yml logs

# Check if port is in use
netstat -tuln | grep 8080
lsof -i :8080

# Remove old containers
docker-compose -f docker-compose.build.yml down
docker system prune -f
```

### Build Failures

```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker-compose -f docker-compose.build.yml build --no-cache

# Check Docker disk space
df -h
docker system df
```

### Service Not Responding

```bash
# Check container is running
docker ps | grep hugo-contact

# Check internal connectivity
docker exec hugo-contact-prod wget -O- http://localhost:8080/health

# Check logs for errors
docker-compose -f docker-compose.build.yml logs | grep ERROR
```

### Email Not Sending

```bash
# Check SMTP configuration
grep SMTP .env

# Test SMTP connection from container
docker exec hugo-contact-prod sh -c 'nc -zv $SMTP_HOST $SMTP_PORT'

# Check recent email attempts
docker-compose -f docker-compose.build.yml logs | grep -E "(email|smtp|mail)"
```

## 🚨 Emergency Procedures

### Service Down - Quick Recovery

```bash
# 1. Try restart first
./manage-service.sh restart

# 2. If that fails, full redeploy
./manage-service.sh update

# 3. If still failing, check logs
docker-compose -f docker-compose.build.yml logs --tail=100
```

### Rollback to Previous Version

```bash
# Stop current
docker-compose -f docker-compose.build.yml down

# List available images
docker images | grep hugo-contact

# Run previous image (replace TAG with actual tag)
docker run -d --name hugo-contact-prod \
  --env-file .env \
  -p 8080:8080 \
  hugo-contact:TAG
```

### Complete Reset

```bash
# Stop everything
docker-compose -f docker-compose.build.yml down

# Remove all related images
docker images | grep hugo-contact | awk '{print $3}' | xargs docker rmi -f

# Clean system
docker system prune -f

# Fresh deploy
./manage-service.sh start
```

## 📝 Configuration Files

### Key Files
- `.env` - Environment configuration (SMTP, CORS, etc.)
- `docker-compose.build.yml` - Docker Compose configuration
- `Dockerfile` - Build instructions
- `main.go` - Application source code

### Environment Variables (.env)
```bash
# Key variables to check/update
SMTP_HOST=mail23.hi7.de
SMTP_PORT=587
RECIPIENT_EMAIL=info@connexxo.com
CORS_ALLOW_ORIGINS=https://connexxo.com,https://v2.connexxo.com
TOKEN_SECRET=<secure-32-char-secret>
PORT=8080
```

## 🔐 Security Notes

1. **Always use HTTPS** for production endpoints
2. **Keep TOKEN_SECRET secure** - Never commit to git
3. **Restrict CORS_ALLOW_ORIGINS** to your domains only
4. **Regular updates** - Redeploy periodically for security patches
5. **Monitor logs** for suspicious activity

## 📞 Health Check URLs

- **Internal**: `http://localhost:8080/health`
- **External**: `http://contact.connexxo.com:8080/health`
- **Token Test**: `http://contact.connexxo.com:8080/form-token.js`
- **Status Page**: `https://contact.connexxo.com/status.php` (recommended)
- **Status Page**: `https://contact.connexxo.com/status-info.html` (manual testing)

## 🗓️ Maintenance Schedule

### Daily
- Check status page
- Monitor error logs

### Weekly
- Review all logs
- Check disk space
- Verify backups

### Monthly
- Update Docker images
- Review security patches
- Test email delivery

---

**Support Contact**: For issues, check logs first, then contact your system administrator.