# Automated Docker Deployment Guide

Complete automation for Hugo Contact Form deployment using GitHub Actions + Docker + SSH.

## 🚀 Overview

**One-Push Deployment**: Push to GitHub `main` branch → Automatic Docker build → SSH deploy → Health verified → Ready!

**Architecture**:
- GitHub Actions builds Docker image
- SSH uploads and deploys to your server  
- Container auto-starts with health checks
- Zero manual steps after setup

## 🔐 GitHub Secrets Setup

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

### SSH Connection
```
SSH_HOST=your-server-hostname-or-ip
SSH_USER=k000490
SSH_PASS=your-ssh-password
SSH_PORT=22
```

### Application Configuration  
```
SMTP_HOST=your-smtp-server.com
SMTP_PORT=587
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SENDER_EMAIL=noreply@yourdomain.com
RECIPIENT_EMAIL=contact@yourdomain.com
TOKEN_SECRET=generate-random-32-char-string
CORS_ALLOW_ORIGINS=https://connexxo.com,https://www.connexxo.com
```

### Generate TOKEN_SECRET
```bash
# Generate secure random token
openssl rand -base64 32
```

## 📦 Deployment Process

### Automatic Trigger
Every push to `main` branch triggers:

1. **Build Phase** (GitHub Actions)
   - Checkout latest code
   - Build Docker image locally  
   - Save image as compressed tar file

2. **Deploy Phase** (SSH to your server)
   - Stop existing container gracefully
   - Clean up old Docker images
   - Upload new Docker image
   - Load image and start container
   - Verify health and functionality

3. **Verification Phase**
   - Health check endpoints
   - Container status validation
   - Service availability confirmation

### Manual Management
Use the enhanced management script on your server:

```bash
# SSH into your server
ssh k000490@your-server

# Navigate to deployment directory
cd /home/k000490/www/12/htdocs/hugo-contact

# Use enhanced Docker management
./scripts/docker-manage.sh status    # Check status
./scripts/docker-manage.sh logs      # View logs  
./scripts/docker-manage.sh restart   # Restart container
./scripts/docker-manage.sh update    # Full rebuild
./scripts/docker-manage.sh cleanup   # Clean old images
```

## 🔧 Management Commands

### Container Operations
```bash
# Start container
./scripts/docker-manage.sh start

# Stop container
./scripts/docker-manage.sh stop

# Restart container  
./scripts/docker-manage.sh restart

# Update (rebuild and restart)
./scripts/docker-manage.sh update
```

### Monitoring
```bash
# Check overall status
./scripts/docker-manage.sh status

# View recent logs (default: 50 lines)
./scripts/docker-manage.sh logs

# View more logs
./scripts/docker-manage.sh logs 100

# Follow logs in real-time
./scripts/docker-manage.sh follow

# Health check only
./scripts/docker-manage.sh health
```

### Maintenance
```bash
# Clean up old containers and images
./scripts/docker-manage.sh cleanup

# Check Docker disk usage
docker system df

# Manual container management
docker ps                           # List running containers
docker logs hugo-contact-prod       # View container logs
docker restart hugo-contact-prod    # Restart container
```

## 🌐 Service Access

### Current Container Status
Your container is already running and healthy:
- **Container**: `hugo-contact-prod`
- **Port**: `8080`
- **Status**: Up 13+ hours (healthy)

### Endpoints
- **Health Check**: `http://your-server:8080/health`
- **Form Submission**: `http://your-server:8080/f/contact`  
- **Anti-spam Token**: `http://your-server:8080/form-token.js`

### Access Options

**Option 1: Direct Access** (Simplest)
Configure your domain DNS to point to `your-server:8080`

**Option 2: Nginx/Apache Proxy**
Set up local web server to proxy HTTPS → HTTP:8080

**Option 3: Hosting Provider Tools**
Use your hosting provider's reverse proxy/load balancer features

## 📊 Monitoring & Health Checks

### Automated Monitoring
The deployment includes:
- **Health Checks**: Container automatically monitored
- **Auto-Restart**: `--restart unless-stopped` policy
- **Log Rotation**: Automatic log management
- **Resource Limits**: Optimized container configuration

### Health Check Endpoints
```bash
# Test health endpoint
curl http://localhost:8080/health
# Expected: {"status":"healthy","service":"hugo-contact","timestamp":"..."}

# Test form token
curl http://localhost:8080/form-token.js  
# Expected: JavaScript code for anti-spam tokens

# Test form submission (POST)
curl -X POST -d "name=Test&email=test@example.com&message=Hello" \
  http://localhost:8080/f/contact
```

## 🔄 Update Process

### Automated Updates
1. Make changes to your code
2. Commit and push to `main` branch
3. GitHub Actions automatically:
   - Builds new Docker image
   - Deploys to server
   - Verifies functionality
