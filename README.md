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
- 📊 Spam logging and daily email reports

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
| `SPAM_LOG_ENABLED` | No | Enable spam logging (default: false) |
| `SPAM_LOG_DIR` | No | Directory for spam logs (default: /var/log/hugo-contact) |
| `SPAM_LOG_MAX_SIZE_MB` | No | Maximum log file size before rotation (default: 10) |
| `SPAM_LOG_RETENTION_DAYS` | No | Days to keep old logs (default: 10) |
| `SPAM_REPORT_ENABLED` | No | Enable daily spam email reports (default: false) |
| `SPAM_REPORT_RECIPIENT` | No | Email for spam reports (defaults to RECIPIENT_EMAIL) |

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

## Spam Logging and Reporting

The application can log detected spam attempts and send daily email reports.

### Enable Spam Logging

Set these environment variables:
```bash
SPAM_LOG_ENABLED=true
SPAM_LOG_DIR=/var/log/hugo-contact  # or your preferred directory
SPAM_LOG_RETENTION_DAYS=10          # keep logs for 10 days
```

### Enable Daily Spam Reports

1. **Configure environment variables:**
   ```bash
   SPAM_REPORT_ENABLED=true
   SPAM_REPORT_RECIPIENT=admin@example.com  # optional, uses RECIPIENT_EMAIL if not set
   ```

2. **Set up the cron job:**
   ```bash
   # Add to crontab (runs daily at 9 AM)
   crontab -e
   ```
   
   Add this line:
   ```
   0 9 * * * /path/to/hugo-contact/scripts/send-spam-report.sh >> /var/log/hugo-contact/spam-report-cron.log 2>&1
   ```

3. **For Docker deployments:**
   
   Mount a volume for persistent log storage:
   ```bash
   docker run -v /host/path/logs:/var/log/hugo-contact ...
   ```

### Security Features

- All logged data is HTML-escaped and sanitized
- Maximum field lengths enforced
- Automatic log rotation to prevent disk exhaustion
- No user input is used in file paths
- JSON encoding prevents injection attacks

### Manual Report Generation

```bash
# Build the spam report tool
go build -o bin/spam-report ./cmd/spam-report/main.go

# Run manually
./bin/spam-report
```

## Troubleshooting

### "Forbidden" error
Update `CORS_ALLOW_ORIGINS` to include your domain

### "Invalid token" error
Ensure the form-token.js script is loaded before form submission

### Emails not sending
Check SMTP credentials and view container logs

### Spam reports not sending
- Verify `SPAM_REPORT_ENABLED=true` is set
- Check cron job is configured correctly
- Review logs in `/var/log/hugo-contact/spam-report-cron.log`
- Ensure SMTP credentials are accessible to the cron job

## License

MIT License