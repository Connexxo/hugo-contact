#!/bin/bash

# Local build script for Hugo Contact HTTPS binary
# This helps you build the binary locally for testing

set -e

echo "🔨 Hugo Contact Form - Local Binary Builder"
echo "==========================================="
echo ""

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names
case $ARCH in
    x86_64)
        GOARCH="amd64"
        ;;
    aarch64|arm64)
        GOARCH="arm64"
        ;;
    *)
        GOARCH=$ARCH
        ;;
esac

# Function to build for current platform
build_local() {
    echo "📦 Building for current platform ($OS/$GOARCH)..."
    
    output_name="hugo-contact-https"
    if [ "$OS" = "windows" ]; then
        output_name="hugo-contact-https.exe"
    fi
    
    CGO_ENABLED=0 go build -ldflags="-w -s" -o $output_name main-https.go
    
    echo "✅ Built: $output_name"
    ls -lah $output_name
    file $output_name 2>/dev/null || true
}

# Function to build for Linux server deployment
build_linux() {
    echo "🐧 Building for Linux AMD64 (server deployment)..."
    
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build \
        -ldflags="-w -s" \
        -o hugo-contact-https-linux \
        main-https.go
    
    echo "✅ Built: hugo-contact-https-linux"
    ls -lah hugo-contact-https-linux
    file hugo-contact-https-linux 2>/dev/null || true
}

# Function to build for all platforms
build_all() {
    echo "🌍 Building for all platforms..."
    
    # Linux AMD64
    echo ""
    echo "→ Linux AMD64..."
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build \
        -ldflags="-w -s" \
        -o dist/hugo-contact-https-linux-amd64 \
        main-https.go
    
    # Linux ARM64
    echo "→ Linux ARM64..."
    GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build \
        -ldflags="-w -s" \
        -o dist/hugo-contact-https-linux-arm64 \
        main-https.go
    
    # macOS AMD64
    echo "→ macOS AMD64..."
    GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build \
        -ldflags="-w -s" \
        -o dist/hugo-contact-https-darwin-amd64 \
        main-https.go
    
    # macOS ARM64 (M1/M2)
    echo "→ macOS ARM64..."
    GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build \
        -ldflags="-w -s" \
        -o dist/hugo-contact-https-darwin-arm64 \
        main-https.go
    
    # Windows AMD64
    echo "→ Windows AMD64..."
    GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build \
        -ldflags="-w -s" \
        -o dist/hugo-contact-https-windows-amd64.exe \
        main-https.go
    
    echo ""
    echo "✅ All platforms built successfully!"
    echo ""
    echo "📁 Binaries in dist/ directory:"
    ls -lah dist/
}

# Function to create deployment package
create_package() {
    echo "📦 Creating deployment package..."
    
    # Build Linux binary first
    build_linux
    
    # Create deployment directory
    mkdir -p deployment
    
    # Copy binary
    cp hugo-contact-https-linux deployment/hugo-contact-https
    chmod +x deployment/hugo-contact-https
    
    # Copy scripts
    cp scripts/restart-contact-server.sh deployment/
    chmod +x deployment/restart-contact-server.sh
    
    # Copy environment template
    if [ -f .env.production.template ]; then
        cp .env.production.template deployment/
    fi
    
    # Create tar archive
    tar -czf hugo-contact-deployment.tar.gz deployment/
    
    echo "✅ Deployment package created: hugo-contact-deployment.tar.gz"
    echo ""
    echo "📋 Package contents:"
    tar -tzf hugo-contact-deployment.tar.gz
    echo ""
    echo "🚀 To deploy:"
    echo "  1. Upload hugo-contact-deployment.tar.gz to your server"
    echo "  2. Extract: tar -xzf hugo-contact-deployment.tar.gz"
    echo "  3. Configure: Edit .env.production with your settings"
    echo "  4. Run: sudo ./restart-contact-server.sh"
}

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Error: Go is not installed!"
    echo "Please install Go from: https://golang.org/dl/"
    exit 1
fi

# Check if main-https.go exists
if [ ! -f main-https.go ]; then
    echo "❌ Error: main-https.go not found!"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Create dist directory if building all
if [ "$1" = "all" ]; then
    mkdir -p dist
fi

# Parse command line arguments
case "${1:-local}" in
    local)
        build_local
        ;;
    linux)
        build_linux
        ;;
    all)
        build_all
        ;;
    package)
        create_package
        ;;
    *)
        echo "Usage: $0 {local|linux|all|package}"
        echo ""
        echo "Options:"
        echo "  local   - Build for current platform (default)"
        echo "  linux   - Build for Linux AMD64 (server deployment)"
        echo "  all     - Build for all platforms"
        echo "  package - Create deployment package with Linux binary"
        exit 1
        ;;
esac

echo ""
echo "💡 Tips:"
echo "  - For testing locally: ./$0 local"
echo "  - For server deployment: ./$0 linux"
echo "  - For distribution: ./$0 all"
echo "  - For complete package: ./$0 package"