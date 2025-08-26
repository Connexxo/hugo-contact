#!/bin/bash

# Hugo Contact Form Docker Management Script
# Enhanced automation for container management

set -e

CONTAINER_NAME="hugo-contact-prod"
IMAGE_NAME="hugo-contact-app-hugo-contact:latest"
PORT="8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Health check function
health_check() {
    local max_attempts=10
    local attempt=1
    
    log "${BLUE}🏥 Performing health check...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:$PORT/health > /dev/null 2>&1; then
            health_data=$(curl -s http://localhost:$PORT/health)
            log "${GREEN}✅ Health check passed: $health_data${NC}"
            return 0
        fi
        
        log "${YELLOW}⏳ Health check attempt $attempt/$max_attempts...${NC}"
        sleep 3
        ((attempt++))
    done
    
    log "${RED}❌ Health check failed after $max_attempts attempts${NC}"
    return 1
}

# Start container
start_container() {
    log "${BLUE}🚀 Starting Hugo Contact Form container...${NC}"
    
    # Check if container already exists and is running
    if docker ps | grep -q $CONTAINER_NAME; then
        log "${YELLOW}⚠️  Container is already running${NC}"
        return 0
    fi
    
    # Remove existing stopped container if it exists
    if docker ps -a | grep -q $CONTAINER_NAME; then
        log "${BLUE}🧹 Removing existing stopped container...${NC}"
        docker rm $CONTAINER_NAME
    fi
    
    # Check if image exists
    if ! docker images | grep -q hugo-contact-app-hugo-contact; then
        log "${RED}❌ Docker image not found! Please build it first.${NC}"
        log "${BLUE}💡 Run: docker-compose -f docker-compose.build.yml build${NC}"
        exit 1
    fi
    
    # Load environment variables from .env if it exists
    ENV_ARGS=""
    if [ -f .env ]; then
        log "${BLUE}📋 Loading environment from .env file...${NC}"
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $line ]]; then
                continue
            fi
            # Add -e flag for each environment variable
            ENV_ARGS="$ENV_ARGS -e $line"
        done < .env
    else
        log "${YELLOW}⚠️  No .env file found, using minimal configuration${NC}"
        ENV_ARGS="-e PORT=$PORT"
    fi
    
    # Start container
    log "${BLUE}🚀 Starting new container...${NC}"
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p $PORT:$PORT \
        $ENV_ARGS \
        $IMAGE_NAME
    
    # Wait for container to initialize
    sleep 5
    
    # Verify container started
    if docker ps | grep -q $CONTAINER_NAME; then
        log "${GREEN}✅ Container started successfully!${NC}"
        health_check
    else
        log "${RED}❌ Container failed to start!${NC}"
        log "${BLUE}📋 Container logs:${NC}"
        docker logs $CONTAINER_NAME || true
        exit 1
    fi
}

# Stop container
stop_container() {
    log "${BLUE}🛑 Stopping Hugo Contact Form container...${NC}"
    
    if docker ps | grep -q $CONTAINER_NAME; then
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
        log "${GREEN}✅ Container stopped and removed${NC}"
    else
        log "${YELLOW}⚠️  Container is not running${NC}"
    fi
}

# Restart container
restart_container() {
    log "${BLUE}🔄 Restarting Hugo Contact Form container...${NC}"
    stop_container
    sleep 2
    start_container
}

# Update container (rebuild and restart)
update_container() {
    log "${BLUE}🔧 Updating Hugo Contact Form container...${NC}"
    
    # Stop current container
    stop_container
    
    # Clean up old images
    log "${BLUE}🧹 Cleaning up old images...${NC}"
    docker image prune -f
    
    # Rebuild image
    log "${BLUE}🏗️  Rebuilding Docker image...${NC}"
    if [ -f docker-compose.build.yml ]; then
        docker-compose -f docker-compose.build.yml build --no-cache
    else
        docker build -t $IMAGE_NAME .
    fi
    
    # Start updated container
    start_container
    
    log "${GREEN}🎉 Container updated successfully!${NC}"
    show_status
}

