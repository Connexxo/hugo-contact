#!/bin/bash

# Quick Status Check Script
# Run this on your server or remotely

echo "🔍 Hugo Contact Form Status Check"
echo "=================================="
echo ""

# Test health endpoint
echo "🏥 Health Check:"
if curl -s -f http://contact.connexxo.com:8080/health > /dev/null 2>&1; then
    health_data=$(curl -s http://contact.connexxo.com:8080/health)
    echo "✅ HEALTHY - $health_data"
else
    echo "❌ FAILED - Service not responding"
fi

echo ""

# Test token endpoint
echo "🎫 Token Endpoint:"
if curl -s -f http://contact.connexxo.com:8080/form-token.js > /dev/null 2>&1; then
    echo "✅ WORKING - JavaScript token endpoint active"
else
    echo "❌ FAILED - Token endpoint not responding"
fi

echo ""

# Test CORS
echo "🔒 CORS Check:"
if curl -s -o /dev/null -w "%{http_code}" -H "Origin: https://connexxo.com" -X OPTIONS http://contact.connexxo.com:8080/f/contact | grep -q "204\|200"; then
    echo "✅ CONFIGURED - CORS headers working"
else
    echo "❌ FAILED - CORS configuration issue"
fi

echo ""
echo "📊 Container Status:"
if command -v docker &> /dev/null; then
    if docker ps | grep -q hugo-contact-prod; then
        echo "✅ RUNNING - Docker container active"
    else
        echo "❌ STOPPED - Docker container not running"
    fi
else
    echo "⚠️  Docker not available - cannot check container status"
fi

echo ""
echo "⏰ Checked at: $(date)"
echo ""
echo "💡 To fix issues, run: ./manage-service.sh restart"