4. Service updated with zero downtime

### Manual Updates
```bash
# On your server, for immediate updates:
cd /home/k000490/www/12/htdocs/hugo-contact
./scripts/docker-manage.sh update
```

## 🛠️ Troubleshooting

### Common Issues

**Container won't start**:
```bash
# Check container logs
./scripts/docker-manage.sh logs

# Check if image exists
docker images | grep hugo-contact

# Rebuild if needed
./scripts/docker-manage.sh update
```

**Health check fails**:
```bash
# Check detailed status
./scripts/docker-manage.sh status

# View live logs
./scripts/docker-manage.sh follow

# Manual health test
curl -v http://localhost:8080/health
```

**Port conflicts**:
```bash
# Check what's using port 8080
netstat -tuln | grep 8080
ss -tuln | grep 8080

# Check container port mapping
docker port hugo-contact-prod
```

**Out of disk space**:
```bash
# Clean up Docker resources
./scripts/docker-manage.sh cleanup

# Check disk usage
df -h
docker system df
```

### Debug Commands
```bash
# Enter running container for debugging
docker exec -it hugo-contact-prod sh

# Check container resource usage  
docker stats hugo-contact-prod

# Inspect container configuration
docker inspect hugo-contact-prod

# Test SMTP connectivity (from inside container)
docker exec hugo-contact-prod ping your-smtp-server.com
```

## 🔒 Security Notes

### Best Practices
- ✅ **Secrets Management**: All sensitive data via GitHub Secrets
- ✅ **Container Security**: Non-root user execution
- ✅ **Network Security**: Only necessary ports exposed
- ✅ **Resource Limits**: Container resource constraints
- ✅ **Log Security**: No sensitive data in logs

### Security Checklist
- [ ] GitHub Secrets configured (never in code)
- [ ] TOKEN_SECRET is random and secure (32+ characters)
- [ ] SMTP credentials are correct and secure
- [ ] CORS origins restricted to your domains only
- [ ] Server firewall allows only necessary ports
- [ ] SSH access secured with strong passwords/keys
- [ ] Regular container updates scheduled

## 📈 Performance Optimization

### Container Optimization
- **Multi-stage Build**: Minimal production image (26.6MB)
- **Alpine Linux**: Lightweight base OS
- **Static Binary**: No runtime dependencies
- **Health Checks**: Built-in container monitoring
- **Resource Limits**: Optimized memory/CPU usage

### Monitoring Metrics
```bash
# Container resource usage
docker stats hugo-contact-prod --no-stream

# Application performance
time curl http://localhost:8080/health

# Docker system resources
docker system df
docker system events
```

## 📋 Maintenance Schedule

### Daily (Automated)
- Health checks every 30 seconds
- Automatic container restart if unhealthy
- Log rotation and cleanup

### Weekly (Manual)
```bash
# Check overall system health
./scripts/docker-manage.sh status

# Clean up old resources
./scripts/docker-manage.sh cleanup

# Review recent logs for issues
./scripts/docker-manage.sh logs 500 | grep -i error
```

### Monthly (Manual)
- Review and rotate TOKEN_SECRET if needed
- Update base Docker images
- Review disk usage and cleanup
- Test backup/restore procedures

## 🆘 Support & Troubleshooting

### Key Information
- **Server**: `/home/k000490/www/12/htdocs/hugo-contact`
- **Container**: `hugo-contact-prod`
- **Image**: `hugo-contact-app-hugo-contact:latest`
- **Port**: `8080`
- **Management**: `./scripts/docker-manage.sh`

### Quick Diagnostics
```bash
# Complete status check
./scripts/docker-manage.sh status

# Full container information
docker inspect hugo-contact-prod

# Network connectivity test  
curl -I http://localhost:8080/health
```

### Emergency Recovery
```bash
# Complete rebuild from scratch
./scripts/docker-manage.sh stop
./scripts/docker-manage.sh cleanup  
./scripts/docker-manage.sh update

# Restore from GitHub (if local files corrupted)
git clone https://github.com/Connexxo/hugo-contact.git
cd hugo-contact
./scripts/docker-manage.sh start
```

---

## ✅ Ready for Production!

Your Hugo Contact Form now has **fully automated deployment**:
- ✅ **Push to GitHub** → Automatic deployment
- ✅ **Zero manual steps** after initial setup  
- ✅ **Health monitoring** and auto-restart
- ✅ **Professional container management**
- ✅ **Easy troubleshooting** and maintenance

**Next Steps**:
1. Configure GitHub Secrets (see setup section above)
2. Test first automated deployment
3. Configure domain access to port 8080
4. Set up monitoring alerts (optional)

🎉 **Your contact form service is now enterprise-ready with full automation!**