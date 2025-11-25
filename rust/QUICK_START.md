# Quick Reference - Building Rust RQD on Linux VM

## TL;DR - Fastest Way

```bash
# 1. Sync project to VM
rsync -avz ~/Documents/GitHub/OpenCue/ user@vm-hostname:~/OpenCue/

# 2. SSH to VM
ssh user@vm-hostname

# 3. Build (automated)
cd ~/OpenCue/rust
./build-rust-rqd.sh

# 4. Binary ready at:
# target/release/openrqd (11MB)
```

**Time:** 2-5 minutes | **Requirements:** 2GB RAM, internet connection

---

## Build Script Options

```bash
./build-rust-rqd.sh              # Standard release build
./build-rust-rqd.sh --clean      # Clean and rebuild
./build-rust-rqd.sh --debug      # Fast debug build
./build-rust-rqd.sh --no-tests   # Skip tests
./build-rust-rqd.sh --static     # Static binary (no dependencies)
./build-rust-rqd.sh --help       # Show all options
```

---

## Manual Build (If Script Fails)

### Ubuntu/Debian VM

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libssl-dev protobuf-compiler curl git

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build
cd ~/OpenCue/rust
cargo build --release --package rqd

# Binary: target/release/openrqd
```

### Rocky/AlmaLinux/CentOS VM

```bash
# Install dependencies
sudo dnf install -y epel-release
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y pkg-config openssl-devel protobuf-compiler curl git

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build
cd ~/OpenCue/rust
cargo build --release --package rqd

# Binary: target/release/openrqd
```

---

## Syncing Project to VM

### Method 1: rsync (Recommended)

```bash
# Sync entire project
rsync -avz --progress \
  ~/Documents/GitHub/OpenCue/ \
  user@vm-hostname:~/OpenCue/

# Sync only rust directory (faster)
rsync -avz --progress \
  ~/Documents/GitHub/OpenCue/rust/ \
  user@vm-hostname:~/OpenCue/rust/

# Sync and exclude target directory
rsync -avz --progress \
  --exclude 'target' \
  ~/Documents/GitHub/OpenCue/ \
  user@vm-hostname:~/OpenCue/
```

### Method 2: scp

```bash
# Copy entire project
scp -r ~/Documents/GitHub/OpenCue \
  user@vm-hostname:~/

# Compress before transfer (faster for slow networks)
tar czf opencue.tar.gz -C ~/Documents/GitHub OpenCue
scp opencue.tar.gz user@vm-hostname:~/
ssh user@vm-hostname "tar xzf opencue.tar.gz"
```

### Method 3: git (If in version control)

```bash
# On VM
git clone https://github.com/AcademySoftwareFoundation/OpenCue.git
cd OpenCue
git checkout pipeline-main
```

---

## Post-Build Installation

```bash
# Install binary system-wide
sudo cp target/release/openrqd /usr/local/bin/
sudo chmod +x /usr/local/bin/openrqd

# Create config directory
sudo mkdir -p /etc/openrqd
sudo cp config/rqd.yaml /etc/openrqd/

# Edit config (set your Cuebot server)
sudo nano /etc/openrqd/rqd.yaml
# Change: cuebot_endpoints: ["your-cuebot:8443"]

# Test run
CUEBOT_ENDPOINTS=your-cuebot:8443 openrqd
```

---

## Set Up systemd Service

```bash
# Copy service file
sudo cp crates/rqd/resources/openrqd.service /etc/systemd/system/

# Edit to set Cuebot endpoint
sudo nano /etc/systemd/system/openrqd.service
# Add: Environment="CUEBOT_ENDPOINTS=your-cuebot:8443"

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable openrqd
sudo systemctl start openrqd

# Check status
sudo systemctl status openrqd

# View logs
sudo journalctl -u openrqd -f
```

---

## Common Issues & Solutions

| Issue                     | Solution                                                                                               |
| ------------------------- | ------------------------------------------------------------------------------------------------------ |
| **"protoc not found"**    | `sudo apt-get install protobuf-compiler` (Ubuntu)<br>`sudo dnf install protobuf-compiler` (Rocky)      |
| **"linker cc not found"** | `sudo apt-get install build-essential` (Ubuntu)<br>`sudo dnf groupinstall "Development Tools"` (Rocky) |
| **"out of memory"**       | Build with `-j 1` flag or add swap:<br>`cargo build --release --package rqd -j 1`                      |
| **"permission denied"**   | Don't build as root, build in home directory                                                           |
| **Network/proxy errors**  | Set proxy: `export https_proxy=http://proxy:port`                                                      |

