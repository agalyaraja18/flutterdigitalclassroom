# PDF Analysis Module Setup Guide

## Prerequisites
- Python environment with Django installed
- Google Gemini API key (already configured in `.env` file)
- `google-generativeai` package installed (already in requirements.txt)

## Step-by-Step Setup

### 1. Run Database Migrations
Apply the new database migrations for the PDF Analysis module:

```bash
python manage.py migrate pdf_analyzer
```

Or migrate all apps:
```bash
python manage.py migrate
```

### 2. Verify Environment Variables
Check that your `.env` file contains:
```
AI_API_KEY=REDACTED_API_KEY
```

### 3. Start the Django Server
```bash
python manage.py runserver
```

The server will start on `http://127.0.0.1:8000/`

## API Endpoints

Once the server is running, you can use these endpoints:

### 1. Upload PDF
**POST** `/api/pdf-analysis/upload`
- Content-Type: `multipart/form-data`
- Headers: `Authorization: Token <your_auth_token>`
- Body:
  - `file`: PDF file (max 50MB)
  - `metadata`: (optional) JSON string, e.g., `{"title": "Lecture 1"}`

**Response:**
```json
{
  "file_id": "uuid-string",
  "status": "success",
  "message": "PDF uploaded successfully"
}
```

### 2. Analyze PDF
**POST** `/api/pdf-analysis/analyze`
- Content-Type: `application/json`
- Headers: `Authorization: Token <your_auth_token>`
- Body:
```json
{
  "file_id": "uuid-from-upload",
  "task": "summarize",  // or "explain" or "answer"
  "task_options": {
    "summarize_length": "short",  // for summarize: "short", "medium", or "long"
    "explain_topic": "topic name",  // required for explain
    "question": "your question"  // required for answer
  },
  "response_format": "text"  // or "json" or "bulleted"
}
```

**Response:**
```json
{
  "request_id": "uuid-string",
  "status": "queued",
  "result": null,
  "model_used": null,
  "cost_estimate": null
}
```

### 3. Check Analysis Status
**GET** `/api/pdf-analysis/status/{request_id}`
- Headers: `Authorization: Token <your_auth_token>`

**Response:**
```json
{
  "request_id": "uuid-string",
  "status": "done",  // or "queued", "processing", "error"
  "result": {
    "type": "summary",
    "content": "Analysis result...",
    "references": [
      {
        "page": 1,
        "text_snippet": "..."
      }
    ]
  },
  "error": null
}
```

## Optional: Setup Cleanup Task

To automatically clean up expired documents (older than 1 hour), you can set up a cron job or scheduled task:

**Windows (Task Scheduler):**
```powershell
python manage.py cleanup_expired_documents
```

**Linux/Mac (Cron):**
Add to crontab (runs every hour):
```
0 * * * * cd /path/to/lms_backend && python manage.py cleanup_expired_documents
```

Or run manually:
```bash
python manage.py cleanup_expired_documents
```

Dry run (see what would be deleted without deleting):
```bash
python manage.py cleanup_expired_documents --dry-run
```

## Testing the API

### Using curl:

1. **Get Auth Token** (if you don't have one):
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "your_username", "password": "your_password"}'
```

2. **Upload PDF**:
```bash
curl -X POST http://127.0.0.1:8000/api/pdf-analysis/upload \
  -H "Authorization: Token YOUR_TOKEN_HERE" \
  -F "file=@/path/to/your/document.pdf" \
  -F "metadata={\"title\": \"Test Document\"}"
```

3. **Analyze PDF**:
```bash
curl -X POST http://127.0.0.1:8000/api/pdf-analysis/analyze \
  -H "Authorization: Token YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "file_id": "FILE_ID_FROM_UPLOAD",
    "task": "summarize",
    "task_options": {"summarize_length": "short"},
    "response_format": "text"
  }'
```

4. **Check Status**:
```bash
curl -X GET http://127.0.0.1:8000/api/pdf-analysis/status/REQUEST_ID \
  -H "Authorization: Token YOUR_TOKEN_HERE"
```

## Troubleshooting

1. **Migration errors**: Make sure you're in the `lms_backend` directory
2. **API key errors**: Verify `AI_API_KEY` is set in `.env` file
3. **Import errors**: Install dependencies: `pip install -r requirements.txt`
4. **Permission errors**: Make sure the `media/` directory is writable

## Admin Interface

You can also view and manage PDF Analysis documents and requests through Django admin:
- URL: `http://127.0.0.1:8000/admin/`
- Login with your admin credentials
- Navigate to "PDF Analyzer" section

