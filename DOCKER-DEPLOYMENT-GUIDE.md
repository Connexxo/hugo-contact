# Hugo Contact Form - Docker Deployment Guide

Complete step-by-step documentation for deploying the Hugo Contact Form application via Docker on shared hosting with FTP access.

## 📋 Overview

**Application**: Hugo Contact Form Service (Go-based)  
**Deployment Method**: Docker containerization via FTP upload  
**Server Environment**: Shared hosting with Docker support  
**Security Model**: Secure credential management via environment variables  

## 🏗️ Architecture

```
Server Structure:
/home/k000490/www/12/
├── htdocs/                          ← Public web directory
│   ├── hugo-contact-app/            ← Application files (protected)
│   │   ├── main.go                  ← Go source code
│   │   ├── Dockerfile               ← Docker build config
│   │   ├── docker-compose.build.yml ← Docker Compose config
│   │   ├── go.mod & go.sum         ← Go dependencies
│   │   ├── .env                     ← Basic config (no secrets)
│   │   └── manage-service.sh        ← Management script
│   └── (website files)
└── (no access to parallel directories)
```

## 🔐 Security Approach

**Challenge**: Shared hosting restricts file placement to `/htdocs` (publicly accessible)  
**Solution**: 
- Store application files in subdirectory under htdocs
- Pass sensitive credentials via Docker environment variables (not files)
- Never store passwords in files accessible via web

## 📦 Prerequisites

### Server Requirements
- Docker 27.5.1-ce or later ✅
- Docker Compose 2.22.0 or later ✅
- SSH access for command execution ✅
- FTP access for file uploads ✅

### Local Requirements
- FTP client (FileZilla, etc.)
- SSH client
- SMTP credentials for email sending

## 🚀 Deployment Process

### Step 1: Prepare Local Files

**Files to Upload** (from `deploy/` folder):
```
✅ main.go                    - Application source code
✅ Dockerfile                 - Docker build configuration  
✅ go.mod                     - Go module dependencies
✅ go.sum                     - Go dependency checksums
✅ docker-compose.build.yml   - Docker Compose configuration
✅ manage-service.sh          - Service management script (optional)
✅ check-status.sh            - Health monitoring script (optional)
```

**Files NOT to Upload**:
```
❌ .env.production           - Contains sensitive passwords
❌ Documentation files       - Keep locally for reference
❌ Test files               - Not needed on server
```

### Step 2: FTP Upload

**Target Directory**: `/home/k000490/www/12/htdocs/hugo-contact-app/`

1. Connect to server via FTP
2. Create directory: `hugo-contact-app` under htdocs
3. Upload all required files to this directory
4. Verify all files transferred correctly

### Step 3: Server Configuration

**Connect via SSH**:
```bash
# Navigate to application directory
cd /home/k000490/www/12/htdocs/hugo-contact-app/

# Verify files uploaded correctly
ls -la

# Make management scripts executable (if uploaded)
chmod +x manage-service.sh check-status.sh
```

### Step 4: Environment Configuration

**Create minimal .env file** (no sensitive data):
```bash
cat > .env << 'EOF'
# Basic configuration (sensitive data passed via docker run)
PORT=8080
CORS_ALLOW_ORIGINS=https://contact.connexxo.com,https://connexxo.com

# Placeholder values (overridden at runtime)
SMTP_HOST=placeholder
SMTP_PORT=587
SMTP_USERNAME=placeholder
SMTP_PASSWORD=placeholder
SENDER_EMAIL=placeholder
RECIPIENT_EMAIL=placeholder
TOKEN_SECRET=placeholder
EOF
```

### Step 5: Build Docker Image

```bash
# Build the Docker image
docker-compose -f docker-compose.build.yml build

# Verify image was created
docker images | grep hugo
```

**Expected Output**:
```
hugo-contact-app-hugo-contact   latest   [IMAGE_ID]   [TIME]   26.6MB
```

### Step 6: Deploy Container

**Remove any existing container**:
```bash
# Check for existing containers
docker ps -a

# Remove if exists
docker rm -f hugo-contact-prod
```

**Start new container with secure credentials**:
```bash
docker run -d \
  --name hugo-contact-prod \
  --restart unless-stopped \
  -p 8080:8080 \
  -e PORT=8080 \
  -e CORS_ALLOW_ORIGINS=https://contact.connexxo.com,https://connexxo.com \
  -e SMTP_HOST=your-smtp-host \
  -e SMTP_PORT=587 \
  -e SMTP_USERNAME=your-username \
  -e SMTP_PASSWORD=your-password \
  -e SENDER_EMAIL=sender@domain.com \
  -e RECIPIENT_EMAIL=recipient@domain.com \
  -e TOKEN_SECRET=$(openssl rand -base64 32) \
  hugo-contact-app-hugo-contact
```

**Replace Placeholders**:
- `your-smtp-host` → Actual SMTP server
- `your-username` → SMTP login username
- `your-password` → SMTP password
- `sender@domain.com` → From email address
- `recipient@domain.com` → Where to receive form submissions

### Step 7: Verification

**Check container status**:
```bash
# Verify container is running
docker ps

# Check logs
docker logs hugo-contact-prod

# Test health endpoint
curl http://localhost:8080/health
```

**Expected Results**:
```bash
# docker ps
CONTAINER ID   IMAGE                           STATUS                    PORTS
cd32150c92a9   hugo-contact-app-hugo-contact   Up 10 seconds (healthy)   0.0.0.0:8080->8080/tcp

# Health check
{"status":"healthy","service":"hugo-contact","timestamp":"2025-08-26T07:34:41Z"}
```

## 🔧 Service Management

