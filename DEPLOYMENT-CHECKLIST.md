# Hugo Contact Form - Complete Deployment Checklist

## 📦 Files to Upload to Server

### **Core Application Files (Required)**
- ✅ `main.go` - Main application with health endpoint
- ✅ `Dockerfile` - Docker build instructions  
- ✅ `go.mod` - Go module dependencies
- ✅ `go.sum` - Go dependency checksums
- ✅ `docker-compose.build.yml` - Docker compose for server build

### **Configuration Files (Required)**
- ✅ `.env.server` - Environment template (rename to `.env` on server)

### **Management Scripts (Required)**
- ✅ `manage-service.sh` - Service management script

### **Web Files (Optional but Recommended)**
- ✅ `status.html` - Status monitoring page
- ✅ `.htaccess` - Web server proxy configuration

### **Documentation (Optional)**
- `DOCKER-OPERATIONS-GUIDE.md` - Complete operations guide
- `DEPLOYMENT-CHECKLIST.md` - This checklist

## 🚀 Deployment Steps

### **Step 1: Upload Files**
```bash
# Via SCP (recommended)
scp main.go Dockerfile go.mod go.sum docker-compose.build.yml .env.server manage-service.sh status.html .htaccess \
    user@yourserver.com:~/hugo-contact/

# Or upload via FTP to your server directory
```

### **Step 2: Server Configuration**
```bash
# SSH into your server
ssh user@yourserver.com
cd ~/hugo-contact

# Make scripts executable
chmod +x manage-service.sh

# Configure environment
cp .env.server .env
nano .env  # Edit with your settings
```

### **Step 3: Deploy Service**
```bash
# Update/deploy the service
./manage-service.sh update

# Check status
./manage-service.sh status
```

### **Step 4: Web Server Setup**
```bash
# Upload .htaccess to your web root (if using Apache)
# Upload status.html to your web root

# Test endpoints
curl http://localhost:8080/health
curl http://contact.connexxo.com:8080/health
```

## 🔧 Environment Configuration

### **Update .env with your settings:**
```bash
# SMTP Configuration
SMTP_HOST=mail23.hi7.de
SMTP_PORT=587
SMTP_USERNAME=k000490-017
SMTP_PASSWORD=cihbon-syqtYz-8gaxzi
SENDER_EMAIL=system@connexxo.com
RECIPIENT_EMAIL=info@connexxo.com

# CORS Configuration (Multiple Domains)
CORS_ALLOW_ORIGINS=http://localhost:1313,https://v2.connexxo.com,https://connexxo.com,http://contact.connexxo.com:8080

# Security Token (Generate a secure 32+ character secret)
TOKEN_SECRET=your-production-32-character-secret-key-change-this

# Server Configuration
PORT=8080
```

## ✅ Verification Tests

### **After deployment, test these:**
```bash
# Local tests (on server)
curl http://localhost:8080/health
curl http://localhost:8080/form-token.js

# External tests (from your computer)
curl http://contact.connexxo.com:8080/health
curl http://contact.connexxo.com:8080/form-token.js

# Status page
https://contact.connexxo.com/status.html
```

## 🎯 Hugo Integration

### **Update your Hugo templates:**
```html
<!-- Load anti-spam JavaScript -->
<script src="http://contact.connexxo.com:8080/form-token.js"></script>

<!-- Contact form -->
<form action="http://contact.connexxo.com:8080/f/contact" method="POST">
  <!-- Honeypot fields (required) -->
  <input type="text" name="_gotcha" style="display:none" tabindex="-1" autocomplete="off">
  <input type="text" name="nickname" style="display:none" tabindex="-1" autocomplete="off">
  
  <!-- Optional redirect after success -->
  <input type="hidden" name="_next" value="https://connexxo.com/thank-you/">
  
  <!-- Your form fields -->
  <input type="text" name="name" required>
  <input type="email" name="email" required>
  <textarea name="message" required></textarea>
  <button type="submit">Send Message</button>
</form>
```

## 🛠️ Service Management

### **Common commands:**
```bash
# Start service
./manage-service.sh start

# Stop service  
./manage-service.sh stop

# Restart service
./manage-service.sh restart

# Update service (rebuild and restart)
./manage-service.sh update

# Check status
./manage-service.sh status

# View logs
./manage-service.sh logs

# Follow logs
./manage-service.sh follow
```

## 🔍 Monitoring URLs

- **Health Check**: `http://contact.connexxo.com:8080/health`
- **Token Endpoint**: `http://contact.connexxo.com:8080/form-token.js`
- **Status Page**: `https://contact.connexxo.com/status.html`
- **Contact Form**: `http://contact.connexxo.com:8080/f/contact`

## 🚨 Troubleshooting

### **If deployment fails:**
```bash
# Check Docker logs
./manage-service.sh logs

# Check if container is running
docker ps

# Check port availability
netstat -tuln | grep 8080

# Restart service
./manage-service.sh restart
```

### **If emails don't send:**
- Check SMTP settings in `.env`
- Verify recipient email address
- Check service logs for SMTP errors

### **If CORS issues:**
- Verify `CORS_ALLOW_ORIGINS` includes your Hugo site URL
- Check browser console for CORS errors
- Test with curl to verify server response

---

**🎉 You're ready to deploy! All files have been touched and are ready for upload.**