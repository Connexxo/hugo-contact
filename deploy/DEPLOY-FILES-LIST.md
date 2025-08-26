# Deploy Folder - Files for Deployment

## ESSENTIAL FILES TO UPLOAD (Required for Docker)
✅ `main.go` - Application source code  
✅ `Dockerfile` - Docker build configuration  
✅ `go.mod` - Go module dependencies  
✅ `go.sum` - Go dependency checksums  
✅ `docker-compose.build.yml` - Docker Compose configuration  

## MANAGEMENT SCRIPTS (Optional but Recommended)
✅ `manage-service.sh` - Service management script (start/stop/restart)  
✅ `check-status.sh` - Health check script  

## WEB MONITORING (Optional)
📄 `status.php` - PHP status page for web monitoring  
📄 `status-info.html` - Static HTML status information  

## DOCUMENTATION (Keep Locally, Don't Upload)
📚 `DEPLOYMENT-CHECKLIST.md` - Deployment guide  
📚 `README-DEPLOY.md` - Deployment overview  
📚 `DEPLOY-FILES-LIST.md` - This file  

## IMPORTANT NOTES:
1. **Create `.env` file on server** with your SMTP credentials (don't upload from local)
2. **Never upload `.env` files** containing passwords via FTP
3. **All files should go to**: `/home/k000490/www/12/htdocs/hugo-contact-app/`
4. **Pass sensitive data via Docker run command**, not in files