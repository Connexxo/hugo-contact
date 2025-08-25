# FTP Deployment Guide for Hugo Contact Form

Simple GitHub Actions deployment using FTP - no SSH keys required!

## 🚀 Quick Setup

### 1. Add FTP Secrets to GitHub

Go to: **GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**

Add these **Repository Secrets**:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `FTP_SERVER` | Your FTP server hostname | `ftp.yourhost.com` |
| `FTP_USERNAME` | FTP username | `your-ftp-username` |
| `FTP_PASSWORD` | FTP password | `your-ftp-password` |
| `FTP_REMOTE_DIR` | Directory on server | `/public_html/hugo-contact/` or `~/hugo-contact/` |
| `FTP_PORT` | FTP port (optional) | `21` (default) |
| `FTP_PROTOCOL` | Protocol (optional) | `ftp` or `ftps` |
| `FTP_SECURITY` | Security mode (optional) | `loose` |
| `SMTP_PASSWORD` | SMTP password from .env.server | `cihbon-syqtYz-8gaxzi` |
| `TOKEN_SECRET` | Random 32+ character string | Generate: `openssl rand -hex 32` |

### 2. Test Deployment

Once secrets are configured:

```bash
git add .
git commit -m "Configure FTP deployment"
git push origin main
```

## 📁 What Gets Deployed

The workflow uploads these files to your server:
- `main.go` - Application code
- `Dockerfile` - Docker configuration  
- `go.mod`, `go.sum` - Go dependencies
- `docker-compose.build.yml` - Docker compose file
- `manage-service.sh` - Service management script
- `deploy.sh` - Deployment automation
- `.env` - Production environment file (auto-generated)
- `DEPLOY-INSTRUCTIONS.txt` - Manual steps

## 🛠️ Manual Steps After FTP Upload

After GitHub Actions uploads the files, **SSH into your server** to complete deployment:

```bash
# SSH into your server
ssh user@yourserver.com

# Navigate to uploaded files
cd /path/to/uploaded/files

# Make scripts executable
chmod +x deploy.sh manage-service.sh

# Run deployment
./deploy.sh production

# Check service status
./manage-service.sh status

# Test health endpoint
curl http://localhost:8080/health
```

## 🔧 FTP Configuration Options

### Common FTP Settings:

**Standard FTP:**
```yaml
FTP_PORT: 21
FTP_PROTOCOL: ftp
FTP_SECURITY: loose
```

**Secure FTP (FTPS):**
```yaml
FTP_PORT: 21
FTP_PROTOCOL: ftps
FTP_SECURITY: strict
```

**FTP over SSL:**
```yaml
FTP_PORT: 990
FTP_PROTOCOL: ftps-implicit
FTP_SECURITY: strict
```

### Directory Examples:

- **cPanel/shared hosting**: `/public_html/hugo-contact/`
- **Home directory**: `~/hugo-contact/`
- **Custom path**: `/var/www/hugo-contact/`

## 📊 Deployment Process

### Automatic (GitHub Actions):
1. ✅ Run tests
2. ✅ Build application  
3. ✅ Create deployment package
4. ✅ Generate .env file with secrets
5. ✅ Upload via FTP

### Manual (On Server):
1. SSH into server
2. Run `./deploy.sh production`
3. Verify with `./manage-service.sh status`

## 🚨 Troubleshooting

### FTP Connection Issues:

**"Connection refused":**
- Check FTP_SERVER hostname
- Verify FTP_PORT (usually 21)
- Confirm FTP service is running

**"Login failed":**
- Verify FTP_USERNAME and FTP_PASSWORD
- Check if account is active
- Try connecting with FTP client manually

**"Permission denied":**
- Check FTP_REMOTE_DIR exists
- Verify write permissions
- Ensure directory path is correct

### Deployment Issues:

**Scripts not executable:**
```bash
chmod +x deploy.sh manage-service.sh
```

**Docker not found:**
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Logout and login again
```

**Port 8080 blocked:**
```bash
# Check if port is in use
netstat -tuln | grep 8080

# Check firewall
sudo ufw status
sudo ufw allow 8080
```

## 📋 Verification Checklist

After deployment:

- [ ] Files uploaded via FTP
- [ ] Scripts are executable (`chmod +x`)
- [ ] Docker container is running
- [ ] Health endpoint responds: `curl http://localhost:8080/health`
- [ ] Form token endpoint works: `curl http://localhost:8080/form-token.js`
- [ ] Service logs show no errors: `./manage-service.sh logs`

## 🔄 Re-deployment

For updates, just push to main branch:

```bash
git add .
git commit -m "Update application"
git push origin main
```

Then SSH to server and run:
```bash
./deploy.sh production
```

## 🆘 Need Help?

**Check deployment logs:**
- GitHub: Repository → Actions → Latest workflow
- Server: `./manage-service.sh logs`

**Common fixes:**
1. Verify all FTP secrets are set correctly
2. Check FTP server connection manually
3. Ensure server has Docker installed
4. Confirm .env file was created with correct values

---

**🎉 Your FTP deployment is ready! Push to main branch to deploy automatically.**