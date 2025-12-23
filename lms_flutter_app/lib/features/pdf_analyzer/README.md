# PDF Analyzer Module

AI-powered PDF analysis using Google's Gemini API. This module allows users to upload PDF documents and interact with them using natural language queries.

## Features

- 📄 **PDF Upload**: Select and upload PDF documents
- 🤖 **AI Analysis**: Powered by Google Gemini AI
- 💬 **Chat Interface**: Ask questions about the PDF in a conversational manner
- 📝 **Auto Summary**: Generate comprehensive summaries of documents
- 🎯 **Smart Suggestions**: Quick action chips for common queries
- 🎨 **Beautiful UI**: Modern chat interface with message bubbles

## Setup Instructions

### 1. Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key

### 2. Configure the API Key

When you first upload a PDF, the app will prompt you to enter your Gemini API key. You can also:

**Option A: Hardcode (for development only)**
Edit `lib/core/services/gemini_service.dart` and replace:
```dart
static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

**Option B: Use Environment Variables (recommended)**
- Create a `.env` file in the project root
- Add: `GEMINI_API_KEY=your_api_key_here`
- Update the service to read from environment variables

### 3. Usage

1. Navigate to the Dashboard
2. Click on the "PDF Analyzer" card
3. Upload a PDF document
4. Start asking questions!

## Example Queries

- "What is this document about?"
- "Summarize the key points"
- "Explain [specific topic] from the document"
- "What are the main conclusions?"
- "List the important facts mentioned"

## Technical Details

### Dependencies
- `google_generative_ai: ^0.2.2` - Google's Gemini API
- `syncfusion_flutter_pdf: ^24.1.41` - PDF text extraction
- `file_picker: ^6.1.1` - File selection

### Architecture
```
pdf_analyzer/
├── models/
│   └── chat_message.dart       # Chat message model
├── presentation/
│   └── screens/
│       └── pdf_analyzer_screen.dart  # Main screen
└── README.md
```

### Services
- `GeminiService` (lib/core/services/gemini_service.dart)
  - Handles AI interactions
  - Manages chat sessions
  - PDF content context management

## Limitations

- PDF must contain extractable text (scanned images won't work without OCR)
- File size should be reasonable (Gemini has token limits)
- API rate limits apply based on your Google AI Studio plan

## Future Enhancements

- [ ] OCR support for scanned PDFs
- [ ] Multiple PDF comparison
- [ ] Export chat history
- [ ] Highlight relevant sections in PDF
- [ ] Voice input for queries
- [ ] Save favorite queries
- [ ] Share analysis results

## Troubleshooting

**Problem**: "Error loading PDF"
- **Solution**: Ensure the PDF contains text (not just images)

**Problem**: "API Key error"
- **Solution**: Verify your API key is correct and active

**Problem**: "No response from AI"
- **Solution**: Check internet connection and API quota

## Support

For issues or questions, please check:
- Google Gemini API documentation
- Syncfusion PDF documentation
- Project GitHub issues
