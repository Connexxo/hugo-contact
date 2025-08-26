# Binary Deployment Guide - Hugo Contact Form HTTPS

This guide explains how to deploy the Hugo Contact Form as a standalone HTTPS server using a compiled Go binary.

## 🚀 Quick Start

### Prerequisites
- Server with HTTPS/SSL certificates configured
- FTP access to upload files
- SSH access to start/stop the server
- Sudo privileges (for port 443)

### GitHub Secrets Required

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

```
FTP_HOST=your-ftp-server.com
FTP_USER=your-ftp-username
FTP_PASS=your-ftp-password

SMTP_HOST=your-smtp-server.com
SMTP_PORT=587
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SENDER_EMAIL=noreply@yourdomain.com
RECIPIENT_EMAIL=contact@yourdomain.com

SSL_CERT_PATH=/path/to/certificate.crt
SSL_KEY_PATH=/path/to/private.key

TOKEN_SECRET=generate-random-32-char-string
```

## 📦 Automated Deployment Process

### 1. Push to GitHub

When you push to the `main` branch, GitHub Actions will:
- Build the Go binary for Linux AMD64
- Create deployment scripts
- Upload everything via FTP to `/htdocs/hugo-contact/`

### 2. SSH to Your Server

```bash
ssh your-server
cd /htdocs/hugo-contact
```

### 3. Start the HTTPS Server

```bash
sudo ./restart-contact-server.sh
```

### 4. Verify It's Working

```bash
./check-https-status.sh
```

Or test manually:
```bash
curl https://contact.connexxo.com/health
```

## 🔧 Manual Deployment

### Build Locally

```bash
# Make scripts executable
chmod +x scripts/build-binary.sh

# Build for Linux server
./scripts/build-binary.sh linux

# Or create complete deployment package
./scripts/build-binary.sh package
```

### Upload Files

Upload these files to your server:
- `hugo-contact-https` (the binary)
- `.env.production` (configuration)
- `restart-contact-server.sh` (management script)
- `check-https-status.sh` (status check)

### Configure Environment

Copy and edit the template:
```bash
cp .env.production.template .env.production
nano .env.production
```

Set your values:
```env
USE_HTTPS=true
PORT=443
SSL_CERT_PATH=/etc/letsencrypt/live/contact.connexxo.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/contact.connexxo.com/privkey.pem
# ... other settings
```

## 🛠️ Server Management

### Start/Restart Server
```bash
sudo ./restart-contact-server.sh
# or
sudo ./restart-contact-server.sh restart
```

### Stop Server
```bash
sudo ./restart-contact-server.sh stop
```

### Check Status
```bash
./restart-contact-server.sh status
```

### View Logs
```bash
./restart-contact-server.sh logs
# or follow in real-time
tail -f hugo-contact.log
```

## 🔍 Troubleshooting

### Common Issues

#### Port 443 Permission Denied
- Make sure to use `sudo` when starting the server
- Alternative: Use port 8443 instead (no sudo required)

#### SSL Certificate Not Found
- Check paths in `.env.production`
- Verify certificate files exist and are readable
- Common locations:
  - Let's Encrypt: `/etc/letsencrypt/live/domain/`
  - Custom: `/etc/ssl/certs/` and `/etc/ssl/private/`

#### Server Not Accessible Externally
- Check firewall allows port 443
- Verify DNS points to correct server
- Test locally first: `curl -k https://localhost/health`

#### Form Not Sending Emails
- Check SMTP settings in `.env.production`
- Verify SMTP credentials are correct
- Check server logs: `tail -f hugo-contact.log`

### Debug Mode

For more detailed logging, edit `.env.production`:
```env
LOG_LEVEL=debug
```

Then restart the server.

## 📍 Endpoints

Once running, your contact form server provides:

- **Health Check**: `https://contact.connexxo.com/health`
- **Contact Form**: `https://contact.connexxo.com/f/contact`
- **Token Script**: `https://contact.connexxo.com/form-token.js`

## 🔄 Updating

To update to a new version:

1. Push changes to GitHub `main` branch
2. Wait for GitHub Actions to complete
3. SSH to server and restart:
   ```bash
   sudo ./restart-contact-server.sh
   ```

## 🔒 Security Notes

- **TOKEN_SECRET**: Keep this secret and random
- **SSL Certificates**: Ensure proper file permissions
- **CORS Origins**: Only allow your actual domains
- **Logs**: Don't log sensitive information

## 📝 Form HTML

Your website form should use HTTPS URLs:

```html
<form action="https://contact.connexxo.com/f/contact" method="POST">
    <input type="text" name="name" required>
    <input type="email" name="email" required>
    <input type="text" name="subject">
    <textarea name="message" required></textarea>
    <input type="hidden" name="_gotcha">
    <button type="submit">Send</button>
</form>

<script src="https://contact.connexxo.com/form-token.js" defer></script>
```

## 🆘 Need Help?

1. Check server logs: `tail -50 hugo-contact.log`
2. Verify environment: `cat .env.production`
3. Test endpoints manually with `curl`
4. Check GitHub Actions logs for deployment issues

---

**✅ Your HTTPS contact form server is ready for production!**