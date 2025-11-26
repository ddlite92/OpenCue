# monsta_venv - Windows Python 3.9 Virtual Environment Setup

This directory provides Windows-specific Python 3.9 virtual environment setup for running OpenCue client components (rqd, cuegui).

## Requirements

- Windows 10/11
- Python 3.9.x (required for Windows client components)
- Administrator privileges (for initial setup)

## Quick Setup

### Option 1: Automated Setup (Recommended)

1. Open PowerShell as Administrator
2. Navigate to this directory:
   ```powershell
   cd path\to\OpenCue\monsta_venv
   ```
3. Run the setup script:
   ```powershell
   .\setup_windows_venv.ps1
   ```

### Option 2: Manual Setup

1. Install Python 3.9:
   - Download from [Python.org](https://www.python.org/downloads/release/python-3913/)
   - During installation, check "Add Python to PATH"
   - Select "Customize installation" and enable "pip"

2. Create virtual environment:
   ```powershell
   cd path\to\OpenCue\monsta_venv
   py -3.9 -m venv venv
   ```

3. Activate the environment:
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

4. Install dependencies:
   ```powershell
   pip install -r requirements.txt
   ```

## Activating the Environment

### PowerShell
```powershell
.\monsta_venv\activate.ps1
```

### Command Prompt
```cmd
monsta_venv\activate.bat
```

## Running Client Components

After activating the environment:

### RQD (Render Queue Daemon)
```powershell
$env:CUEBOT_HOSTNAME = "your-cuebot-server"
rqd -c ..\sandbox\rqd_windows.conf
```

### CueGUI
```powershell
$env:CUEBOT_HOSTS = "your-cuebot-server"
cuegui
```

### CueSubmit
```powershell
$env:CUEBOT_HOSTS = "your-cuebot-server"
cuesubmit
```

## Troubleshooting

### Python 3.9 Not Found
If Python 3.9 is not in your PATH, specify the full path:
```powershell
C:\Python39\python.exe -m venv venv
```

### PowerShell Execution Policy
If scripts are blocked, run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Module Import Errors
Ensure all dependencies are installed:
```powershell
pip install -r requirements.txt
```

### PySide2/Qt Issues
For CueGUI Qt issues:
```powershell
pip uninstall PySide2
pip install PySide2==5.15.2.1
```

### gRPC Connection Issues
1. Verify CUEBOT_HOSTNAME is set correctly
2. Check firewall allows port 8443 (gRPC) and 8444 (RQD)
3. Test connectivity:
   ```powershell
   Test-NetConnection -ComputerName your-cuebot-server -Port 8443
   ```

## Directory Structure

```
monsta_venv/
├── README.md              # This file
├── requirements.txt       # Python dependencies
├── setup_windows_venv.ps1 # Automated setup script
├── activate.ps1           # PowerShell activation script
├── activate.bat           # Command Prompt activation script
└── venv/                  # Virtual environment (created during setup)
```

## Python Version Requirement

**Important:** Windows client components specifically require Python 3.9.x due to:
- Binary wheel availability for PySide2 on Windows
- Compatibility with psutil and other native dependencies
- Tested and verified operation with OpenCue client tools

Python versions 3.10+ may have issues with some dependencies on Windows.

## See Also

- [Quick Start for Windows](../docs/_docs/quick-starts/quick-start-windows.md)
- [Hybrid RQD Setup](../docs/_docs/developer-guide/hybrid-rqd-setup.md)
- [OpenCue Documentation](https://www.opencue.io/docs/)
