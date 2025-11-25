# Building Rust RQD on Linux VM

## Overview

This guide provides step-by-step instructions for building the Rust RQD (Render Queue Daemon) on a fresh Linux VM. The automated build script handles all dependencies and compilation.

---

## Supported Linux Distributions

| Distribution    | Version | Status         | Notes               |
| --------------- | ------- | -------------- | ------------------- |
| **Ubuntu**      | 20.04+  | ✅ Recommended | Easiest setup       |
| **Debian**      | 11+     | ✅ Recommended | Stable and reliable |
| **Rocky Linux** | 8+      | ✅ Supported   | RHEL alternative    |
| **AlmaLinux**   | 8+      | ✅ Supported   | RHEL alternative    |
| **CentOS**      | 8+      | ✅ Supported   | Enterprise          |
| **Fedora**      | 36+     | ✅ Supported   | Latest packages     |
| **openSUSE**    | 15+     | ✅ Supported   | Enterprise option   |

---

## Prerequisites

### Minimum System Requirements

- **CPU**: 2 cores (4+ recommended)
- **RAM**: 2GB (4GB+ recommended for compilation)
- **Disk**: 5GB free space (10GB+ recommended)
- **Network**: Internet connection for downloading dependencies

### Required Permissions

- Sudo/root access for installing system packages
- Regular user for building (don't build as root)

---

## Quick Start (Automated)

### 1. Sync OpenCue Project to VM

**From your local machine:**

```bash
# Using rsync
rsync -avz --progress \
  /home/didi/Documents/GitHub/OpenCue/ \
  user@vm-hostname:/home/user/OpenCue/

# Or using scp
scp -r /home/didi/Documents/GitHub/OpenCue \
  user@vm-hostname:/home/user/

# Or using git (if project is in version control)
# On VM:
git clone https://github.com/AcademySoftwareFoundation/OpenCue.git
cd OpenCue
git checkout pipeline-main
```

### 2. Run the Build Script

**On the Linux VM:**

```bash
cd ~/OpenCue/rust

# Make script executable
chmod +x build-rust-rqd.sh

# Run the build script
./build-rust-rqd.sh
```

The script will:

1. ✅ Detect your Linux distribution
2. ✅ Install all required dependencies
3. ✅ Install Rust toolchain if needed
4. ✅ Build the Rust RQD in release mode
5. ✅ Run tests to verify the build
6. ✅ Display build summary with binary location

**Build time:** 2-5 minutes (depending on VM specs)

---

## Manual Build Instructions

If you prefer to build manually or the script fails, follow these steps:

### Step 1: Install System Dependencies

**Ubuntu/Debian:**

```bash
# Update package index
sudo apt-get update

# Install build tools
sudo apt-get install -y \
  build-essential \
  pkg-config \
  libssl-dev \
  protobuf-compiler \
  curl \
  git \
  ca-certificates

# Verify protobuf installation
protoc --version
# Should output: libprotoc 3.x.x or higher
```

**Rocky Linux/AlmaLinux/CentOS:**

```bash
# Install EPEL repository (if needed)
sudo dnf install -y epel-release

# Install build tools
sudo dnf groupinstall -y "Development Tools"

# Install dependencies
sudo dnf install -y \
  pkg-config \
  openssl-devel \
  protobuf-compiler \
  protobuf-devel \
  curl \
  git \
  ca-certificates

# Verify protobuf installation
protoc --version
```

**Fedora:**

```bash
# Install build tools
sudo dnf groupinstall -y "Development Tools"

# Install dependencies
sudo dnf install -y \
  pkg-config \
  openssl-devel \
  protobuf-compiler \
  protobuf-devel \
  curl \
  git

# Verify protobuf installation
protoc --version
```

**openSUSE:**

```bash
# Install build tools
sudo zypper install -y -t pattern devel_basis

# Install dependencies
sudo zypper install -y \
  pkg-config \
  libopenssl-devel \
  protobuf-devel \
  curl \
  git

# Verify protobuf installation
protoc --version
```

### Step 2: Install Rust

```bash
# Download and install rustup (Rust installer)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Follow the prompts:
# 1) Proceed with installation (default)
# Press Enter

# Load Rust environment
source $HOME/.cargo/env

# Verify installation
rustc --version
cargo --version

# Expected output:
# rustc 1.85.x (xxxxxxx)
# cargo 1.85.x (xxxxxxx)
```

**Add Rust to PATH permanently:**

```bash
# The installer should have added this already, but verify:
grep -q 'cargo/env' ~/.bashrc || echo 'source $HOME/.cargo/env' >> ~/.bashrc

# For zsh users:
grep -q 'cargo/env' ~/.zshrc || echo 'source $HOME/.cargo/env' >> ~/.zshrc
```

### Step 3: Build Rust RQD

```bash
# Navigate to the Rust directory
cd ~/OpenCue/rust

# Clean any previous builds (optional)
cargo clean

# Build in release mode (optimized)
cargo build --release --package rqd

# This will:
# 1. Download and compile all Rust dependencies
# 2. Compile the opencue-proto package
# 3. Compile the rqd package
# 4. Create optimized binary

# Build time: 2-5 minutes on typical VM
```

**Expected output:**

```
   Compiling opencue-proto v0.1.4
   Compiling rqd v0.1.4
    Finished release [optimized] target(s) in 2m 34s
```

### Step 4: Verify the Build

```bash
# Check binary was created
ls -lh target/release/openrqd

# Expected output:
# -rwxr-xr-x 1 user user 11M Nov 26 12:34 target/release/openrqd

# Check binary type
file target/release/openrqd

# Expected output:
# target/release/openrqd: ELF 64-bit LSB pie executable, x86-64 ...

# Run simple test (will try to connect to Cuebot)
CUEBOT_ENDPOINTS=localhost:8443 ./target/release/openrqd --help 2>&1 | head -5
```

### Step 5: Run Tests (Optional)

```bash
# Run unit tests
cargo test --package rqd

# Run with output
cargo test --package rqd -- --nocapture

# Run specific test
cargo test --package rqd test_machine
```

---

## Building with Different Optimization Levels

### Production Build (Recommended)

```bash
# Maximum optimization, smallest binary
cargo build --release --package rqd

# Binary: target/release/openrqd
# Size: ~11MB
# Optimization: Full (-O3)
```

### Debug Build (Development)

```bash
# Fast compilation, larger binary, debug symbols
cargo build --package rqd

# Binary: target/debug/openrqd
# Size: ~50-80MB
# Optimization: None (-O0)
```

### Custom Optimization

```bash
# Build with custom profile (edit Cargo.toml first)
cargo build --profile custom --package rqd
```

---

## Post-Build Steps

### Install System-Wide

```bash
# Copy binary to system location
sudo cp target/release/openrqd /usr/local/bin/

# Make executable (should already be)
sudo chmod +x /usr/local/bin/openrqd

# Verify installation
openrqd --version
which openrqd
# Should output: /usr/local/bin/openrqd
```

### Create Configuration

```bash
# Create config directory
sudo mkdir -p /etc/openrqd

# Copy example configuration
sudo cp config/rqd.yaml /etc/openrqd/

# Edit configuration
sudo nano /etc/openrqd/rqd.yaml

# Update Cuebot endpoints:
# grpc:
#   cuebot_endpoints: ["your-cuebot-server:8443"]
```

### Set Up systemd Service

```bash
# Copy service file
sudo cp crates/rqd/resources/openrqd.service /etc/systemd/system/

# Edit service file to set correct endpoints
sudo nano /etc/systemd/system/openrqd.service

# Add environment variable:
# Environment="CUEBOT_ENDPOINTS=your-cuebot:8443"

# Reload systemd
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable openrqd

# Start service
sudo systemctl start openrqd

# Check status
sudo systemctl status openrqd

# View logs
sudo journalctl -u openrqd -f
```

---

## Building RPM Package

For RHEL-based distributions (Rocky, AlmaLinux, CentOS, Fedora):

```bash
# Install cargo-generate-rpm
cargo install cargo-generate-rpm

# Navigate to RQD directory
cd crates/rqd

# Build the binary first
cargo build --release

# Generate RPM
cargo generate-rpm

# RPM location:
ls -lh target/generate-rpm/openrqd-*.rpm

# Install RPM
sudo rpm -ivh target/generate-rpm/openrqd-*.rpm

# The RPM automatically:
# - Installs binary to /usr/bin/openrqd
# - Installs config to /etc/openrqd/rqd.yaml
# - Installs systemd service
# - Enables and starts the service
```

---

## Cross-Compiling for Different Architectures

### Build for ARM64 (aarch64)

```bash
# Install cross-compilation toolchain
rustup target add aarch64-unknown-linux-gnu

# Install cross-compiler
# Ubuntu/Debian:
sudo apt-get install gcc-aarch64-linux-gnu

# Build for ARM64
cargo build --release --package rqd --target aarch64-unknown-linux-gnu

# Binary location:
# target/aarch64-unknown-linux-gnu/release/openrqd
```

### Using 'cross' for Easy Cross-Compilation

```bash
# Install cross tool
cargo install cross

# Build for ARM64
cross build --release --package rqd --target aarch64-unknown-linux-gnu

# Build for other architectures
cross build --release --package rqd --target x86_64-unknown-linux-musl  # Static binary
cross build --release --package rqd --target armv7-unknown-linux-gnueabihf  # ARM 32-bit
```

---

## Troubleshooting

### Issue: "protoc: command not found"

**Problem:** Protocol Buffer compiler not installed

**Solution:**

```bash
# Ubuntu/Debian:
sudo apt-get install protobuf-compiler

# Rocky/AlmaLinux:
sudo dnf install protobuf-compiler

# Verify:
protoc --version
```

### Issue: "linker `cc` not found"

**Problem:** C compiler not installed

**Solution:**

```bash
# Ubuntu/Debian:
sudo apt-get install build-essential

# Rocky/AlmaLinux:
sudo dnf groupinstall "Development Tools"

# Verify:
gcc --version
```

### Issue: "could not find system library 'openssl'"

**Problem:** OpenSSL development headers not installed

**Solution:**

```bash
# Ubuntu/Debian:
sudo apt-get install libssl-dev

# Rocky/AlmaLinux:
sudo dnf install openssl-devel

# Verify:
pkg-config --libs openssl
```

### Issue: "Out of memory during build"

**Problem:** VM has insufficient RAM

**Solution:**

```bash
# Option 1: Build with fewer parallel jobs
cargo build --release --package rqd -j 1

# Option 2: Increase swap space
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Option 3: Build in debug mode first (uses less memory)
cargo build --package rqd
```

### Issue: "Failed to fetch index"

**Problem:** Network/proxy issues

**Solution:**

```bash
# Check internet connectivity
ping -c 4 crates.io

# If behind proxy, set environment variables:
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# Or configure cargo proxy in ~/.cargo/config.toml:
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml << 'EOF'
[http]
proxy = "proxy.example.com:8080"

[https]
proxy = "proxy.example.com:8080"
EOF
```

### Issue: "Permission denied"

**Problem:** Trying to write to restricted location

**Solution:**

```bash
# Don't build as root
# Build in your home directory
cd ~/OpenCue/rust
cargo build --release --package rqd

# Only use sudo for installation:
sudo cp target/release/openrqd /usr/local/bin/
```

---

## Performance Tuning

### Build with Link-Time Optimization (LTO)

**Edit `rust/Cargo.toml`:**

```toml
[profile.release]
lto = true
codegen-units = 1
opt-level = 3
```

**Build:**

```bash
cargo build --release --package rqd
# Takes longer but produces smaller, faster binary
```

### Build Static Binary (No Dynamic Dependencies)

```bash
# Install musl target
rustup target add x86_64-unknown-linux-musl

# Build static binary
cargo build --release --package rqd --target x86_64-unknown-linux-musl

# Binary location:
# target/x86_64-unknown-linux-musl/release/openrqd

# Verify it's static:
ldd target/x86_64-unknown-linux-musl/release/openrqd
# Should output: "not a dynamic executable"
```

---

## Verification Checklist

After building, verify everything works:

- [ ] Binary exists: `ls -lh target/release/openrqd`
- [ ] Binary is executable: `file target/release/openrqd`
- [ ] Binary runs: `./target/release/openrqd --help`
- [ ] Tests pass: `cargo test --package rqd`
- [ ] Config file exists: `ls config/rqd.yaml`
- [ ] Can connect to Cuebot (if available): `CUEBOT_ENDPOINTS=your-cuebot:8443 ./target/release/openrqd`

---

## Next Steps

After successful build:

1. **Configure RQD**: Edit `config/rqd.yaml` with your Cuebot server details
2. **Test locally**: Run with dummy-cuebot for testing
3. **Install system-wide**: Copy binary to `/usr/local/bin/`
4. **Set up service**: Configure systemd for auto-start
5. **Monitor logs**: Use `journalctl` to monitor RQD activity
6. **Deploy to render farm**: Repeat on all render nodes

---

## Building on Different VM Platforms

### AWS EC2

```bash
# Launch instance: Ubuntu 22.04 LTS, t2.medium or larger
# SSH into instance
ssh -i your-key.pem ubuntu@ec2-instance

# Sync project
rsync -avz -e "ssh -i your-key.pem" \
  /path/to/OpenCue/ ubuntu@ec2-instance:~/OpenCue/

# Run build script
cd ~/OpenCue/rust
./build-rust-rqd.sh
```

### Google Cloud VM

```bash
# Create instance: Ubuntu 22.04, e2-medium or larger
# SSH into instance (gcloud CLI)
gcloud compute ssh vm-instance

# Sync project
gcloud compute scp --recurse /path/to/OpenCue/ vm-instance:~/

# Run build script
cd ~/OpenCue/rust
./build-rust-rqd.sh
```

### VirtualBox VM

```bash
# Create VM: Ubuntu 22.04, 2+ cores, 4GB+ RAM
# Set up shared folder or use SSH

# From host, sync via SSH:
rsync -avz /path/to/OpenCue/ user@vm-ip:~/OpenCue/

# Or use VirtualBox shared folders:
# In VM:
sudo mount -t vboxsf SharedFolder ~/host-share
cp -r ~/host-share/OpenCue ~/

# Run build script
cd ~/OpenCue/rust
./build-rust-rqd.sh
```

### VMware VM

```bash
# Create VM: Ubuntu 22.04, 2+ cores, 4GB+ RAM
# Install VMware Tools for shared folders

# Sync project via shared folder or SSH
rsync -avz /path/to/OpenCue/ user@vm-ip:~/OpenCue/

# Run build script
cd ~/OpenCue/rust
./build-rust-rqd.sh
```

---

## Automated Deployment Script

For deploying to multiple VMs:

**Create `deploy-to-vms.sh`:**

```bash
#!/bin/bash
# Deploy Rust RQD to multiple Linux VMs

VMS=(
    "user@render-node-01"
    "user@render-node-02"
    "user@render-node-03"
)

for vm in "${VMS[@]}"; do
    echo "Deploying to $vm..."

    # Sync project
    rsync -avz --delete \
        ~/OpenCue/ \
        "$vm:~/OpenCue/"

    # Build on remote VM
    ssh "$vm" "cd ~/OpenCue/rust && ./build-rust-rqd.sh"

    # Install system-wide
    ssh "$vm" "sudo cp ~/OpenCue/rust/target/release/openrqd /usr/local/bin/"

    # Restart service
    ssh "$vm" "sudo systemctl restart openrqd"

    echo "✓ Deployed to $vm"
done

echo "Deployment complete!"
```

**Usage:**

```bash
chmod +x deploy-to-vms.sh
./deploy-to-vms.sh
```

---

## Resources

- **Rust Documentation**: https://doc.rust-lang.org/
- **Cargo Book**: https://doc.rust-lang.org/cargo/
- **OpenCue Documentation**: https://www.opencue.io/docs/
- **Build Script**: `build-rust-rqd.sh` (in this directory)
- **Rust RQD Guide**: `../dev_docs/Rust_RQD_Build_Guide.md`

---

## Summary

**Quick Build:**

```bash
# 1. Sync project to VM
rsync -avz OpenCue/ user@vm:~/OpenCue/

# 2. SSH to VM
ssh user@vm

# 3. Run build script
cd ~/OpenCue/rust
./build-rust-rqd.sh

# 4. Binary ready at:
# target/release/openrqd
```

**Build time:** 2-5 minutes  
**Binary size:** ~11MB  
**Memory required:** 2GB+ (4GB+ recommended)

The automated build script handles everything - just sync the project and run it!
