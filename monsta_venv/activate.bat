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
