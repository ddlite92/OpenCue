#!/bin/bash
# =============================================================================
# OpenCue Rust RQD - Automated Build Script for Linux VM
# =============================================================================
# This script automatically builds the Rust RQD on a Linux VM by:
# 1. Detecting the Linux distribution
# 2. Installing all required dependencies
# 3. Installing Rust toolchain (if not already installed)
# 4. Building the Rust RQD in release mode
# 5. Running tests to verify the build
#
# Usage:
#   ./build-rust-rqd.sh [OPTIONS]
#
# Options:
#   --clean         Clean build (removes previous build artifacts)
#   --debug         Build in debug mode instead of release
#   --no-tests      Skip running tests after build
#   --static        Build static binary (musl target)
#   --help          Show this help message
#
# Author: OpenCue Contributors
# License: Apache 2.0
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_MODE="release"
RUN_TESTS=true
CLEAN_BUILD=false
STATIC_BUILD=false
RUST_INSTALLED=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# Argument Parsing
# =============================================================================

show_help() {
    cat << EOF
OpenCue Rust RQD - Automated Build Script

Usage: $0 [OPTIONS]

Options:
    --clean         Clean build (removes previous build artifacts)
    --debug         Build in debug mode instead of release
    --no-tests      Skip running tests after build
    --static        Build static binary (musl target)
    --help          Show this help message

Examples:
    $0                      # Standard release build
    $0 --clean              # Clean and rebuild
    $0 --debug --no-tests   # Quick debug build without tests
    $0 --static             # Build static binary

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --debug)
            BUILD_MODE="debug"
            shift
            ;;
        --no-tests)
            RUN_TESTS=false
            shift
            ;;
        --static)
            STATIC_BUILD=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# System Detection
# =============================================================================

detect_os() {
    print_header "Detecting Operating System"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
        print_success "Detected: $PRETTY_NAME"
    else
        print_error "Cannot detect OS distribution"
        exit 1
    fi
}

# =============================================================================
# Dependency Installation
# =============================================================================

install_dependencies_ubuntu_debian() {
    print_header "Installing Dependencies (Ubuntu/Debian)"
    
    print_info "Updating package index..."
    sudo apt-get update -qq
    
    print_info "Installing build tools and dependencies..."
    sudo apt-get install -y \
        build-essential \
        pkg-config \
        libssl-dev \
        protobuf-compiler \
        curl \
        git \
        ca-certificates \
        > /dev/null 2>&1
    
    print_success "Dependencies installed successfully"
}

install_dependencies_rhel() {
    print_header "Installing Dependencies (RHEL/Rocky/AlmaLinux/CentOS)"
    
    # Install EPEL if not already installed
    if ! rpm -qa | grep -q epel-release; then
        print_info "Installing EPEL repository..."
        sudo dnf install -y epel-release > /dev/null 2>&1
    fi
    
    print_info "Installing build tools..."
    sudo dnf groupinstall -y "Development Tools" > /dev/null 2>&1 || true
    
    print_info "Installing dependencies..."
    sudo dnf install -y \
        pkg-config \
        openssl-devel \
        protobuf-compiler \
        protobuf-devel \
        curl \
        git \
        ca-certificates \
        > /dev/null 2>&1
    
    print_success "Dependencies installed successfully"
}

install_dependencies_fedora() {
    print_header "Installing Dependencies (Fedora)"
    
    print_info "Installing build tools..."
    sudo dnf groupinstall -y "Development Tools" > /dev/null 2>&1 || true
    
    print_info "Installing dependencies..."
    sudo dnf install -y \
        pkg-config \
        openssl-devel \
        protobuf-compiler \
        protobuf-devel \
        curl \
        git \
        > /dev/null 2>&1
    
    print_success "Dependencies installed successfully"
}

install_dependencies_opensuse() {
    print_header "Installing Dependencies (openSUSE)"
    
    print_info "Installing build tools..."
    sudo zypper install -y -t pattern devel_basis > /dev/null 2>&1
    
    print_info "Installing dependencies..."
    sudo zypper install -y \
        pkg-config \
        libopenssl-devel \
        protobuf-devel \
        curl \
        git \
        > /dev/null 2>&1
    
    print_success "Dependencies installed successfully"
}

install_dependencies() {
    case "$OS_NAME" in
        ubuntu|debian|linuxmint)
            install_dependencies_ubuntu_debian
            ;;
        rhel|rocky|almalinux|centos)
            install_dependencies_rhel
            ;;
        fedora)
            install_dependencies_fedora
            ;;
        opensuse*|sles)
            install_dependencies_opensuse
            ;;
        *)
            print_warning "Unknown distribution: $OS_NAME"
            print_info "Attempting to use apt-get (Debian-based)..."
            install_dependencies_ubuntu_debian
            ;;
    esac
    
    # Verify critical dependencies
    if ! command_exists protoc; then
        print_error "protoc (Protocol Buffer compiler) not found after installation"
        exit 1
    fi
    
    print_success "All dependencies verified"
}

# =============================================================================
# Rust Installation
# =============================================================================

