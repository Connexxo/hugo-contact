# 📦 Deployment Package - Hugo Contact Form

This folder contains **all the files needed** to deploy the Hugo Contact Form service to your production server.

## 🗂️ Files in This Package

### **Core Application**
- `main.go` - Go application source code
- `Dockerfile` - Docker build configuration
- `go.mod` - Go module definition
- `go.sum` - Go dependencies (empty - no external deps)

### **Docker Configuration**
- `docker-compose.build.yml` - Production Docker Compose config

### **Environment Configuration**
- `.env.server` - Production environment template (rename to `.env` and configure)

### **Management Scripts**
- `manage-service.sh` - Complete service management (start/stop/restart/update/logs/status)
- `check-status.sh` - Health monitoring script

### **Monitoring Pages**
- `status.php` - Server-side PHP status checker (recommended for HTTPS sites)
- `status-info.html` - Static information page with manual test links

### **Documentation**
- `DEPLOYMENT-CHECKLIST.md` - Complete step-by-step deployment guide
- `README-DEPLOY.md` - This file

## 🚀 Quick Deployment

1. **Upload all files** in this folder to your server
2. **Make scripts executable**: `chmod +x manage-service.sh check-status.sh`
3. **Configure environment**: `cp .env.server .env` and edit with your settings
4. **Deploy**: `./manage-service.sh start`
5. **Monitor**: Upload `status.php` to your web server for monitoring

## 📋 Complete Instructions

See `DEPLOYMENT-CHECKLIST.md` for detailed step-by-step instructions.

---

**Service URL**: https://contact.connexxo.com  
**Health Check**: http://contact.connexxo.com:8080/health  
**Management**: `./manage-service.sh status`