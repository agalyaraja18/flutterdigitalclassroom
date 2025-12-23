# Django Backend Startup Script for Windows PowerShell
# This script activates the virtual environment and starts the Django server

Write-Host "Starting Django Backend Server..." -ForegroundColor Green

# Navigate to backend directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Check if virtual environment exists
if (Test-Path "venv\Scripts\Activate.ps1") {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    & .\venv\Scripts\Activate.ps1
    
    # Check if Django is installed
    $djangoCheck = python -c "import django" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Django not found. Installing requirements..." -ForegroundColor Yellow
        pip install -r requirements.txt
    }
    
    Write-Host "Running database migrations..." -ForegroundColor Yellow
    python manage.py migrate
    
    Write-Host "Starting Django server on port 8000..." -ForegroundColor Green
    Write-Host "Server will be available at: http://localhost:8000" -ForegroundColor Cyan
    Write-Host "API Root: http://localhost:8000/" -ForegroundColor Cyan
    Write-Host "Admin Panel: http://localhost:8000/admin/" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    # Start the server
    python manage.py runserver
} else {
    Write-Host "Error: Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please create a virtual environment first:" -ForegroundColor Yellow
    Write-Host "  python -m venv venv" -ForegroundColor White
    Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor White
    Write-Host "  pip install -r requirements.txt" -ForegroundColor White
    exit 1
}