### Essential Commands

**Check Status**:
```bash
docker ps                           # Running containers
docker logs hugo-contact-prod       # Application logs
curl http://localhost:8080/health   # Health check
```

**Restart Service**:
```bash
docker restart hugo-contact-prod
```

**Update Application**:
```bash
# 1. Upload new files via FTP
# 2. Rebuild image
docker-compose -f docker-compose.build.yml build

# 3. Stop old container
docker rm -f hugo-contact-prod

# 4. Start new container (use same docker run command as Step 6)
```

**Stop Service**:
```bash
docker stop hugo-contact-prod
docker rm hugo-contact-prod
```

### Using Management Script (if uploaded)

```bash
# Start service
./manage-service.sh start

# Stop service  
./manage-service.sh stop

# Restart service
./manage-service.sh restart

# View status
./manage-service.sh status

# View logs
./manage-service.sh logs
```

## 🌐 Service Endpoints

Once deployed, the service provides:

**Health Check**:
- URL: `https://contact.connexxo.com:8080/health`
- Response: `{"status":"healthy","service":"hugo-contact","timestamp":"..."}`

**Form Token** (for spam protection):
- URL: `https://contact.connexxo.com:8080/form-token.js`  
- Usage: Include in HTML pages with forms

**Form Submission**:
- URL: `https://contact.connexxo.com:8080/f/contact`
- Method: POST
- Content-Type: `application/x-www-form-urlencoded`

## 📝 HTML Form Integration

**Example form for your Hugo site**:
```html
<form action="https://contact.connexxo.com:8080/f/contact" method="POST">
  <input type="text" name="name" required>
  <input type="email" name="email" required>
  <input type="text" name="subject" placeholder="Subject (optional)">
  <textarea name="message" required></textarea>
  
  <!-- Honeypot spam protection -->
  <input type="text" name="_gotcha" style="display:none">
  
  <!-- Optional redirect after submission -->
  <input type="hidden" name="_next" value="https://yoursite.com/thank-you">
  
  <button type="submit">Send Message</button>
</form>

<!-- Anti-spam token (include on pages with forms) -->
<script src="https://contact.connexxo.com:8080/form-token.js"></script>
```

## 🚨 Security Best Practices

### 1. Credential Management
- ✅ Never store passwords in files
- ✅ Pass secrets via Docker environment variables
- ✅ Use strong TOKEN_SECRET (auto-generated)
- ✅ Restrict CORS origins to your actual domains

### 2. File Security
- ✅ Application files in protected directory structure
- ✅ Sensitive data passed at runtime, not stored
- ✅ Regular cleanup of old images and containers

### 3. Monitoring
- ✅ Health check endpoint for monitoring
- ✅ Structured logging with timestamps
- ✅ Container restart policy configured

## 📊 Monitoring & Troubleshooting

### Health Monitoring
```bash
# Quick health check
curl -f http://localhost:8080/health || echo "Service unhealthy"

# Detailed status
docker inspect hugo-contact-prod --format='{{.State.Health.Status}}'
```

### Log Analysis
```bash
# View recent logs
docker logs --tail 50 hugo-contact-prod

# Follow live logs  
docker logs -f hugo-contact-prod

# Search for errors
docker logs hugo-contact-prod 2>&1 | grep -i error
```

### Common Issues

**Container won't start**:
```bash
# Check for port conflicts
netstat -tlnp | grep 8080

# Check image exists
docker images | grep hugo

# Check logs for errors
docker logs hugo-contact-prod
```

**Form submissions not working**:
```bash
# Verify SMTP credentials in logs
docker logs hugo-contact-prod | grep -i smtp

# Test token endpoint
curl http://localhost:8080/form-token.js

# Check CORS configuration
curl -H "Origin: https://yoursite.com" http://localhost:8080/health
```

## 🔄 Maintenance Schedule

### Weekly
- Check container health status
- Review logs for errors or suspicious activity
- Verify disk space usage

### Monthly  
- Update application if new versions available
- Clean up old Docker images: `docker system prune -a`
- Review and rotate TOKEN_SECRET if desired

### As Needed
- Update SMTP credentials if changed
- Modify CORS origins for new domains
- Scale resources if traffic increases

## 📋 Deployment Checklist

**Pre-Deployment**:
- [ ] Verify Docker and Docker Compose installed on server
- [ ] Prepare SMTP credentials
- [ ] Test FTP access to server
- [ ] Clean and verify files in deploy folder

**Deployment**:
- [ ] Upload application files via FTP
- [ ] SSH into server
- [ ] Create minimal .env file (no secrets)
- [ ] Build Docker image successfully
- [ ] Remove any existing containers
- [ ] Start container with real SMTP credentials
- [ ] Verify container health status

**Post-Deployment**:
- [ ] Test health endpoint responds
- [ ] Test form token endpoint  
- [ ] Submit test form (if possible)
- [ ] Update DNS/proxy if needed
- [ ] Document any custom configurations
- [ ] Set up monitoring/alerts

## 📞 Support Information

**Container Name**: `hugo-contact-prod`  
**Image Name**: `hugo-contact-app-hugo-contact`  
**Port**: `8080`  
**Health Endpoint**: `/health`  
**Log Location**: Docker logs (not file-based)

**Key Files on Server**:
- `/home/k000490/www/12/htdocs/hugo-contact-app/` - Application directory
- `docker-compose.build.yml` - Build configuration  
- `.env` - Basic configuration (no secrets)

---

**✅ Deployment Successfully Completed**  
**Service Status**: Healthy and Running  
**Last Updated**: 2025-08-26  
**Next Review**: As needed for updates or issues