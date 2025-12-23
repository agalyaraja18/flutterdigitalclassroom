# Backend Setup Guide

## Overview

This LMS project requires **TWO backends** to run for full functionality:

1. **Django Backend** (`lms_backend`) - Main LMS API
   - Port: **8000** (default)
   - Handles: Authentication, PDF Converter, Quiz System, PDF Analyzer API

2. **FastAPI Backend** (`pdf_analyzer_backend`) - PDF Analysis with RAG
   - Port: **8080** (default)
   - Handles: PDF text extraction, AI queries, summaries, flashcards, MCQs using FAISS vector database

## Architecture

```
┌─────────────────┐         ┌──────────────────┐
│  Django Backend │────────▶│ FastAPI Backend  │
│   (Port 8000)   │  HTTP   │   (Port 8080)    │
│                 │  Calls  │                  │
└─────────────────┘         └──────────────────┘
         │
         │
         ▼
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└─────────────────┘
```

## When Do You Need Both?

### ✅ Both Backends Required For:
- **PDF Analyzer features** (AI queries, summaries, flashcards, MCQs)
- Full application functionality

### ⚠️ Django Backend Only For:
- Authentication (login, register, profile)
- PDF to Audio conversion
- Quiz creation and management
- Basic PDF upload (without AI analysis)

**Note:** PDF Analyzer endpoints will fail if FastAPI backend is not running.

## Setup Instructions

### 1. Django Backend Setup

```bash
# Navigate to Django backend
cd lms_backend

# Activate virtual environment (if using one)
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Run Django server (Port 8000)
python manage.py runserver
```

### 2. FastAPI Backend Setup

```bash
# Navigate to FastAPI backend
cd pdf_analyzer_backend/backend

# Activate virtual environment (if using one)
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run FastAPI server (MUST be on Port 8080)
uvicorn main:app --reload --port 8080
```

**⚠️ Important:** The FastAPI backend MUST run on port **8080** (not 8000) because:
- Django backend uses port 8000 by default
- Django's `fastapi_service.py` is configured to connect to `http://localhost:8080`
- Running both on port 8000 will cause a port conflict

## Running Both Backends

### Option 1: Using Startup Scripts (Easiest - Windows)

**Terminal 1 - Django Backend:**
```powershell
cd lms_backend
.\start_server.ps1
```
Or double-click `start_server.bat` in Windows Explorer

**Terminal 2 - FastAPI Backend:**
```powershell
cd pdf_analyzer_backend/backend
.\start_server.ps1
```
Or double-click `start_server.bat` in Windows Explorer

### Option 2: Manual Commands

**Terminal 1 - Django Backend:**
```powershell
cd lms_backend
.\venv\Scripts\Activate.ps1
python manage.py runserver
```

**Terminal 2 - FastAPI Backend (Port 8080):**
```powershell
cd pdf_analyzer_backend/backend
.\venv\Scripts\Activate.ps1
uvicorn main:app --reload --port 8080
```

**⚠️ Important:** 
- You MUST activate the virtual environment first (`.venv\Scripts\Activate.ps1` or `venv\Scripts\activate.bat`)
- FastAPI backend MUST run on port **8080** (not the default 8000) to avoid conflicts with Django backend
- If `uvicorn` is not recognized, activate the virtual environment first

### Option 3: Background Processes (Windows PowerShell)

**Terminal 1:**
```powershell
cd lms_backend
Start-Process python -ArgumentList "manage.py runserver" -WindowStyle Normal
```

**Terminal 2:**
```powershell
cd pdf_analyzer_backend/backend
Start-Process uvicorn -ArgumentList "main:app --reload --port 8080" -WindowStyle Normal
```

## Environment Variables

### Django Backend (.env in lms_backend/)
```env
SECRET_KEY=your-secret-key
GEMINI_API_KEY=your-gemini-api-key
```

### FastAPI Backend (.env in pdf_analyzer_backend/backend/)
```env
GOOGLE_GEMINI_KEY=your-gemini-api-key
```

## Port Configuration

**Important:** The FastAPI backend must run on port **8080** because the Django backend's `fastapi_service.py` is configured to connect to `http://localhost:8080`.

### Change Django Backend Port:
```bash
python manage.py runserver 8001  # Use port 8001 instead
```

### Change FastAPI Backend Port (if needed):
1. Update `lms_backend/apps/pdf_analyzer/fastapi_service.py`:
   ```python
   self.base_url = 'http://localhost:8081'  # Change to new port
   ```
2. Run FastAPI backend with the new port:
   ```bash
   uvicorn main:app --reload --port 8081
   ```

**Note:** The Dockerfile uses port 8000, but for local development, use port 8080 to avoid conflicts with Django.

## Verifying Backends Are Running

### Check Django Backend:
```bash
curl http://localhost:8000/
# Should return API documentation JSON
```

### Check FastAPI Backend:
```bash
curl http://localhost:8080/docs
# Should return FastAPI Swagger documentation
```

## Troubleshooting

### Issue: PDF Analyzer endpoints return errors
**Solution:** Ensure FastAPI backend is running on port 8080

### Issue: Connection refused to FastAPI backend
**Solution:** 
1. Check if FastAPI backend is running: `curl http://localhost:8080/docs`
2. Verify port 8080 is not used by another application
3. Check firewall settings

### Issue: Django backend fails to start
**Solution:**
1. Check if port 8000 is available
2. Run migrations: `python manage.py migrate`
3. Check for missing dependencies: `pip install -r requirements.txt`

## API Endpoints

### Django Backend (http://localhost:8000)
- `/api/auth/` - Authentication
- `/api/pdf/` - PDF Converter
- `/api/quiz/` - Quiz System
- `/api/pdf-analyzer/` - PDF Analyzer (requires FastAPI backend)

### FastAPI Backend (http://localhost:8080)
- `/upload-pdf/` - Upload and index PDF
- `/ask-question/` - Query PDF with AI
- `/generate-flashcards/` - Generate flashcards
- `/generate-mcqs/` - Generate MCQs
- `/docs` - API documentation (Swagger UI)

