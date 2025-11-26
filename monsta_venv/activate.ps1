# OpenCue Windows Virtual Environment Activation Script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvActivate = Join-Path $ScriptDir "venv\Scripts\Activate.ps1"

if (Test-Path $VenvActivate) {
    & $VenvActivate
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