---

## Building for Multiple VMs

### Create VM List

```bash
# vm-list.txt
user@render-node-01
user@render-node-02
user@render-node-03
```

### Deploy Script

```bash
#!/bin/bash
# deploy-all.sh

while read vm; do
    echo "Deploying to $vm..."

    # Sync project
    rsync -avz ~/OpenCue/ "$vm:~/OpenCue/"

    # Build
    ssh "$vm" "cd ~/OpenCue/rust && ./build-rust-rqd.sh"

    # Install
    ssh "$vm" "sudo cp ~/OpenCue/rust/target/release/openrqd /usr/local/bin/"

    # Restart
    ssh "$vm" "sudo systemctl restart openrqd"

    echo "✓ Done: $vm"
done < vm-list.txt
```

---

## Verification Commands

```bash
# Check binary
ls -lh target/release/openrqd
file target/release/openrqd

# Test run (will try to connect to Cuebot)
CUEBOT_ENDPOINTS=localhost:8443 ./target/release/openrqd

# Run with dummy-cuebot for testing
# Terminal 1:
./target/release/dummy-cuebot report-server

# Terminal 2:
OPENCUE_RQD_CONFIG=config/rqd.fake_linux.yaml ./target/release/openrqd

# Check if installed system-wide
which openrqd
openrqd --version

# Check systemd service
sudo systemctl status openrqd
sudo journalctl -u openrqd -n 50
```

---

## Performance Notes

| Build Type  | Size    | Build Time | Use Case             |
| ----------- | ------- | ---------- | -------------------- |
| **Release** | 11MB    | 2-5 min    | Production (default) |
| **Debug**   | 50-80MB | 1-2 min    | Development          |
| **Static**  | 12MB    | 3-6 min    | Portable/containers  |
| **LTO**     | 9MB     | 5-10 min   | Maximum optimization |

---

## Environment Variables

```bash
# Cuebot server
export CUEBOT_ENDPOINTS="cuebot.example.com:8443"

# Config file
export OPENCUE_RQD_CONFIG="/etc/openrqd/rqd.yaml"

# Log level
export RUST_LOG=info  # or debug, warn, error

# Multiple Cuebot servers (failover)
export CUEBOT_ENDPOINTS="primary:8443,backup:8443"
```

---

## Files Created

After building, you'll have:

```
OpenCue/rust/
├── target/release/openrqd        # Main binary (11MB)
├── target/release/dummy-cuebot   # Testing tool
├── build-rust-rqd.sh             # Build script ✓
├── BUILD_LINUX_VM.md             # This guide ✓
└── config/
    ├── rqd.yaml                  # Production config
    └── rqd.fake_linux.yaml       # Testing config
```

---

## Resources

- **Full Guide**: `BUILD_LINUX_VM.md` (detailed instructions)
- **Rust RQD Guide**: `../dev_docs/Rust_RQD_Build_Guide.md`
- **OpenCue Docs**: https://www.opencue.io/docs/
- **Rust Docs**: https://doc.rust-lang.org/

---

## Quick Troubleshooting

```bash
# Clean and rebuild
./build-rust-rqd.sh --clean

# Build without tests (faster)
./build-rust-rqd.sh --no-tests

# Debug build (much faster compilation)
./build-rust-rqd.sh --debug

# Check Rust installation
rustc --version
cargo --version

# Update Rust
rustup update

# Check dependencies
protoc --version    # Should be 3.x+
gcc --version       # Should be installed
```

---

## Next Steps Checklist

After successful build:

- [ ] Binary exists at `target/release/openrqd`
- [ ] Tests pass (if not skipped)
- [ ] Config file updated with Cuebot address
- [ ] Binary copied to `/usr/local/bin/`
- [ ] systemd service configured
- [ ] Service enabled and started
- [ ] Can connect to Cuebot
- [ ] Ready to accept render jobs

---

**That's it!** The automated script handles everything. Just sync the project to your VM and run `./build-rust-rqd.sh`.
