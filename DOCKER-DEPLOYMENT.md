# Hugo Contact Form - Docker Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Hugo Contact Form service using Docker on a shared hosting environment with FTP and SSH access.

## Prerequisites
- FTP access to upload files
- SSH access to the server
- Docker installed and accessible on the server
- Domain configured to point to the server

## Quick Deployment Steps

### 1. Prepare Deployment Files
Upload these 4 files to your server via FTP:
- `Dockerfile`
- `main-https.go`
- `go.mod`
- `go.sum`

Upload location: `/home/k000490/www/12/htdocs/`

### 2. Build Docker Image
Connect via SSH and run:
```bash
cd /home/k000490/www/12/htdocs/
docker build -t hugo-contact:latest .
```

### 3. Run Docker Container
Create and start the container with your configuration:
```bash
docker run -d \
  --name hugo-contact-prod \
  --restart unless-stopped \
  -p 8080:8080 \
  -e PORT=8080 \
  -e CORS_ALLOW_ORIGINS=https://connexxo.com,http://connexxo.com,https://contact.connexxo.com,http://contact.connexxo.com \
  -e SMTP_HOST=mail23.hi7.de \
  -e SMTP_PORT=587 \
  -e SMTP_USERNAME=k000490-017 \
  -e SMTP_PASSWORD=your-smtp-password \
  -e SENDER_EMAIL=system@connexxo.com \
  -e RECIPIENT_EMAIL=info@connexxo.com \
  -e TOKEN_SECRET=your-secret-token-here \
  hugo-contact:latest
```

### 4. Configure Apache Routing
Create `.htaccess` file in the web root:
```bash
cat > /home/k000490/www/12/htdocs/.htaccess << 'EOF'
RewriteEngine On
RewriteRule ^(.*)$ http://localhost:8080/$1 [P,L]
EOF
```

### 5. Clean Up Build Files
Remove temporary files for security:
```bash
rm -f Dockerfile main-https.go go.mod go.sum
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| PORT | Port for the service | 8080 |
| CORS_ALLOW_ORIGINS | Comma-separated allowed origins | https://connexxo.com,http://connexxo.com |
| SMTP_HOST | SMTP server hostname | mail23.hi7.de |
| SMTP_PORT | SMTP server port | 587 |
| SMTP_USERNAME | SMTP username | k000490-017 |
| SMTP_PASSWORD | SMTP password | (secure password) |
| SENDER_EMAIL | Email sender address | system@connexxo.com |
| RECIPIENT_EMAIL | Where to send form submissions | info@connexxo.com |
| TOKEN_SECRET | Secret for anti-spam tokens (min 16 chars) | (random string) |

## Testing the Deployment

### 1. Test Health Endpoint
```bash
curl http://localhost:8080/health
```
Expected: `{"status":"healthy","service":"hugo-contact","timestamp":"..."}`

### 2. Test Token Generation
```bash
curl http://localhost:8080/form-token.js
```
Expected: JavaScript function that generates form tokens

### 3. Test External Access
Visit in browser: `http://contact.connexxo.com/health`

## Container Management

### View Container Status
```bash
docker ps | grep hugo-contact-prod
```

### View Container Logs
```bash
docker logs hugo-contact-prod --tail 50
```

### Stop Container
```bash
docker stop hugo-contact-prod
```

### Remove Container
```bash
docker rm hugo-contact-prod
```

### Restart Container
```bash
docker restart hugo-contact-prod
```

## Updating the Application

1. Stop and remove the existing container:
```bash
docker stop hugo-contact-prod
docker rm hugo-contact-prod
```

2. Remove old image:
```bash
docker rmi hugo-contact:latest
```

3. Upload new files via FTP
4. Rebuild image (Step 2)
5. Run new container (Step 3)

## HTML Form Integration

Add this to your HTML pages that need the contact form:

```html
<!-- Load anti-spam token script -->
<script src="http://contact.connexxo.com/form-token.js"></script>

<!-- Contact Form -->
<form action="http://contact.connexxo.com/f/contact" method="POST">
    <input type="text" name="name" required placeholder="Your Name">
    <input type="email" name="email" required placeholder="Your Email">
    <input type="text" name="subject" placeholder="Subject (optional)">
    <textarea name="message" required placeholder="Your Message"></textarea>
    
    <!-- Optional: Redirect after submission -->
    <input type="hidden" name="_next" value="https://connexxo.com/thank-you">
    
    <!-- Honeypot field (leave empty) -->
    <input type="text" name="_gotcha" style="display:none">
    
    <button type="submit">Send Message</button>
</form>
```

## Troubleshooting

### Problem: "Forbidden" error when submitting form
**Solution**: Update CORS_ALLOW_ORIGINS to include the domain where your form is hosted

### Problem: "Invalid token" error
**Solution**: Ensure the form-token.js script is loaded before form submission

### Problem: Container won't start
**Solution**: Check if port 8080 is already in use: `netstat -tuln | grep 8080`

### Problem: Emails not sending
**Solution**: Verify SMTP credentials and check container logs for errors

## Security Notes

1. Always remove build files after deployment
2. Use strong TOKEN_SECRET (minimum 16 characters)
3. Keep SMTP credentials secure
4. Regularly update the container for security patches
5. Monitor logs for suspicious activity

## Support

For issues or questions about the Hugo Contact Form service, check the logs first:
```bash
docker logs hugo-contact-prod --tail 100
```

The logs will show:
- Form submission attempts
- CORS validation
- Email sending status
- Any errors or warnings