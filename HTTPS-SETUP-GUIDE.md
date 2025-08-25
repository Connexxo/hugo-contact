# HTTPS Setup Guide for Hugo Contact Form

Since your server only accepts HTTPS connections, you need to set up a reverse proxy to forward HTTPS requests to your Hugo Contact Form server running on HTTP port 8080.

## 🔒 Solution Overview

**Problem**: Hugo Contact Form runs on HTTP port 8080, but your server only accepts HTTPS.

**Solution**: Set up a reverse proxy to handle HTTPS and forward to the HTTP backend.

## 📋 Setup Options

### Option 1: Nginx Reverse Proxy (Recommended)

1. **Add to your nginx configuration** (usually in `/etc/nginx/sites-available/your-site`):

```nginx
# Add this to your existing server block
server {
    listen 443 ssl http2;
    server_name contact.connexxo.com;  # or connexxo.com
    
    # Your existing SSL configuration
    ssl_certificate /path/to/your/certificate.crt;
    ssl_private_key /path/to/your/private.key;
    
    # Proxy contact form endpoints
    location /f/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://connexxo.com" always;
        add_header Access-Control-Allow-Methods "POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type" always;
    }
    
    location /form-token.js {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Cache-Control "no-store";
    }
}
```

2. **Reload nginx**: `sudo nginx -t && sudo systemctl reload nginx`

### Option 2: Apache/cPanel Setup

If you're using Apache or cPanel:

1. **Enable mod_rewrite and mod_proxy** (usually enabled by default)

2. **Add to your .htaccess** in web root:

```apache
RewriteEngine On

# Proxy contact form requests
RewriteRule ^f/contact$ http://127.0.0.1:8080/f/contact [P,L]
RewriteRule ^form-token\.js$ http://127.0.0.1:8080/form-token.js [P,L]

# CORS headers
Header always set Access-Control-Allow-Origin "https://connexxo.com"
Header always set Access-Control-Allow-Methods "POST, OPTIONS"
Header always set Access-Control-Allow-Headers "Content-Type"
```

### Option 3: Cloudflare/CDN Setup

If using Cloudflare:

1. **Add DNS record**: `contact.connexxo.com` → Your server IP
2. **Enable "Proxied" (orange cloud)**
3. **Set up Page Rule** for `contact.connexxo.com/f/*` → Forward to `http://your-server-ip:8080/f/$1`

## 🚀 Deployment Steps

### 1. Deploy Hugo Contact Server

```bash
# Download latest deployment package from GitHub Actions
# Upload to server and run:
./deploy.sh production

# Verify it's running on port 8080
curl http://localhost:8080/health
```

### 2. Configure Reverse Proxy

Choose one of the options above based on your server setup.

### 3. Update CORS Settings

Make sure your Hugo Contact server's CORS settings include your domain:

```bash
# In your .env file:
CORS_ALLOW_ORIGINS=https://connexxo.com,https://www.connexxo.com
```

### 4. Test the Setup

```bash
# Test HTTPS endpoints
curl https://contact.connexxo.com/form-token.js
curl -X POST https://contact.connexxo.com/f/contact \
  -d "name=Test&email=test@example.com&message=Test&subject=HTTPS Test"
```

## ✅ Your Hugo Form Should Use

Your form is already correctly configured for HTTPS:

```html
<form action="https://contact.connexxo.com/f/contact" method="POST">
<!-- Your existing form fields -->
</form>

<script>
const s = document.createElement('script');
s.src = 'https://contact.connexxo.com/form-token.js';
document.body.appendChild(s);
</script>
```

## 🔍 Troubleshooting

### Check if proxy is working:
```bash
# Test health endpoint through proxy
curl https://contact.connexxo.com/health
```

### Check Hugo Contact server logs:
```bash
./manage-service.sh logs
```

### Common issues:
- **502 Bad Gateway**: Hugo Contact server not running on port 8080
- **CORS errors**: Update CORS_ALLOW_ORIGINS in .env file
- **SSL certificate errors**: Check your SSL configuration

## 📞 Need Help?

1. Check your server's specific documentation for reverse proxy setup
2. Verify Hugo Contact server is running: `docker ps | grep hugo-contact`
3. Check logs for errors: `./manage-service.sh logs`

---

**🎉 Once configured, your HTTPS contact form will work perfectly with the subject field!**