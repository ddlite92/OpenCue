# OpenCue Windows Python 3.9 Virtual Environment Setup Script
# This script creates and configures a Python 3.9 virtual environment for OpenCue client components

param(
    [switch]$SkipPythonCheck,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = Join-Path $ScriptDir "venv"
$RepoRoot = Split-Path -Parent $ScriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenCue Windows Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for Python 3.9
if (-not $SkipPythonCheck) {
    Write-Host "Checking for Python 3.9..." -ForegroundColor Yellow
    
    $Python39 = $null
    
    # Try py launcher first
    try {
        $pyVersion = & py -3.9 --version 2>&1
        if ($pyVersion -match "Python 3\.9") {
            $Python39 = "py -3.9"
            Write-Host "  Found Python 3.9 via py launcher: $pyVersion" -ForegroundColor Green
        }
    } catch {
        # py launcher not available or Python 3.9 not found
    }
    
    # Try python39 command
    if (-not $Python39) {
        try {
            $pyVersion = & python39 --version 2>&1
            if ($pyVersion -match "Python 3\.9") {
                $Python39 = "python39"
                Write-Host "  Found Python 3.9: $pyVersion" -ForegroundColor Green
            }
        } catch {
            # python39 not available
        }
    }
    
    # Try python command and check version
    if (-not $Python39) {
        try {
            $pyVersion = & python --version 2>&1
            if ($pyVersion -match "Python 3\.9") {
                $Python39 = "python"
                Write-Host "  Found Python 3.9: $pyVersion" -ForegroundColor Green
            }
        } catch {
            # python not available
        }
    }
    
    # Check common installation paths
    if (-not $Python39) {
        $CommonPaths = @(
            "$env:LOCALAPPDATA\Programs\Python\Python39\python.exe",
            "C:\Python39\python.exe",
            "$env:ProgramFiles\Python39\python.exe"
        )
        
        foreach ($path in $CommonPaths) {
            if (Test-Path $path) {
                $pyVersion = & $path --version 2>&1
                if ($pyVersion -match "Python 3\.9") {
                    $Python39 = $path
                    Write-Host "  Found Python 3.9 at: $path" -ForegroundColor Green
                    break
                }
            }
        }
    }
    
    if (-not $Python39) {
        Write-Host ""
        Write-Host "ERROR: Python 3.9 not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install Python 3.9 from:" -ForegroundColor Yellow
        Write-Host "  https://www.python.org/downloads/release/python-3913/" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Installation tips:" -ForegroundColor Yellow
        Write-Host "  - Check 'Add Python to PATH' during installation" -ForegroundColor White
        Write-Host "  - Select 'Customize installation' and enable pip" -ForegroundColor White
        Write-Host ""
        exit 1
    }
} else {
    $Python39 = "python"
    Write-Host "Skipping Python version check..." -ForegroundColor Yellow
}

# Check if venv already exists
if (Test-Path $VenvDir) {
    if ($Force) {
        Write-Host "Removing existing virtual environment..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $VenvDir
    } else {
        Write-Host ""
        Write-Host "Virtual environment already exists at: $VenvDir" -ForegroundColor Yellow
        Write-Host "Use -Force to recreate it." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To activate the existing environment:" -ForegroundColor Green
        Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan
        Write-Host ""
        exit 0
    }
}

# Create virtual environment
Write-Host ""
Write-Host "Creating virtual environment..." -ForegroundColor Yellow

if ($Python39 -eq "py -3.9") {
    & py -3.9 -m venv $VenvDir
} else {
    & $Python39 -m venv $VenvDir
}

if (-not (Test-Path $VenvDir)) {
    Write-Host "ERROR: Failed to create virtual environment!" -ForegroundColor Red
    exit 1
}

Write-Host "  Virtual environment created at: $VenvDir" -ForegroundColor Green

# Activate virtual environment
Write-Host ""
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
$ActivateScript = Join-Path $VenvDir "Scripts\Activate.ps1"
& $ActivateScript

# Upgrade pip
Write-Host ""
Write-Host "Upgrading pip..." -ForegroundColor Yellow
& python -m pip install --upgrade pip

# Install requirements
Write-Host ""
Write-Host "Installing requirements..." -ForegroundColor Yellow
$RequirementsFile = Join-Path $ScriptDir "requirements.txt"
& pip install -r $RequirementsFile

# Install OpenCue packages from source
Write-Host ""
Write-Host "Installing OpenCue packages from source..." -ForegroundColor Yellow

$Packages = @("pycue", "pyoutline", "rqd", "cuegui", "cuesubmit", "cueadmin")

foreach ($pkg in $Packages) {
    $PkgPath = Join-Path $RepoRoot $pkg
    if (Test-Path $PkgPath) {
        Write-Host "  Installing $pkg..." -ForegroundColor White
        & pip install -e $PkgPath
    } else {
        Write-Host "  WARNING: $pkg not found at $PkgPath" -ForegroundColor Yellow
    }
}

# Create activation scripts
Write-Host ""
Write-Host "Creating activation scripts..." -ForegroundColor Yellow

# PowerShell activation script
$ActivatePs1Content = @"
# OpenCue Windows Virtual Environment Activation Script
`$ScriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$VenvActivate = Join-Path `$ScriptDir "venv\Scripts\Activate.ps1"

if (Test-Path `$VenvActivate) {
    & `$VenvActivate
    Write-Host "OpenCue virtual environment activated!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Cyan
    Write-Host "  cuegui    - Launch CueGUI" -ForegroundColor White
    Write-Host "  cuesubmit - Launch CueSubmit" -ForegroundColor White
    Write-Host "  rqd       - Start RQD daemon" -ForegroundColor White
    Write-Host "  cueadmin  - Command-line admin tool" -ForegroundColor White
    Write-Host ""
    Write-Host "Remember to set CUEBOT_HOSTS environment variable:" -ForegroundColor Yellow
    Write-Host "  `$env:CUEBOT_HOSTS = `"your-cuebot-server`"" -ForegroundColor White
} else {
    Write-Host "ERROR: Virtual environment not found!" -ForegroundColor Red
    Write-Host "Run setup_windows_venv.ps1 first." -ForegroundColor Yellow
}
"@

$ActivatePs1Path = Join-Path $ScriptDir "activate.ps1"
$ActivatePs1Content | Out-File -FilePath $ActivatePs1Path -Encoding UTF8

# Batch activation script
$ActivateBatContent = @"
@echo off
REM OpenCue Windows Virtual Environment Activation Script

set SCRIPT_DIR=%~dp0
set VENV_ACTIVATE=%SCRIPT_DIR%venv\Scripts\activate.bat

if exist "%VENV_ACTIVATE%" (
    call "%VENV_ACTIVATE%"
    echo OpenCue virtual environment activated!
    echo.
    echo Available commands:
    echo   cuegui    - Launch CueGUI
    echo   cuesubmit - Launch CueSubmit
    echo   rqd       - Start RQD daemon
    echo   cueadmin  - Command-line admin tool
    echo.
    echo Remember to set CUEBOT_HOSTS environment variable:
    echo   set CUEBOT_HOSTS=your-cuebot-server
) else (
    echo ERROR: Virtual environment not found!
    echo Run setup_windows_venv.ps1 first.
)
"@

$ActivateBatPath = Join-Path $ScriptDir "activate.bat"
$ActivateBatContent | Out-File -FilePath $ActivateBatPath -Encoding ASCII

Write-Host "  Created activate.ps1" -ForegroundColor Green
Write-Host "  Created activate.bat" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To activate the environment:" -ForegroundColor Yellow
Write-Host "  PowerShell: .\monsta_venv\activate.ps1" -ForegroundColor White
Write-Host "  CMD:        monsta_venv\activate.bat" -ForegroundColor White
Write-Host ""
Write-Host "To run OpenCue client tools:" -ForegroundColor Yellow
Write-Host "  1. Set the Cuebot server:" -ForegroundColor White
Write-Host "     `$env:CUEBOT_HOSTS = `"your-cuebot-server`"" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Run the desired tool:" -ForegroundColor White
Write-Host "     cuegui    - Graphical interface" -ForegroundColor Cyan
Write-Host "     cuesubmit - Job submission tool" -ForegroundColor Cyan
Write-Host "     rqd       - Render queue daemon" -ForegroundColor Cyan
Write-Host "     cueadmin  - Admin commands" -ForegroundColor Cyan
Write-Host ""
