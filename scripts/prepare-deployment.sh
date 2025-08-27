#!/bin/bash

# Hugo Contact Form - Deployment Package Preparation Script
# Run this locally to prepare files for FTP upload

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOY_PACKAGE_DIR="$PROJECT_ROOT/deploy-package"

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

# Create deployment package directory
create_package_dir() {
    print_status "Creating deployment package directory..."
    
    # Remove old package if exists
    if [ -d "$DEPLOY_PACKAGE_DIR" ]; then
        print_warning "Removing existing deployment package..."
        rm -rf "$DEPLOY_PACKAGE_DIR"
    fi
    
    mkdir -p "$DEPLOY_PACKAGE_DIR"
    print_status "Package directory created at: $DEPLOY_PACKAGE_DIR"
}

# Copy required files
copy_files() {
    print_status "Copying deployment files..."
    
    # Check if source files exist
    if [ ! -f "$PROJECT_ROOT/main-https.go" ]; then
        print_error "main-https.go not found in project root!"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/Dockerfile" ]; then
        print_error "Dockerfile not found in project root!"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/go.mod" ]; then
        print_error "go.mod not found in project root!"
        exit 1
    fi
    
    # Copy files
    cp "$PROJECT_ROOT/main-https.go" "$DEPLOY_PACKAGE_DIR/"
    cp "$PROJECT_ROOT/Dockerfile" "$DEPLOY_PACKAGE_DIR/"
    cp "$PROJECT_ROOT/go.mod" "$DEPLOY_PACKAGE_DIR/"
    
    # Create empty go.sum if it doesn't exist
    if [ -f "$PROJECT_ROOT/go.sum" ]; then
        cp "$PROJECT_ROOT/go.sum" "$DEPLOY_PACKAGE_DIR/"
    else
        touch "$DEPLOY_PACKAGE_DIR/go.sum"
    fi
    
    # Copy deployment script
    if [ -f "$SCRIPT_DIR/deploy-docker.sh" ]; then
        cp "$SCRIPT_DIR/deploy-docker.sh" "$DEPLOY_PACKAGE_DIR/"
        chmod +x "$DEPLOY_PACKAGE_DIR/deploy-docker.sh"
    fi
    
    print_status "Files copied to deployment package"
}

# Create deployment instructions
create_instructions() {
    print_status "Creating deployment instructions..."
    
    cat > "$DEPLOY_PACKAGE_DIR/DEPLOY-INSTRUCTIONS.txt" << 'EOF'
HUGO CONTACT FORM - DEPLOYMENT INSTRUCTIONS
===========================================

1. UPLOAD FILES VIA FTP
   Upload all files from this directory to:
   /home/k000490/www/12/htdocs/

   Files to upload:
   - Dockerfile
   - main-https.go
   - go.mod
   - go.sum
   - deploy-docker.sh (optional - for automated deployment)

2. CONNECT VIA SSH
   SSH into your server

3. AUTOMATED DEPLOYMENT (if deploy-docker.sh was uploaded)
   cd /home/k000490/www/12/htdocs/
   export SMTP_PASSWORD='your-smtp-password'
   chmod +x deploy-docker.sh
   ./deploy-docker.sh

4. MANUAL DEPLOYMENT
   If not using the script, run these commands:

   # Navigate to deployment directory
   cd /home/k000490/www/12/htdocs/

   # Build Docker image
   docker build -t hugo-contact:latest .

   # Stop and remove existing container (if any)
   docker stop hugo-contact-prod 2>/dev/null || true
   docker rm hugo-contact-prod 2>/dev/null || true

   # Run new container
   docker run -d \
     --name hugo-contact-prod \
     --restart unless-stopped \
     -p 8080:8080 \
     -e PORT=8080 \
     -e CORS_ALLOW_ORIGINS=https://connexxo.com,http://connexxo.com,https://contact.connexxo.com,http://contact.connexxo.com \
     -e SMTP_HOST=mail23.hi7.de \
     -e SMTP_PORT=587 \
     -e SMTP_USERNAME=k000490-017 \
     -e SMTP_PASSWORD='your-smtp-password' \
     -e SENDER_EMAIL=system@connexxo.com \
     -e RECIPIENT_EMAIL=info@connexxo.com \
     -e TOKEN_SECRET='your-secret-token' \
     hugo-contact:latest

   # Create .htaccess for routing
   cat > .htaccess << 'HTACCESS'
RewriteEngine On
RewriteRule ^(.*)$ http://localhost:8080/$1 [P,L]
HTACCESS

   # Clean up build files
   rm -f Dockerfile main-https.go go.mod go.sum deploy-docker.sh

5. TEST THE DEPLOYMENT
   curl http://localhost:8080/health
   
   Should return: {"status":"healthy","service":"hugo-contact","timestamp":"..."}

6. VERIFY EXTERNAL ACCESS
   Visit: http://contact.connexxo.com/health

TROUBLESHOOTING
===============
- Check logs: docker logs hugo-contact-prod --tail 50
- Restart container: docker restart hugo-contact-prod
- Check status: docker ps | grep hugo-contact-prod

IMPORTANT
=========
Remember to set your SMTP_PASSWORD before running the container!
EOF
    
    print_status "Deployment instructions created"
}

# Create environment template
create_env_template() {
    print_status "Creating environment template..."
    
    cat > "$DEPLOY_PACKAGE_DIR/.env.template" << 'EOF'
# Hugo Contact Form - Environment Variables Template
# Copy this to .env and fill in your values

# SMTP Configuration
SMTP_HOST=mail23.hi7.de
SMTP_PORT=587
SMTP_USERNAME=k000490-017
SMTP_PASSWORD=your-smtp-password-here

# Email Configuration
SENDER_EMAIL=system@connexxo.com
RECIPIENT_EMAIL=info@connexxo.com

# Security
TOKEN_SECRET=generate-a-random-32-character-string-here

# CORS Configuration (comma-separated)
CORS_ORIGINS=https://connexxo.com,http://connexxo.com,https://contact.connexxo.com,http://contact.connexxo.com

# Server Configuration
PORT=8080
EOF
    
    print_status "Environment template created"
}

# Show package contents
show_package() {
    echo ""
    print_status "Deployment package created successfully!"
    echo ""
    echo "Package location: $DEPLOY_PACKAGE_DIR"
    echo ""
    echo "Package contents:"
    ls -la "$DEPLOY_PACKAGE_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Review the files in $DEPLOY_PACKAGE_DIR"
    echo "2. Upload them to your server via FTP"
    echo "3. Follow the instructions in DEPLOY-INSTRUCTIONS.txt"
    echo ""
    print_warning "Remember to set your SMTP_PASSWORD before deploying!"
}

# Main function
main() {
    echo "=============================================="
    echo "Hugo Contact Form - Deployment Package Creator"
    echo "=============================================="
    echo ""
    
    create_package_dir
    copy_files
    create_instructions
    create_env_template
    show_package
}

# Run main function
main