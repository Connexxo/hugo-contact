#!/bin/bash

# Hugo Contact Form - Daily Spam Report Script
# This script is designed to be run as a cron job to send daily spam reports
# 
# Example cron entry (runs daily at 9 AM):
# 0 9 * * * /path/to/send-spam-report.sh >> /var/log/hugo-contact/spam-report-cron.log 2>&1

# Exit on error
set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables if .env file exists
if [ -f "$PROJECT_DIR/.env.production" ]; then
    export $(cat "$PROJECT_DIR/.env.production" | grep -v '^#' | xargs)
elif [ -f "$PROJECT_DIR/.env" ]; then
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
fi

# Log start time
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting spam report generation..."

# Check if spam reporting is enabled
if [ "$SPAM_REPORT_ENABLED" != "true" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Spam reporting is disabled (SPAM_REPORT_ENABLED != true)"
    exit 0
fi

# Check if running inside Docker container or on host
if [ -f "/app/bin/spam-report" ]; then
    # Running inside Docker container
    SPAM_REPORT_BINARY="/app/bin/spam-report"
else
    # Running on host - build if needed
    SPAM_REPORT_BINARY="$PROJECT_DIR/bin/spam-report"
    if [ ! -f "$SPAM_REPORT_BINARY" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Building spam report tool..."
        cd "$PROJECT_DIR"
        go build -o "$SPAM_REPORT_BINARY" ./cmd/spam-report/main.go
    fi
fi

# Run the spam report generator
if [ -f "$SPAM_REPORT_BINARY" ]; then
    "$SPAM_REPORT_BINARY"
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Spam report completed successfully"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Spam report failed with exit code: $EXIT_CODE"
        exit $EXIT_CODE
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: Spam report binary not found at $SPAM_REPORT_BINARY"
    exit 1
fi

# Optional: Clean up old logs (older than retention period)
if [ -n "$SPAM_LOG_DIR" ] && [ -d "$SPAM_LOG_DIR" ]; then
    RETENTION_DAYS="${SPAM_LOG_RETENTION_DAYS:-10}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up logs older than $RETENTION_DAYS days..."
    find "$SPAM_LOG_DIR" -name "spam-*.jsonl*" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Spam report script completed"