---
layout: default
title: Quick start for Windows
nav_order: 5
parent: Quick Starts
---

# Quick start for Windows

### This quick start guide covers setting up an OpenCue deployment on Windows using Docker and docker-compose

---

## Prerequisites

- Windows 10/11 with WSL2 enabled
- Docker Desktop for Windows
- Git for Windows
- **Python 3.9** (required for Windows client components - see note below)

{: .important }
> **Python 3.9 Requirement:** Windows client components (rqd, cuegui, cuesubmit) specifically require Python 3.9.x. This is due to binary wheel availability and compatibility with native dependencies like PySide2. See the [monsta_venv setup](#option-2-using-monsta_venv-recommended-for-python-39) for an easy way to configure the correct environment.

## Setup Steps

### 1. Enable WSL2

If you haven't already enabled WSL2:

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   wsl --install
   ```
3. Restart your computer

### 2. Install Docker Desktop

1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Install and ensure WSL2 backend is enabled
3. Start Docker Desktop

### 3. Clone the OpenCue repository

Open PowerShell or Command Prompt:

```bash
git clone https://github.com/AcademySoftwareFoundation/OpenCue.git
cd OpenCue
```

### 4. Start OpenCue services

```bash
docker-compose up -d
```

This starts:
- PostgreSQL database
- Cuebot server
- RQD (on the local machine)

### 5. Verify services are running

```bash
docker-compose ps
```

You should see all services in "Up" state.

### 6. Install Python dependencies

There are two options for setting up Python dependencies on Windows:

#### Option 1: Standard pip install

```bash
pip install pycue cuegui
```

#### Option 2: Using monsta_venv (Recommended for Python 3.9)

The `monsta_venv` directory provides a preconfigured Python 3.9 virtual environment setup specifically for Windows:

1. Open PowerShell as Administrator
2. Navigate to the OpenCue repository:
   ```powershell
   cd OpenCue\monsta_venv
   ```
3. Run the setup script:
   ```powershell
   .\setup_windows_venv.ps1
   ```
4. Activate the environment:
   ```powershell
   .\activate.ps1
   ```

See the [monsta_venv README](../../../monsta_venv/README.md) for detailed instructions and troubleshooting.

### 7. Configure environment

Set the Cuebot host:

```bash
set CUEBOT_HOSTS=localhost
```

Or in PowerShell:
```powershell
$env:CUEBOT_HOSTS = "localhost"
```

### 8. Launch CueGUI

```bash
cuegui
```

## Testing the Setup

1. In CueGUI, you should see your local machine listed as a host
2. Submit a test job using CueSubmit:
   ```bash
   cuesubmit
   ```

## Troubleshooting

### Python 3.9 Issues

**Python version mismatch:**
Windows client components require Python 3.9.x specifically. If you encounter module import errors or PySide2 issues:
1. Install Python 3.9 from [python.org](https://www.python.org/downloads/release/python-3913/)
2. Use the `monsta_venv` setup: `.\monsta_venv\setup_windows_venv.ps1`

**PySide2 installation fails:**
```powershell
pip install PySide2==5.15.2.1
```

### Docker not starting
- Ensure virtualization is enabled in BIOS
- Check that WSL2 is properly installed
- Restart Docker Desktop

### CueGUI connection issues
- Verify CUEBOT_HOSTS is set correctly
- Check firewall settings for port 8443
- Ensure Cuebot container is running

### Performance issues
- Allocate more resources to Docker Desktop in Settings
- Use WSL2 backend for better performance

### PowerShell script execution blocked
Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Next Steps

- [monsta_venv README](../../../monsta_venv/README.md) - Detailed Windows Python 3.9 setup
- [Installing CueSubmit](../getting-started/installing-cuesubmit.md)
- [Submitting Jobs](../user-guides/submitting-jobs.md)
- [Configuring RQD](../other-guides/customizing-rqd.md)

For more detailed instructions, see the component-specific installation guides.