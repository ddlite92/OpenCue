# Windows Deployment Guide for OpenCue

This guide provides step-by-step instructions for deploying OpenCue client components on Windows systems using the `monsta_venv` portable Python environment bundle.

## Overview

The Windows deployment uses a two-step process:
1. **Deploy**: Run `deploy_opencue_windows.ps1` to set up the OpenCue environment
2. **Start**: Run `start_opencue_env.ps1` to launch the OpenCue client applications

## Prerequisites

- Windows 10 or later
- PowerShell 5.1 or later
- Administrator privileges (for initial setup)
- Network access to your OpenCue Cuebot server

## Installation

### Step 1: Deploy the OpenCue Environment

Open PowerShell as Administrator and run:

```powershell
.\deploy_opencue_windows.ps1
```

This script will:
- Extract the `monsta_venv` portable Python environment
- Configure the necessary environment variables
- Set up paths for OpenCue client components (CueGUI, CueSubmit, RQD)

### Step 2: Start the OpenCue Environment

After deployment is complete, start the OpenCue environment:

```powershell
.\start_opencue_env.ps1
```

This script will:
- Activate the Python virtual environment
- Set the `CUEBOT_HOSTS` environment variable
- Launch the OpenCue client applications

## Configuration

### Cuebot Server Connection

Set the `CUEBOT_HOSTS` environment variable to point to your Cuebot server:

```powershell
$env:CUEBOT_HOSTS = "your-cuebot-server:8443"
```

For IPv6 environments, ensure your server binding is configured correctly (see commit 56ad287 for IPv6 binding fixes).

### Python Environment

The `monsta_venv` bundle includes Python 3.9 and all required dependencies:
- PySide6 (Qt bindings)
- gRPC libraries
- OpenCue Python packages (pycue, pyoutline, cuegui, cuesubmit)

## Troubleshooting

### Common Issues

#### PowerShell Execution Policy Error
If you see an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Connection Refused to Cuebot
1. Verify `CUEBOT_HOSTS` is set correctly
2. Check network connectivity to the Cuebot server
3. Ensure the Cuebot service is running on the server
4. For IPv6 networks, verify the server is bound to the correct interface

#### Missing Dependencies
If you encounter import errors:
1. Ensure `deploy_opencue_windows.ps1` completed successfully
2. Check that the `monsta_venv` directory exists and contains the required files
3. Re-run the deployment script if needed

#### UI Display Issues
For CueGUI display problems:
1. Ensure your display drivers are up to date
2. Try setting the environment variable: `$env:QT_QPA_PLATFORM = "windows"`

### Log Files

Check the following locations for log files:
- OpenCue logs: `%USERPROFILE%\.opencue\logs\`
- Application logs: Check the console output when running in debug mode

## Verification

To verify the installation is working correctly:

1. **Check Python environment**:
   ```powershell
   python --version
   # Should show Python 3.9.x
   ```

2. **Test OpenCue imports**:
   ```powershell
   python -c "import opencue; print('OpenCue imported successfully')"
   ```

3. **Launch CueGUI**:
   ```powershell
   python -m cuegui
   ```

4. **Verify Cuebot connection**:
   - In CueGUI, check the status bar for connection status
   - View available shows and jobs to confirm connectivity

## Additional Resources

- [OpenCue Documentation](https://www.opencue.io/docs/)
- [OpenCue GitHub Repository](https://github.com/AcademySoftwareFoundation/OpenCue)
- [Issue #5: Windows client components require Python 3.9 environment](https://github.com/ddlite92/OpenCue/issues/5)

## Notes

- This deployment method bundles Python 3.9 as required for Windows client compatibility
- The `monsta_venv` portable environment eliminates the need for system-wide Python installation
- For production deployments, consider setting environment variables permanently via System Properties
