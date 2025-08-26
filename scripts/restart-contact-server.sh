#!/bin/bash

# Hugo Contact Form HTTPS Restart Script
# This script manages the Hugo Contact Form server running on HTTPS port 443

set -e

echo "🔄 Hugo Contact Form HTTPS Server Management"
echo "============================================"
echo ""

# Check if running as root (needed for port 443)
if [ "$EUID" -ne 0 ] && [ "$1" != "status" ]; then 
   echo "❌ Error: This script needs sudo privileges to bind to port 443"
   echo "Please run: sudo $0"
   exit 1
fi

# Function to load environment variables
load_env() {
    if [ -f .env.production ]; then
        export $(cat .env.production | grep -v '^#' | xargs)
        echo "✅ Environment variables loaded from .env.production"
    elif [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        echo "✅ Environment variables loaded from .env"
    else
        echo "⚠️  Warning: No .env file found, using system environment"
    fi
}

# Function to stop the server
stop_server() {
    echo "🛑 Stopping existing Hugo Contact server..."
    
    # Find and kill existing process
    if pgrep -f hugo-contact-https > /dev/null; then
        pkill -f hugo-contact-https
        echo "✅ Stopped existing process"
        sleep 2
    else
        echo "ℹ️  No existing process found"
    fi
}

# Function to start the server
start_server() {
    echo "🚀 Starting Hugo Contact HTTPS server..."
    
    # Load environment
    load_env
    
    # Check if binary exists
    if [ ! -f ./hugo-contact-https ]; then
        echo "❌ Error: hugo-contact-https binary not found!"
        echo "Please ensure the binary is in the current directory"
        exit 1
    fi
    
    # Make sure binary is executable
    chmod +x hugo-contact-https
    
    # Check SSL certificates
    if [ -z "$SSL_CERT_PATH" ] || [ -z "$SSL_KEY_PATH" ]; then
        echo "❌ Error: SSL_CERT_PATH and SSL_KEY_PATH must be set!"
        exit 1
    fi
    
    if [ ! -f "$SSL_CERT_PATH" ]; then
        echo "❌ Error: SSL certificate not found at: $SSL_CERT_PATH"
        exit 1
    fi
    
    if [ ! -f "$SSL_KEY_PATH" ]; then
        echo "❌ Error: SSL key not found at: $SSL_KEY_PATH"
        exit 1
    fi
    
    # Start server in background
    nohup ./hugo-contact-https > hugo-contact.log 2>&1 &
    
    echo "⏳ Waiting for server to start..."
    sleep 3
    
    # Verify it's running
    if pgrep -f hugo-contact-https > /dev/null; then
        echo "✅ Server started successfully!"
        echo "📝 PID: $(pgrep -f hugo-contact-https)"
        
        # Test health endpoint
        echo ""
        echo "🔍 Testing health endpoint..."
        if curl -k -s -f https://localhost:${PORT:-443}/health > /dev/null 2>&1; then
            health_response=$(curl -k -s https://localhost:${PORT:-443}/health)
            echo "✅ Health check passed: $health_response"
        else
            echo "⚠️  Health check failed - server may still be starting"
            echo "Check logs: tail -f hugo-contact.log"
        fi
    else
        echo "❌ Failed to start server!"
        echo "Check logs for errors:"
        tail -20 hugo-contact.log
        exit 1
    fi
}

# Function to check status
check_status() {
    echo "📊 Server Status"
    echo "---------------"
    
    if pgrep -f hugo-contact-https > /dev/null; then
        echo "✅ Status: RUNNING"
        echo "📝 PID: $(pgrep -f hugo-contact-https)"
        echo ""
        
        # Load env for port info
        load_env > /dev/null 2>&1
        PORT=${PORT:-443}
        
        # Test endpoints
        echo "🔍 Endpoint Tests:"
        
        # Health check
        if curl -k -s -f https://localhost:${PORT}/health > /dev/null 2>&1; then
            echo "  ✅ Health endpoint: OK"
        else
            echo "  ❌ Health endpoint: FAILED"
        fi
        
        # Token endpoint
        if curl -k -s -f https://localhost:${PORT}/form-token.js > /dev/null 2>&1; then
            echo "  ✅ Token endpoint: OK"
        else
            echo "  ❌ Token endpoint: FAILED"
        fi
        
        # External check
        if [ ! -z "$EXTERNAL_URL" ]; then
            if curl -s -f ${EXTERNAL_URL}/health > /dev/null 2>&1; then
                echo "  ✅ External access: OK"
            else
                echo "  ⚠️  External access: NOT ACCESSIBLE"
            fi
        fi
        
        echo ""
        echo "📝 Recent logs:"
        tail -5 hugo-contact.log 2>/dev/null || echo "  No logs available"
    else
        echo "❌ Status: STOPPED"
        echo ""
        echo "To start the server, run:"
        echo "  sudo $0 start"
    fi
}

# Function to show logs
show_logs() {
    if [ -f hugo-contact.log ]; then
        echo "📝 Showing last 50 lines of logs:"
        echo "=================================="
        tail -50 hugo-contact.log
        echo ""
        echo "💡 To follow logs in real-time: tail -f hugo-contact.log"
    else
        echo "❌ No log file found"
    fi
}

# Main command handling
case "${1:-restart}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        echo "✅ Server stopped"
        ;;
    restart)
        stop_server
        start_server
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the server"
        echo "  stop    - Stop the server"
        echo "  restart - Restart the server (default)"
        echo "  status  - Check server status"
        echo "  logs    - Show recent logs"
        exit 1
        ;;
esac

echo ""
echo "🎉 Done!"
echo ""
echo "📍 HTTPS Endpoints:"
echo "   https://contact.connexxo.com/health"
echo "   https://contact.connexxo.com/f/contact"
echo "   https://contact.connexxo.com/form-token.js"