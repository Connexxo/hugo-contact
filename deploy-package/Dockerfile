FROM golang:1.24-alpine AS build

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hugo-contact main-https.go spam_logger.go
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o spam-report ./cmd/spam-report/main.go

FROM alpine:latest

# Install ca-certificates for HTTPS SMTP and create directories
RUN apk --no-cache add ca-certificates tzdata
RUN adduser -D -s /bin/sh appuser
RUN mkdir -p /var/log/hugo-contact && chown appuser:appuser /var/log/hugo-contact

ENV PORT=8080
EXPOSE 8080

# Volume for spam logs
VOLUME ["/var/log/hugo-contact"]

WORKDIR /app
COPY --from=build /app/hugo-contact .
COPY --from=build /app/spam-report ./bin/spam-report

# Copy scripts
COPY scripts/ ./scripts/
RUN chmod +x scripts/send-spam-report.sh

RUN chown -R appuser:appuser /app

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:$PORT/form-token.js || exit 1

ENTRYPOINT ["./hugo-contact"]
