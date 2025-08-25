#!/bin/bash

# Hugo Contact Form Service Management Script
# Usage: ./manage-service.sh [start|stop|restart|update|status|logs]

COMPOSE_FILE="docker-compose.build.yml"
SERVICE_NAME="hugo-contact-prod"
LOG_FILE="service-management.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
    echo -e "$1"
}

# Check if docker-compose file exists
check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        log "${RED}❌ Docker Compose file $COMPOSE_FILE not found!${NC}"
        exit 1
    fi
}

# Start service
start_service() {
    log "${BLUE}🚀 Starting Hugo Contact Form service...${NC}"
    check_compose_file
    
    docker-compose -f $COMPOSE_FILE up -d
    if [ $? -eq 0 ]; then
        sleep 3
        if check_health; then
            log "${GREEN}✅ Service started successfully${NC}"
        else
            log "${YELLOW}⚠️  Service started but health check failed${NC}"
        fi
    else
        log "${RED}❌ Failed to start service${NC}"
        exit 1
    fi
}

# Stop service
stop_service() {
    log "${BLUE}🛑 Stopping Hugo Contact Form service...${NC}"
    check_compose_file
    
    docker-compose -f $COMPOSE_FILE down
    if [ $? -eq 0 ]; then
        log "${GREEN}✅ Service stopped successfully${NC}"
    else
        log "${RED}❌ Failed to stop service${NC}"
        exit 1
    fi
}

# Restart service
restart_service() {
    log "${BLUE}🔄 Restarting Hugo Contact Form service...${NC}"
    stop_service
    sleep 2
    start_service
}

# Update service (rebuild and restart)
update_service() {
    log "${BLUE}🔧 Updating Hugo Contact Form service...${NC}"
    check_compose_file
    
    # Stop current service
    log "${BLUE}🛑 Stopping current service...${NC}"
    docker-compose -f $COMPOSE_FILE down
    
    # Rebuild image
    log "${BLUE}🏗️  Rebuilding Docker image...${NC}"
    docker-compose -f $COMPOSE_FILE build --no-cache
    if [ $? -ne 0 ]; then
        log "${RED}❌ Failed to rebuild image${NC}"
        exit 1
    fi
    
    # Start updated service
    log "${BLUE}🚀 Starting updated service...${NC}"
    docker-compose -f $COMPOSE_FILE up -d
    if [ $? -eq 0 ]; then
        sleep 5
        if check_health; then
            log "${GREEN}✅ Service updated and running successfully${NC}"
            show_status
        else
            log "${YELLOW}⚠️  Service updated but health check failed${NC}"
            show_logs_tail
        fi
    else
        log "${RED}❌ Failed to start updated service${NC}"
        exit 1
    fi
}

# Check service health
check_health() {
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
            return 0
        fi
        
        if curl -f -s http://localhost:8080/form-token.js > /dev/null 2>&1; then
            return 0
        fi
        
        log "${YELLOW}⏳ Health check attempt $attempt/$max_attempts...${NC}"
        sleep 2
        ((attempt++))
    done
    
    return 1
}

# Show service status
show_status() {
    log "${BLUE}📊 Service Status:${NC}"
    
    # Container status
    if docker ps | grep -q $SERVICE_NAME; then
        log "${GREEN}✅ Container: Running${NC}"
        
        # Health check
        if curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
            health_data=$(curl -s http://localhost:8080/health 2>/dev/null)
            log "${GREEN}✅ Health: OK - $health_data${NC}"
        elif curl -f -s http://localhost:8080/form-token.js > /dev/null 2>&1; then
            log "${GREEN}✅ Service: Responding (token endpoint)${NC}"
        else
            log "${RED}❌ Health: Service not responding${NC}"
        fi
        
        # Port check
        if netstat -tuln 2>/dev/null | grep -q ":8080 " || ss -tuln 2>/dev/null | grep -q ":8080 "; then
            log "${GREEN}✅ Port 8080: Listening${NC}"
        else
            log "${YELLOW}⚠️  Port 8080: Not detected${NC}"
        fi
        
    else
        log "${RED}❌ Container: Not running${NC}"
    fi
    
    # Show container details
    echo ""
    docker-compose -f $COMPOSE_FILE ps
}

# Show recent logs
show_logs() {
    log "${BLUE}📋 Recent logs (last 50 lines):${NC}"
    docker-compose -f $COMPOSE_FILE logs --tail=50
}

# Show logs tail (for troubleshooting)
show_logs_tail() {
    log "${BLUE}📋 Last 10 log entries:${NC}"
    docker-compose -f $COMPOSE_FILE logs --tail=10
}

# Follow logs
follow_logs() {
    log "${BLUE}📋 Following logs (Ctrl+C to exit):${NC}"
    docker-compose -f $COMPOSE_FILE logs -f
}

# Show usage
show_usage() {
    echo "Hugo Contact Form Service Management"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start the service"
    echo "  stop      Stop the service"
    echo "  restart   Restart the service"
    echo "  update    Stop, rebuild, and start (full update)"
    echo "  status    Show service status"
    echo "  logs      Show recent logs"
    echo "  follow    Follow logs in real-time"
    echo "  health    Check service health"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 update"
    echo "  $0 status"
    echo "  $0 logs"
}

# Parse command
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    update)
        update_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    follow)
        follow_logs
        ;;
    health)
        if check_health; then
            log "${GREEN}✅ Service is healthy${NC}"
        else
            log "${RED}❌ Service health check failed${NC}"
            exit 1
        fi
        ;;
    *)
        show_usage
        exit 1
        ;;
esac