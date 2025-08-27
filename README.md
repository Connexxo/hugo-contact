# Hugo Contact Form

A secure, Formspree-compatible contact form backend for Hugo and static websites.

## Features

- 🔒 Anti-spam protection with timestamp-based tokens
- 📧 SMTP email delivery with customizable settings
- 🐳 Docker containerized for easy deployment
- 🔗 Formspree-compatible API endpoints
- ⚡ Lightweight Go implementation
- 🌐 CORS support for multiple domains
- 🏥 Health check endpoints for monitoring
- 🍯 Honeypot spam protection
- 📝 Custom subject field support

## Quick Start

### Docker Deployment

1. **Prepare deployment package locally:**
   ```bash
   ./scripts/prepare-deployment.sh
   ```

2. **Upload files via FTP** from `deploy-package/` to your server

3. **On the server via SSH:**
   ```bash
   export SMTP_PASSWORD='your-password'
   ./deploy-docker.sh
   ```

For detailed deployment instructions, see [DOCKER-DEPLOYMENT.md](DOCKER-DEPLOYMENT.md).

## Configuration

Configure via environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `SMTP_HOST` | Yes | SMTP server hostname |
| `SMTP_PORT` | Yes | SMTP server port (usually 587 or 465) |
| `SMTP_USERNAME` | Yes | SMTP authentication username |
| `SMTP_PASSWORD` | Yes | SMTP authentication password |
| `SENDER_EMAIL` | Yes | Email sender address |
| `RECIPIENT_EMAIL` | Yes | Where to send form submissions |
| `TOKEN_SECRET` | No | Secret for anti-spam tokens (auto-generated if not set) |
| `CORS_ALLOW_ORIGINS` | No | Comma-separated allowed origins (default: "*") |
| `PORT` | No | Server port (default: 8080) |

## HTML Form Integration

```html
<!-- Load anti-spam token script -->
<script src="http://your-domain.com/form-token.js"></script>

<!-- Contact Form -->
<form action="http://your-domain.com/f/contact" method="POST">
    <input type="text" name="name" required placeholder="Your Name">
    <input type="email" name="email" required placeholder="Your Email">
    <input type="text" name="subject" placeholder="Subject (optional)">
    <textarea name="message" required placeholder="Your Message"></textarea>
    
    <!-- Optional: Redirect after submission -->
    <input type="hidden" name="_next" value="https://your-site.com/thank-you">
    
    <!-- Honeypot field (anti-spam) -->
    <input type="text" name="_gotcha" style="display:none">
    
    <button type="submit">Send Message</button>
</form>
```

The form token script automatically injects a timestamp-based token that expires in 15 minutes and prevents submissions within 2 seconds (likely bots).

## API Endpoints

- `POST /f/contact` - Form submission endpoint (Formspree-compatible)
- `GET /form-token.js` - Anti-spam token JavaScript
- `GET /health` - Health check endpoint

## Container Management

### View Status
```bash
docker ps | grep hugo-contact-prod
```

### View Logs
```bash
docker logs hugo-contact-prod --tail 50
```

### Restart Container
```bash
docker restart hugo-contact-prod
```

### Update Container
```bash
docker stop hugo-contact-prod
docker rm hugo-contact-prod
# Then redeploy with new image
```

## Project Structure

```
hugo-contact/
├── main-https.go              # Main application with HTTPS support
├── Dockerfile                 # Docker container configuration
├── DOCKER-DEPLOYMENT.md       # Detailed deployment guide
├── scripts/
│   ├── prepare-deployment.sh  # Prepare files for deployment
│   └── deploy-docker.sh       # Server-side deployment script
└── README.md                  # This file
```

## Development

### Building from source
```bash
go build -o hugo-contact main-https.go
```

### Running locally
```bash
export SMTP_HOST=smtp.example.com
export SMTP_PORT=587
export SMTP_USERNAME=user@example.com
export SMTP_PASSWORD=password
export SENDER_EMAIL=sender@example.com
export RECIPIENT_EMAIL=recipient@example.com

./hugo-contact
```

### Running with Docker locally
```bash
docker build -t hugo-contact .
docker run -p 8080:8080 \
  -e SMTP_HOST=smtp.example.com \
  -e SMTP_PORT=587 \
  -e SMTP_USERNAME=user@example.com \
  -e SMTP_PASSWORD=password \
  -e SENDER_EMAIL=sender@example.com \
  -e RECIPIENT_EMAIL=recipient@example.com \
  hugo-contact
```

## Troubleshooting

### "Forbidden" error
Update `CORS_ALLOW_ORIGINS` to include your domain

### "Invalid token" error
Ensure the form-token.js script is loaded before form submission

### Emails not sending
Check SMTP credentials and view container logs

## License

MIT License