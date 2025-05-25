# hugo-contact

This is a small, self-hosted Go application that acts as a drop-in replacement for services like Formspree or Airform. It accepts form submissions from static sites (like Hugo) and sends them to a configured SMTP endpoint.

## Features

- Formspree-compatible POST endpoint (`/f/contact`)
- Honeypot spam protection
- CORS support
- Structured JSON logging using Go's `slog` package
- Environment-configurable SMTP (Zoho, Gmail, Mailgun, etc.)
- Optional redirect with `_next` field
- Lightweight and Docker-ready
- No external dependencies outside of Go's standard library

## Environment Variables

| Variable             | Description                       |
|----------------------|-----------------------------------|
| `SMTP_HOST`          | SMTP server host (e.g., `smtp.example.com`) |
| `SMTP_PORT`          | SMTP port (usually `587`)         |
| `SMTP_USERNAME`      | SMTP login username               |
| `SMTP_PASSWORD`      | SMTP login password or app key    |
| `RECIPIENT_EMAIL`    | Email address to receive form submissions |
| `PORT`               | Port to run the server on (default: `8080`) |
| `CORS_ALLOW_ORIGIN`  | CORS allowed origin (default: `*`) |

## Example HTML Form

```html
<form action="https://yourdomain.com/f/contact" method="POST">
  <input type="text" name="name" required>
  <input type="email" name="email" required>
  <textarea name="message" required></textarea>
  <input type="text" name="_gotcha" style="display:none">
  <button type="submit">Send</button>
</form>
```

## Building and Running Locally

```sh
go build -o hugo-contact .
./hugo-contact
```

## Running with Docker

```sh
docker build -t hugo-contact .

# Run it
SMTP_HOST=smtp.example.com \
SMTP_PORT=587 \
SMTP_USERNAME=your@domain.com \
SMTP_PASSWORD=yourpassword \
RECIPIENT_EMAIL=you@domain.com \
PORT=8080 \
CORS_ALLOW_ORIGIN=https://yourhugo.site \
docker run -p 8080:8080 --env-file .env hugo-contact
```

## Building and Pushing to Docker Hub

```sh
docker build -t yourrepository/hugo-contact:latest .
docker push yourrepository/hugo-contact:latest
```

## License

MIT

---
Maintained by [Marc Lewis](https://marclewis.com) - [@gottafixthat](https://mstdn.social/@gottafixthat)