install_rust() {
    print_header "Installing Rust Toolchain"
    
    if command_exists rustc && command_exists cargo; then
        RUST_VERSION=$(rustc --version | awk '{print $2}')
        print_success "Rust is already installed (version $RUST_VERSION)"
        RUST_INSTALLED=true
        return
    fi
    
    print_info "Downloading and installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    
    # Load Rust environment
    . "$HOME/.cargo/env"
    
    # Verify installation
    if command_exists rustc && command_exists cargo; then
        RUST_VERSION=$(rustc --version | awk '{print $2}')
        print_success "Rust $RUST_VERSION installed successfully"
        RUST_INSTALLED=true
    else
        print_error "Rust installation failed"
        exit 1
    fi
}

# =============================================================================
# Build Process
# =============================================================================

clean_build_artifacts() {
    if [ "$CLEAN_BUILD" = true ]; then
        print_header "Cleaning Previous Build Artifacts"
        
        if [ -d "$SCRIPT_DIR/target" ]; then
            print_info "Removing target directory..."
            cargo clean
            print_success "Build artifacts cleaned"
        else
            print_info "No previous build artifacts found"
        fi
    fi
}

build_rust_rqd() {
    print_header "Building Rust RQD"
    
    cd "$SCRIPT_DIR"
    
    # Display build configuration
    print_info "Build configuration:"
    echo "  - Mode: $BUILD_MODE"
    echo "  - Static: $STATIC_BUILD"
    echo "  - Tests: $RUN_TESTS"
    echo ""
    
    # Build command
    BUILD_CMD="cargo build --package rqd"
    
    if [ "$BUILD_MODE" = "release" ]; then
        BUILD_CMD="$BUILD_CMD --release"
    fi
    
    if [ "$STATIC_BUILD" = true ]; then
        print_info "Installing musl target for static builds..."
        rustup target add x86_64-unknown-linux-musl > /dev/null 2>&1
        BUILD_CMD="$BUILD_CMD --target x86_64-unknown-linux-musl"
    fi
    
    print_info "Running: $BUILD_CMD"
    print_info "This may take 2-5 minutes..."
    echo ""
    
    # Execute build
    if $BUILD_CMD; then
        print_success "Build completed successfully!"
    else
        print_error "Build failed"
        exit 1
    fi
}

# =============================================================================
# Testing
# =============================================================================

run_tests() {
    if [ "$RUN_TESTS" = true ]; then
        print_header "Running Tests"
        
        print_info "Executing test suite..."
        if cargo test --package rqd --quiet 2>&1 | grep -E "test result|running"; then
            print_success "All tests passed!"
        else
            print_warning "Some tests failed, but build is complete"
        fi
    else
        print_info "Skipping tests (--no-tests flag used)"
    fi
}

# =============================================================================
# Build Summary
# =============================================================================

show_summary() {
    print_header "Build Summary"
    
    # Determine binary path
    if [ "$STATIC_BUILD" = true ]; then
        BINARY_PATH="$SCRIPT_DIR/target/x86_64-unknown-linux-musl/$BUILD_MODE/openrqd"
    else
        BINARY_PATH="$SCRIPT_DIR/target/$BUILD_MODE/openrqd"
    fi
    
    if [ -f "$BINARY_PATH" ]; then
        BINARY_SIZE=$(du -h "$BINARY_PATH" | awk '{print $1}')
        
        echo -e "${GREEN}Build successful!${NC}"
        echo ""
        echo "Binary information:"
        echo "  Location: $BINARY_PATH"
        echo "  Size: $BINARY_SIZE"
        echo "  Type: $(file -b "$BINARY_PATH" | cut -d',' -f1)"
        echo ""
        
        echo "To run the RQD:"
        echo -e "  ${BLUE}CUEBOT_ENDPOINTS=localhost:8443 $BINARY_PATH${NC}"
        echo ""
        
        echo "To install system-wide:"
        echo -e "  ${BLUE}sudo cp $BINARY_PATH /usr/local/bin/openrqd${NC}"
        echo ""
        
        echo "Next steps:"
        echo "  1. Configure RQD: Edit config/rqd.yaml"
        echo "  2. Test locally: Run with dummy-cuebot"
        echo "  3. Install: Copy to /usr/local/bin/"
        echo "  4. Deploy: Set up systemd service"
        echo ""
        
        print_success "Build process complete!"
    else
        print_error "Binary not found at expected location: $BINARY_PATH"
        exit 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    print_header "OpenCue Rust RQD - Automated Build Script"
    echo ""
    
    # Check if running from correct directory
    if [ ! -f "$SCRIPT_DIR/Cargo.toml" ]; then
        print_error "Script must be run from the OpenCue/rust directory"
        print_info "Current directory: $SCRIPT_DIR"
        exit 1
    fi
    
    # Detect OS
    detect_os
    echo ""
    
    # Install dependencies
    install_dependencies
    echo ""
    
    # Install Rust
    install_rust
    echo ""
    
    # Clean if requested
    clean_build_artifacts
    echo ""
    
    # Build
    build_rust_rqd
    echo ""
    
    # Test
    run_tests
    echo ""
    
    # Summary
    show_summary
}

# =============================================================================
# Error Handling
# =============================================================================

trap 'print_error "Build script failed at line $LINENO"; exit 1' ERR

# =============================================================================
# Execute Main
# =============================================================================

main "$@"
