FROM golang:1.24-alpine AS build

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hugo-contact .

FROM alpine:latest

# Install ca-certificates for HTTPS SMTP
RUN apk --no-cache add ca-certificates tzdata
RUN adduser -D -s /bin/sh appuser

ENV PORT=8080
EXPOSE 8080

WORKDIR /app
COPY --from=build /app/hugo-contact .
RUN chown appuser:appuser /app/hugo-contact

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:$PORT/form-token.js || exit 1

ENTRYPOINT ["./hugo-contact"]
