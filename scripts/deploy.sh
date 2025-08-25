#!/bin/bash

# Hugo Contact Form - Production Deployment Script
# This script is used by GitHub Actions for automated deployment
# It can also be run manually on the server for local deployments

set -e  # Exit on any error

# Configuration
ENVIRONMENT="${1:-production}"
DEPLOY_PATH="${2:-~/hugo-contact}"
BACKUP_KEEP_COUNT=3
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${2:-$BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    log "$1" "$RED"
    exit 1
}

success() {
    log "$1" "$GREEN"
}

warning() {
    log "$1" "$YELLOW"
}

# Check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
    fi
    
    log "Docker and Docker Compose are installed"
}

# Create backup of current deployment
create_backup() {
    log "Creating backup of current deployment..."
    
    BACKUP_DIR="${DEPLOY_PATH}/backups"
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "${DEPLOY_PATH}/docker-compose.build.yml" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_NAME="backup_${TIMESTAMP}"
        BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
        
        mkdir -p "$BACKUP_PATH"
        
        # Backup essential files
        for file in main.go go.mod go.sum Dockerfile docker-compose.build.yml .env manage-service.sh; do
            if [ -f "${DEPLOY_PATH}/${file}" ]; then
                cp "${DEPLOY_PATH}/${file}" "${BACKUP_PATH}/" 2>/dev/null || true
            fi
        done
        
        success "Backup created: ${BACKUP_NAME}"
        
        # Clean old backups (keep only last N backups)
        cd "$BACKUP_DIR"
        ls -t | tail -n +$((BACKUP_KEEP_COUNT + 1)) | xargs -r rm -rf
        cd "$DEPLOY_PATH"
        
        echo "$BACKUP_PATH"  # Return backup path for rollback
    else
        warning "No existing deployment to backup"
        echo ""
    fi
}

# Rollback to previous deployment
rollback() {
    local backup_path="$1"
    
    if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
        error "Cannot rollback: no backup available"
    fi
    
    warning "Rolling back to previous deployment..."
    
    # Stop current container
    docker-compose -f docker-compose.build.yml down 2>/dev/null || true
    
    # Restore files from backup
    cp -r "${backup_path}"/* "${DEPLOY_PATH}/"
    
    # Start previous version
    docker-compose -f docker-compose.build.yml up -d
    
    success "Rollback completed"
}

# Deploy new version
deploy() {
    log "Starting deployment for environment: ${ENVIRONMENT}"
    
    cd "$DEPLOY_PATH"
    
    # Extract deployment package if it exists
    if [ -f "deploy-package.tar.gz" ]; then
        log "Extracting deployment package..."
        tar -xzf deploy-package.tar.gz
        mv deploy-package/* .
        rm -rf deploy-package deploy-package.tar.gz
    fi
    
    # Make scripts executable
    chmod +x manage-service.sh 2>/dev/null || true
    
    # Validate required files
    for file in main.go Dockerfile docker-compose.build.yml; do
        if [ ! -f "$file" ]; then
            error "Required file missing: $file"
        fi
    done
    
    log "All required files present"
    
    # Stop existing container
    log "Stopping existing container..."
    docker-compose -f docker-compose.build.yml down 2>/dev/null || true
    
    # Build new image
    log "Building new Docker image..."
    if ! docker-compose -f docker-compose.build.yml build --no-cache; then
        error "Failed to build Docker image"
    fi
    
    success "Docker image built successfully"
    
    # Start new container
    log "Starting new container..."
    if ! docker-compose -f docker-compose.build.yml up -d; then
        error "Failed to start container"
    fi
    
    # Get port based on environment
    if [ "$ENVIRONMENT" = "production" ]; then
        HEALTH_PORT=8080
    else
        HEALTH_PORT=8081
    fi
    
    # Wait for service to be healthy
    log "Waiting for service to become healthy..."
    sleep 5  # Initial wait
    
    attempt=1
    while [ $attempt -le $HEALTH_CHECK_RETRIES ]; do
        if curl -f -s "http://localhost:${HEALTH_PORT}/health" > /dev/null 2>&1; then
            success "Service is healthy after $attempt attempts"
            break
        fi
        
        if curl -f -s "http://localhost:${HEALTH_PORT}/form-token.js" > /dev/null 2>&1; then
            success "Service is responding (token endpoint) after $attempt attempts"
            break
        fi
        
        log "Health check attempt $attempt/${HEALTH_CHECK_RETRIES}..."
        sleep $HEALTH_CHECK_INTERVAL
        ((attempt++))
    done
    
    if [ $attempt -gt $HEALTH_CHECK_RETRIES ]; then
        warning "Service failed to become healthy"
        
        # Show logs for debugging
        log "Recent container logs:"
        docker-compose -f docker-compose.build.yml logs --tail=50
        
        return 1
    fi
    
    return 0
}

# Clean up old Docker resources
cleanup() {
    log "Cleaning up old Docker resources..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove stopped containers older than 24 hours
    docker container prune -f --filter "until=24h"
    
    # Remove unused volumes (be careful with this)
    # docker volume prune -f
    
    success "Cleanup completed"
}

# Show deployment status
show_status() {
    log "Deployment Status:"
    
    # Container status
    if docker ps | grep -q "hugo-contact"; then
        success "Container: Running"
        
        # Get container details
        docker ps --filter "name=hugo-contact" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Memory and CPU usage
        docker stats --no-stream --filter "name=hugo-contact"
    else
        warning "Container: Not running"
    fi
    
    # Health check
    HEALTH_PORT=$([ "$ENVIRONMENT" = "production" ] && echo "8080" || echo "8081")
    if curl -f -s "http://localhost:${HEALTH_PORT}/health" > /dev/null 2>&1; then
        health_response=$(curl -s "http://localhost:${HEALTH_PORT}/health")
        success "Health Check: OK - ${health_response}"
    else
        warning "Health Check: Failed"
    fi
    
    # Disk usage
    log "Disk Usage:"
    df -h "$DEPLOY_PATH" | tail -1
    
    # Docker disk usage
    log "Docker Disk Usage:"
    docker system df
}

# Main execution
main() {
    log "Hugo Contact Form Deployment Script"
    log "Environment: ${ENVIRONMENT}"
    log "Deploy Path: ${DEPLOY_PATH}"
    
    # Check prerequisites
    check_docker
    
    # Create backup
    BACKUP_PATH=$(create_backup)
    
    # Deploy new version
    if deploy; then
        success "🎉 Deployment successful!"
        
        # Clean up old resources
        cleanup
        
        # Show final status
        show_status
        
        # Remove old backup if deployment was successful
        if [ -n "$BACKUP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
            rm -rf "${BACKUP_PATH}.old" 2>/dev/null || true
        fi
    else
        error_msg="Deployment failed!"
        
        # Attempt rollback if backup exists
        if [ -n "$BACKUP_PATH" ] && [ -d "$BACKUP_PATH" ]; then
            warning "Attempting rollback..."
            rollback "$BACKUP_PATH"
            error_msg="${error_msg} Rolled back to previous version."
        fi
        
        error "$error_msg"
    fi
}

# Run main function
main "$@"