# Show container status
show_status() {
    log "${BLUE}📊 Hugo Contact Form Status:${NC}"
    
    # Container status
    if docker ps | grep -q $CONTAINER_NAME; then
        log "${GREEN}✅ Container: Running${NC}"
        
        # Show container details
        docker ps | grep $CONTAINER_NAME | awk '{print "   ID: " $1 "  Status: " $7 "  Ports: " $6}'
        
        # Health check
        if health_check; then
            log "${GREEN}✅ Service: Healthy${NC}"
        else
            log "${RED}❌ Service: Unhealthy${NC}"
        fi
        
        # Port check
        if netstat -tuln 2>/dev/null | grep -q ":$PORT " || ss -tuln 2>/dev/null | grep -q ":$PORT "; then
            log "${GREEN}✅ Port $PORT: Listening${NC}"
        else
            log "${YELLOW}⚠️  Port $PORT: Not detected${NC}"
        fi
        
    else
        log "${RED}❌ Container: Not running${NC}"
        
        # Check if stopped container exists
        if docker ps -a | grep -q $CONTAINER_NAME; then
            log "${YELLOW}⚠️  Stopped container exists${NC}"
        fi
    fi
    
    # Show images
    log "${BLUE}📦 Images:${NC}"
    docker images | grep hugo-contact || log "${YELLOW}⚠️  No hugo-contact images found${NC}"
}

# Show logs
show_logs() {
    local lines=${1:-50}
    log "${BLUE}📋 Container logs (last $lines lines):${NC}"
    
    if docker ps -a | grep -q $CONTAINER_NAME; then
        docker logs --tail=$lines $CONTAINER_NAME
    else
        log "${RED}❌ Container not found${NC}"
    fi
}

# Follow logs
follow_logs() {
    log "${BLUE}📋 Following container logs (Ctrl+C to exit):${NC}"
    
    if docker ps | grep -q $CONTAINER_NAME; then
        docker logs -f $CONTAINER_NAME
    else
        log "${RED}❌ Container is not running${NC}"
        exit 1
    fi
}

# Cleanup old images and containers
cleanup() {
    log "${BLUE}🧹 Cleaning up Docker resources...${NC}"
    
    # Remove stopped containers
    stopped_containers=$(docker ps -a -q -f status=exited)
    if [ ! -z "$stopped_containers" ]; then
        log "${BLUE}🗑️  Removing stopped containers...${NC}"
        docker rm $stopped_containers
    fi
    
    # Remove dangling images
    log "${BLUE}🗑️  Removing dangling images...${NC}"
    docker image prune -f
    
    # Remove old hugo-contact images (keep latest)
    old_images=$(docker images hugo-contact-app-hugo-contact --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | tail -n +2 | head -n -1 | awk '{print $3}')
    if [ ! -z "$old_images" ]; then
        log "${BLUE}🗑️  Removing old hugo-contact images...${NC}"
        echo "$old_images" | xargs -r docker rmi || true
    fi
    
    log "${GREEN}✅ Cleanup completed${NC}"
    
    # Show disk usage
    log "${BLUE}💾 Disk usage:${NC}"
    docker system df
}

# Show usage
show_usage() {
    echo "Hugo Contact Form Docker Management"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start     Start the container"
    echo "  stop      Stop the container"
    echo "  restart   Restart the container"
    echo "  update    Stop, rebuild, and start (full update)"
    echo "  status    Show container status"
    echo "  logs      Show recent logs (default: 50 lines)"
    echo "  follow    Follow logs in real-time"
    echo "  health    Check service health"
    echo "  cleanup   Clean up old containers and images"
    echo ""
    echo "Options:"
    echo "  logs [N]  Show last N lines of logs"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 update"
    echo "  $0 logs 100"
    echo "  $0 status"
}

# Parse command
case "$1" in
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        restart_container
        ;;
    update)
        update_container
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs ${2:-50}
        ;;
    follow)
        follow_logs
        ;;
    health)
        if health_check; then
            exit 0
        else
            exit 1
        fi
        ;;
    cleanup)
        cleanup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac