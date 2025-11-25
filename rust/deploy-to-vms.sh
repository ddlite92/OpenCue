#!/bin/bash
# =============================================================================
# Deploy Rust RQD to Multiple Linux VMs
# =============================================================================
# This script automates deployment of Rust RQD to multiple render nodes.
#
# Usage:
#   1. Create a file with VM hostnames (one per line):
#      echo "user@render-01" > vm-list.txt
#      echo "user@render-02" >> vm-list.txt
#
#   2. Run this script:
#      ./deploy-to-vms.sh vm-list.txt
#
# Requirements:
#   - SSH key-based authentication configured for all VMs
#   - VMs must be accessible via SSH
#   - User must have sudo privileges on VMs
#
# =============================================================================

set -e
set -u

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VM_LIST_FILE="${1:-}"
INSTALL_SYSTEMD=true
RESTART_SERVICE=true

# =============================================================================
# Helper Functions
# =============================================================================

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# =============================================================================
# Validation
# =============================================================================

validate_inputs() {
    if [ -z "$VM_LIST_FILE" ]; then
        print_error "Usage: $0 <vm-list-file>"
        echo ""
        echo "Example vm-list.txt:"
        echo "  user@render-node-01"
        echo "  user@render-node-02"
        echo "  user@render-node-03"
        echo ""
        exit 1
    fi
    
    if [ ! -f "$VM_LIST_FILE" ]; then
        print_error "VM list file not found: $VM_LIST_FILE"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_ROOT/rust" ]; then
        print_error "OpenCue rust directory not found: $PROJECT_ROOT/rust"
        exit 1
    fi
    
    # Count VMs
    VM_COUNT=$(grep -v '^#' "$VM_LIST_FILE" | grep -v '^[[:space:]]*$' | wc -l)
    if [ "$VM_COUNT" -eq 0 ]; then
        print_error "No VMs found in $VM_LIST_FILE"
        exit 1
    fi
    
    print_success "Found $VM_COUNT VMs to deploy"
}

# =============================================================================
# Deployment Functions
# =============================================================================

test_ssh_connection() {
    local vm=$1
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$vm" "exit" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

sync_project() {
    local vm=$1
    
    print_info "Syncing project to $vm..."
    
    # Create directory on VM
    ssh "$vm" "mkdir -p ~/OpenCue" 2>/dev/null || true
    
    # Sync project (exclude target directory to save time)
    rsync -az --delete \
        --exclude 'target' \
        --exclude '.git' \
        --exclude '*.pyc' \
        --exclude '__pycache__' \
        "$PROJECT_ROOT/" \
        "$vm:~/OpenCue/" 2>&1 | grep -v "sending incremental" | grep -v "sent.*received" || true
    
    print_success "Project synced"
}

build_on_vm() {
    local vm=$1
    
    print_info "Building on $vm..."
    
    # Run build script
    if ssh "$vm" "cd ~/OpenCue/rust && ./build-rust-rqd.sh --no-tests" 2>&1 | \
       grep -E "Build successful|Build completed"; then
        print_success "Build completed"
    else
        print_error "Build failed on $vm"
        return 1
    fi
}

install_binary() {
    local vm=$1
    
    print_info "Installing binary on $vm..."
    
    # Copy binary to /usr/local/bin
    ssh "$vm" "sudo cp ~/OpenCue/rust/target/release/openrqd /usr/local/bin/" 2>/dev/null
    ssh "$vm" "sudo chmod +x /usr/local/bin/openrqd" 2>/dev/null
    
    print_success "Binary installed to /usr/local/bin/openrqd"
}

install_config() {
    local vm=$1
    
    print_info "Installing configuration on $vm..."
    
    # Create config directory
    ssh "$vm" "sudo mkdir -p /etc/openrqd" 2>/dev/null
    
    # Copy config file
    ssh "$vm" "sudo cp ~/OpenCue/rust/config/rqd.yaml /etc/openrqd/" 2>/dev/null
    
    print_success "Configuration installed to /etc/openrqd/rqd.yaml"
}

install_systemd_service() {
    local vm=$1
    
    if [ "$INSTALL_SYSTEMD" = true ]; then
        print_info "Installing systemd service on $vm..."
        
        # Copy service file
        ssh "$vm" "sudo cp ~/OpenCue/rust/crates/rqd/resources/openrqd.service /etc/systemd/system/" 2>/dev/null
        
        # Reload systemd
        ssh "$vm" "sudo systemctl daemon-reload" 2>/dev/null
        
        # Enable service
        ssh "$vm" "sudo systemctl enable openrqd" 2>/dev/null
        
        print_success "systemd service installed and enabled"
    fi
}

restart_service() {
    local vm=$1
    
    if [ "$RESTART_SERVICE" = true ]; then
        print_info "Restarting service on $vm..."
        
        # Restart service
        if ssh "$vm" "sudo systemctl restart openrqd" 2>/dev/null; then
            sleep 2
            
            # Check status
            if ssh "$vm" "sudo systemctl is-active --quiet openrqd" 2>/dev/null; then
                print_success "Service is running"
            else
                print_warning "Service may not be running properly"
                ssh "$vm" "sudo systemctl status openrqd --no-pager -n 5" 2>/dev/null || true
            fi
        else
            print_warning "Failed to restart service (may not be installed yet)"
        fi
    fi
}

deploy_to_vm() {
    local vm=$1
    local vm_num=$2
    local total_vms=$3
    
    print_header "Deploying to $vm ($vm_num/$total_vms)"
    
    # Test SSH connection
    if ! test_ssh_connection "$vm"; then
        print_error "Cannot connect to $vm via SSH"
        return 1
    fi
    print_success "SSH connection OK"
    
    # Sync project
    if ! sync_project "$vm"; then
        print_error "Failed to sync project to $vm"
        return 1
    fi
    
    # Build
    if ! build_on_vm "$vm"; then
        print_error "Failed to build on $vm"
        return 1
    fi
    
    # Install binary
    if ! install_binary "$vm"; then
        print_error "Failed to install binary on $vm"
        return 1
    fi
    
    # Install config
    if ! install_config "$vm"; then
        print_error "Failed to install config on $vm"
        return 1
    fi
    
    # Install systemd service
    if ! install_systemd_service "$vm"; then
        print_warning "Failed to install systemd service on $vm"
    fi
    
    # Restart service
    if ! restart_service "$vm"; then
        print_warning "Failed to restart service on $vm"
    fi
    
    print_success "Deployment to $vm complete!"
    return 0
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "Rust RQD Multi-VM Deployment"
    
    validate_inputs
    
    # Read VM list
    mapfile -t VMS < <(grep -v '^#' "$VM_LIST_FILE" | grep -v '^[[:space:]]*$')
    
    TOTAL_VMS=${#VMS[@]}
    SUCCESSFUL=0
    FAILED=0
    
    print_info "Starting deployment to $TOTAL_VMS VMs"
    echo ""
    
    # Deploy to each VM
    for i in "${!VMS[@]}"; do
        vm="${VMS[$i]}"
        vm_num=$((i + 1))
        
        if deploy_to_vm "$vm" "$vm_num" "$TOTAL_VMS"; then
            SUCCESSFUL=$((SUCCESSFUL + 1))
        else
            FAILED=$((FAILED + 1))
            print_error "Deployment to $vm failed"
        fi
        echo ""
    done
    
    # Summary
    print_header "Deployment Summary"
    echo "Total VMs: $TOTAL_VMS"
    echo -e "Successful: ${GREEN}$SUCCESSFUL${NC}"
    echo -e "Failed: ${RED}$FAILED${NC}"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        print_success "All deployments successful!"
        exit 0
    else
        print_warning "$FAILED deployments failed"
        exit 1
    fi
}

# =============================================================================
# Execute
# =============================================================================

main "$@"
