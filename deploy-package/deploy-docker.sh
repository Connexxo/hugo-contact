#!/bin/bash

# Hugo Contact Form - Docker Deployment Script
# This script automates the deployment process for the Hugo Contact Form service

set -e  # Exit on error

# Configuration
DEPLOY_DIR="/home/k000490/www/12/htdocs"
CONTAINER_NAME="hugo-contact-prod"
IMAGE_NAME="hugo-contact:latest"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running on server
check_environment() {
    print_status "Checking environment..."
    
    if [ ! -d "$DEPLOY_DIR" ]; then
        print_error "Deploy directory $DEPLOY_DIR not found!"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        exit 1
    fi
    
    print_status "Environment check passed"
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    
    cd "$DEPLOY_DIR"
    
    # Check if required files exist
    if [ ! -f "Dockerfile" ] || [ ! -f "main-https.go" ] || [ ! -f "spam_logger.go" ] || [ ! -f "go.mod" ]; then
        print_error "Required build files not found in $DEPLOY_DIR"
        print_warning "Please upload: Dockerfile, main-https.go, spam_logger.go, go.mod, go.sum"
        exit 1
    fi
    
    docker build -t "$IMAGE_NAME" .
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
}

# Stop and remove existing container
cleanup_container() {
    print_status "Checking for existing container..."
    
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        print_warning "Found existing container, stopping and removing..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        print_status "Existing container removed"
    else
        print_status "No existing container found"
    fi
}

# Run new container
run_container() {
    print_status "Starting new container..."
    
    # Check for environment variables or use defaults
    SMTP_HOST="${SMTP_HOST:-mail23.hi7.de}"
    SMTP_PORT="${SMTP_PORT:-587}"
    SMTP_USERNAME="${SMTP_USERNAME:-k000490-017}"
    SMTP_PASSWORD="${SMTP_PASSWORD}"
    SENDER_EMAIL="${SENDER_EMAIL:-system@connexxo.com}"
    RECIPIENT_EMAIL="${RECIPIENT_EMAIL:-info@connexxo.com}"
    TOKEN_SECRET="${TOKEN_SECRET:-$(openssl rand -base64 32)}"
    CORS_ORIGINS="${CORS_ORIGINS:-https://connexxo.com,http://connexxo.com,https://contact.connexxo.com,http://contact.connexxo.com}"
    
    # Spam logging configuration
    SPAM_LOG_ENABLED="${SPAM_LOG_ENABLED:-false}"
    SPAM_REPORT_ENABLED="${SPAM_REPORT_ENABLED:-false}"
    SPAM_REPORT_RECIPIENT="${SPAM_REPORT_RECIPIENT:-$RECIPIENT_EMAIL}"
    
    # Create log directory on host if spam logging is enabled
    if [ "$SPAM_LOG_ENABLED" = "true" ]; then
        mkdir -p "/var/log/hugo-contact"
        print_status "Created spam log directory: /var/log/hugo-contact"
    fi
    
    if [ -z "$SMTP_PASSWORD" ]; then
        print_error "SMTP_PASSWORD environment variable is required!"
        print_warning "Set it with: export SMTP_PASSWORD='your-password'"
        exit 1
    fi
    
    # Build volume mount arguments for spam logging
    VOLUME_ARGS=""
    if [ "$SPAM_LOG_ENABLED" = "true" ]; then
        VOLUME_ARGS="-v /var/log/hugo-contact:/var/log/hugo-contact"
    fi
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 8080:8080 \
        $VOLUME_ARGS \
        -e PORT=8080 \
        -e "CORS_ALLOW_ORIGINS=$CORS_ORIGINS" \
        -e "SMTP_HOST=$SMTP_HOST" \
        -e "SMTP_PORT=$SMTP_PORT" \
        -e "SMTP_USERNAME=$SMTP_USERNAME" \
        -e "SMTP_PASSWORD=$SMTP_PASSWORD" \
        -e "SENDER_EMAIL=$SENDER_EMAIL" \
        -e "RECIPIENT_EMAIL=$RECIPIENT_EMAIL" \
        -e "TOKEN_SECRET=$TOKEN_SECRET" \
        -e "SPAM_LOG_ENABLED=$SPAM_LOG_ENABLED" \
        -e "SPAM_REPORT_ENABLED=$SPAM_REPORT_ENABLED" \
        -e "SPAM_REPORT_RECIPIENT=$SPAM_REPORT_RECIPIENT" \
        "$IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        print_status "Container started successfully"
    else
        print_error "Failed to start container"
        exit 1
    fi
}

# Setup Apache routing
setup_routing() {
    print_status "Setting up Apache routing..."
    
    HTACCESS_FILE="$DEPLOY_DIR/.htaccess"
    
    cat > "$HTACCESS_FILE" << 'EOF'
RewriteEngine On
RewriteRule ^(.*)$ http://localhost:8080/$1 [P,L]
EOF
    
    if [ -f "$HTACCESS_FILE" ]; then
        print_status ".htaccess file created successfully"
    else
        print_error "Failed to create .htaccess file"
        exit 1
    fi
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Wait for container to be ready
    sleep 3
    
    # Test health endpoint
    if curl -s http://localhost:8080/health | grep -q "healthy"; then
        print_status "Health check passed"
    else
        print_error "Health check failed"
        print_warning "Check logs with: docker logs $CONTAINER_NAME"
        exit 1
    fi
    
    # Test token endpoint
    if curl -s http://localhost:8080/form-token.js | grep -q "function"; then
        print_status "Token generation working"
    else
        print_error "Token generation test failed"
    fi
}

# Clean up build files
cleanup_files() {
    print_status "Cleaning up build files..."
    
    cd "$DEPLOY_DIR"
    rm -f Dockerfile main-https.go go.mod go.sum
    
    print_status "Build files removed for security"
}

# Show status
show_status() {
    echo ""
    print_status "Deployment completed successfully!"
    echo ""
    echo "Container Status:"
    docker ps | grep "$CONTAINER_NAME" | head -1
    echo ""
    echo "Test URLs:"
    echo "  - Health: http://contact.connexxo.com/health"
    echo "  - Token:  http://contact.connexxo.com/form-token.js"
    echo "  - Form:   http://contact.connexxo.com/f/contact"
    echo ""
    echo "View logs with: docker logs $CONTAINER_NAME --tail 50"
}

# Main deployment flow
main() {
    echo "======================================"
    echo "Hugo Contact Form - Docker Deployment"
    echo "======================================"
    echo ""
    
    check_environment
    build_image
    cleanup_container
    run_container
    setup_routing
    test_deployment
    cleanup_files
    show_status
}

# Run main function
main