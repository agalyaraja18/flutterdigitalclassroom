# Flutter App - PDF Analysis Update Guide

## Changes Needed in Flutter App

### 1. Update API Constants

**File:** `lms_flutter_app/lib/core/constants/app_constants.dart`

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/';
  
  // PDF Analysis endpoints (NEW - replaces old pdf-analyzer)
  static const String pdfAnalysisBaseUrl = 'http://localhost:8000/api/pdf-analysis/';
  
  // Endpoints
  static const String authEndpoint = 'auth';
  static const String pdfEndpoint = 'pdf';
  static const String quizEndpoint = 'quiz';
  static const String pdfAnalysisEndpoint = 'pdf-analysis';
}
```

### 2. Update PDF Analysis Service

The new API has a different flow:

**Old Flow (FastAPI):**
1. Upload PDF → Get session_id
2. Ask question with session_id → Get immediate answer

**New Flow (Django + Gemini):**
1. Upload PDF → Get file_id
2. Analyze with file_id → Get request_id (async)
3. Check status with request_id → Get result

**Example Service Implementation:**

```dart
class PdfAnalysisService {
  final Dio _dio;
  final String baseUrl = 'http://localhost:8000/api/pdf-analysis/';
  
  PdfAnalysisService(this._dio);
  
  // 1. Upload PDF
  Future<String> uploadPdf(File pdfFile, {Map<String, dynamic>? metadata}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(pdfFile.path),
      'metadata': jsonEncode(metadata ?? {}),
    });
    
    final response = await _dio.post(
      '${baseUrl}upload',
      data: formData,
    );
    
    return response.data['file_id'];
  }
  
  // 2. Analyze PDF
  Future<String> analyzePdf({
    required String fileId,
    required String task, // 'summarize', 'explain', 'answer'
    Map<String, dynamic>? taskOptions,
    String responseFormat = 'text',
  }) async {
    final response = await _dio.post(
      '${baseUrl}analyze',
      data: {
        'file_id': fileId,
        'task': task,
        'task_options': taskOptions ?? {},
        'response_format': responseFormat,
      },
    );
    
    return response.data['request_id'];
  }
  
  // 3. Check Status
  Future<Map<String, dynamic>> checkStatus(String requestId) async {
    final response = await _dio.get('${baseUrl}status/$requestId');
    return response.data;
  }
  
  // Helper: Wait for result
  Future<Map<String, dynamic>> waitForResult(String requestId, {
    Duration pollInterval = const Duration(seconds: 2),
    int maxAttempts = 30,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final status = await checkStatus(requestId);
      
      if (status['status'] == 'done') {
        return status['result'];
      } else if (status['status'] == 'error') {
        throw Exception(status['error'] ?? 'Analysis failed');
      }
      
      await Future.delayed(pollInterval);
    }
    
    throw TimeoutException('Analysis timed out');
  }
  
  // Convenience methods
  Future<String> summarizePdf(String fileId, {String length = 'medium'}) async {
    final requestId = await analyzePdf(
      fileId: fileId,
      task: 'summarize',
      taskOptions: {'summarize_length': length},
    );
    
    final result = await waitForResult(requestId);
    return result['content'];
  }
  
  Future<String> explainTopic(String fileId, String topic) async {
    final requestId = await analyzePdf(
      fileId: fileId,
      task: 'explain',
      taskOptions: {'explain_topic': topic},
    );
    
    final result = await waitForResult(requestId);
    return result['content'];
  }
  
  Future<String> answerQuestion(String fileId, String question) async {
    final requestId = await analyzePdf(
      fileId: fileId,
      task: 'answer',
      taskOptions: {'question': question},
    );
    
    final result = await waitForResult(requestId);
    return result['content'];
  }
}
```

### 3. Update UI Flow

**Example Usage in Widget:**

```dart
class PdfAnalyzerScreen extends StatefulWidget {
  @override
  _PdfAnalyzerScreenState createState() => _PdfAnalyzerScreenState();
}

class _PdfAnalyzerScreenState extends State<PdfAnalyzerScreen> {
  final PdfAnalysisService _service = PdfAnalysisService(Dio());
  String? _fileId;
  bool _isLoading = false;
  String? _result;
  
  Future<void> _uploadPdf() async {
    setState(() => _isLoading = true);
    
    try {
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null) {
        final file = File(result.files.single.path!);
        
        // Upload
        _fileId = await _service.uploadPdf(file);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _summarize() async {
    if (_fileId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final summary = await _service.summarizePdf(_fileId!);
      setState(() => _result = summary);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _askQuestion(String question) async {
    if (_fileId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final answer = await _service.answerQuestion(_fileId!, question);
      setState(() => _result = answer);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Analysis')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadPdf,
              child: Text('Upload PDF'),
            ),
            if (_fileId != null) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _summarize,
                child: Text('Summarize'),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ask a question',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _isLoading ? null : () {
                      // Get question from text field
                      _askQuestion('Your question here');
                    },
                  ),
                ),
              ),
            ],
            if (_isLoading)
              CircularProgressIndicator()
            else if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_result!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Task Types and Options

**Summarize:**
```dart
taskOptions: {
  'summarize_length': 'short' | 'medium' | 'long'
}
```

**Explain:**
```dart
taskOptions: {
  'explain_topic': 'topic name or concept'
}
```

**Answer:**
```dart
taskOptions: {
  'question': 'your question here'
}
```

### 5. Response Format Options

- `'text'` - Plain text response (default)
- `'json'` - Structured JSON response
- `'bulleted'` - Bulleted list format

### 6. Error Handling

Common errors to handle:
- `503 Service Unavailable` - AI service not configured
- `404 Not Found` - File ID or request ID not found
- `400 Bad Request` - Invalid parameters
- `401 Unauthorized` - Missing or invalid token

## Testing

1. Start Django server: `python lms_backend/manage.py runserver`
2. Run Flutter app
3. Test upload → analyze → check status flow
4. Verify results display correctly

## Migration from Old API

If you have existing code using the old `/api/pdf-analyzer/` endpoints:

**Old:** `/api/pdf-analyzer/upload-pdf/` → **New:** `/api/pdf-analysis/upload`
**Old:** `/api/pdf-analyzer/query/` → **New:** `/api/pdf-analysis/analyze` (with task='answer')
**Old:** `/api/pdf-analyzer/summary/` → **New:** `/api/pdf-analysis/analyze` (with task='summarize')

The main difference is the async nature of the new API - you need to poll the status endpoint to get results.
