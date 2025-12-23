@echo off
REM Django Backend Startup Script for Windows CMD
REM This script activates the virtual environment and starts the Django server

echo Starting Django Backend Server...

REM Navigate to backend directory
cd /d "%~dp0"

REM Check if virtual environment exists
if exist "venv\Scripts\activate.bat" (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
    
    echo Running database migrations...
    python manage.py migrate
    
    echo Starting Django server on port 8000...
    echo Server will be available at: http://localhost:8000
    echo API Root: http://localhost:8000/
    echo Admin Panel: http://localhost:8000/admin/
    echo Press Ctrl+C to stop the server
    echo.
    
    REM Start the server
    python manage.py runserver
) else (
    echo Error: Virtual environment not found!
    echo Please create a virtual environment first:
    echo   python -m venv venv
    echo   venv\Scripts\activate.bat
    echo   pip install -r requirements.txt
    pause
    exit /b 1
)

