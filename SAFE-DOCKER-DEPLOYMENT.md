# Safe Docker Deployment Guide (FTP + Manual SSH)

A secure hybrid deployment approach that uses GitHub Actions for building and FTP upload, while keeping SSH operations manual for security.

## 🔒 Security Benefits

- ✅ **No SSH credentials in GitHub** - GitHub never has access to your server
- ✅ **FTP-only automation** - Limited to file uploads only
- ✅ **Manual control** - You decide when to deploy Docker containers
- ✅ **Secrets protection** - SMTP credentials safely stored in GitHub Secrets
- ✅ **Server isolation** - Main server access remains completely private

## 📋 How It Works

### Phase 1: Automated (GitHub Actions)
1. **Push to main branch** triggers workflow
2. **Build deployment package** with Docker files
3. **Inject secrets** from GitHub into .env file
4. **Upload via FTPS** to `/hugo-contact-docker/`

### Phase 2: Manual (Your SSH)
1. **SSH into server** with your credentials
2. **Navigate to directory** with uploaded files
3. **Run deployment script** to build and start Docker
4. **Verify health** and monitor as needed

## 🚀 Quick Start

### One-Time Setup

**1. Add these GitHub Secrets (if not already added):**
- `FTP_HOST` - Your FTP server hostname
- `FTP_USER` - Your FTP username  
- `FTP_PASS` - Your FTP password
- `TOKEN_SECRET` - Generate with: `openssl rand -base64 32`

(SMTP secrets already configured as you mentioned)

**2. First deployment:**
```bash
# After pushing to GitHub and FTP upload completes:
ssh k000490@your-server
cd /home/k000490/www/12/htdocs/hugo-contact-docker
./deploy-docker.sh
```

### Regular Updates

**After pushing code changes:**
```bash
# Wait for GitHub Actions to complete FTP upload
ssh k000490@your-server
cd /home/k000490/www/12/htdocs/hugo-contact-docker
./quick-update.sh
```

## 📁 Files Deployed via FTP

| File | Purpose |
|------|---------|
| `Dockerfile` | Docker build configuration |
| `docker-compose.build.yml` | Docker Compose setup |
| `main-https.go` | Application source code |
| `go.mod`, `go.sum` | Go dependencies |
| `.env` | Pre-configured with secrets from GitHub |
| `deploy-docker.sh` | Full deployment script |
| `quick-update.sh` | Quick rebuild script |
| `docker-manage.sh` | Complete management tool |

## 🔧 Management Commands

### Deployment Scripts

**Full deployment** (stop, build, start, verify):
```bash
./deploy-docker.sh
```

**Quick update** (rebuild and restart):
```bash
./quick-update.sh
```

**Advanced management**:
```bash
./docker-manage.sh status   # Check status
./docker-manage.sh logs     # View logs
./docker-manage.sh restart  # Restart container
./docker-manage.sh cleanup  # Clean old images
```

### Direct Docker Commands

**Check status:**
```bash
docker ps | grep hugo-contact-prod
```

**View logs:**
```bash
docker logs hugo-contact-prod
docker logs -f hugo-contact-prod  # Follow logs
```

**Restart container:**
```bash
docker restart hugo-contact-prod
```

**Stop container:**
```bash
docker stop hugo-contact-prod
docker rm hugo-contact-prod
```

## 📊 Monitoring

### Health Check
```bash
curl http://localhost:8080/health
# Expected: {"status":"healthy","service":"hugo-contact","timestamp":"..."}
```

### Test Endpoints
```bash
# Form token
curl http://localhost:8080/form-token.js

# Form submission (test)
curl -X POST -d "name=Test&email=test@example.com&message=Test" \
  http://localhost:8080/f/contact
```

### Container Resources
```bash
# Resource usage
docker stats hugo-contact-prod --no-stream

# Disk usage
docker system df
```

## 🚨 Troubleshooting

### Container Won't Start
```bash
# Check logs for errors
docker logs hugo-contact-prod

# Verify .env file
cat .env | head -5

# Rebuild from scratch
./deploy-docker.sh
```

### Port Conflicts
```bash
# Check what's using port 8080
netstat -tuln | grep 8080
ss -tuln | grep 8080

# Kill conflicting process or change port in .env
```

### Build Failures
```bash
# Check Docker status
docker --version
docker ps

# Clean and rebuild
docker system prune -a
./deploy-docker.sh
```

### FTP Upload Issues
- Check GitHub Actions logs
- Verify FTP credentials in GitHub Secrets
- Ensure FTPS (not plain FTP) is working

## 📈 Performance Tips

### Optimize Rebuilds
```bash
# Use quick-update.sh for faster rebuilds
./quick-update.sh

# Only use deploy-docker.sh for major changes
```

### Clean Up Regularly
```bash
# Remove old images and containers
./docker-manage.sh cleanup

# Check disk space
df -h
docker system df
```

### Monitor Resources
```bash
# Watch container resources
docker stats hugo-contact-prod

# Set resource limits if needed (edit docker run command)
--memory="64m" --cpus="0.5"
```

## 🔄 Workflow Summary

1. **Development**: Make changes locally
2. **Push**: Commit and push to GitHub main branch
3. **Automated**: GitHub Actions builds and uploads via FTP
4. **Manual**: SSH to server and run deployment script
5. **Verify**: Check health endpoint and logs

## 🎯 Key Benefits

- **Security**: No SSH access from GitHub
- **Control**: You decide when to deploy
- **Flexibility**: Can review files before deploying
- **Reliability**: Simple FTP + proven Docker
- **Monitoring**: Full access to logs and metrics

## 📝 Notes

- The `.env` file is auto-generated with your GitHub Secrets
- TOKEN_SECRET is unique per deployment for security
- Container auto-restarts on server reboot (`--restart unless-stopped`)
- Logs are available via `docker logs` (not file-based)
- Port 8080 must be available on your server

---

## ✅ Ready for Safe Deployment!

Your deployment is now:
- 🔒 **Secure** - No SSH credentials in GitHub
- 🚀 **Automated** - Push to deploy files
- 🎮 **Controlled** - Manual Docker operations
- 📊 **Monitored** - Full visibility into container health

**Next step**: Push to GitHub and run `./deploy-docker.sh` on your server!# Retrigger FTP deployment to upload all files
