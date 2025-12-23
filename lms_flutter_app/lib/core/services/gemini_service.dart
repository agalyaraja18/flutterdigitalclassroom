import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  String? _pdfContent;

  GeminiService({String? apiKey}) {
    final key = apiKey ?? _defaultApiKey;
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: key,
    );
    _chatSession = _model.startChat();
  }

  /// Initialize the PDF content for analysis
  void initializePdfContext(String pdfContent) {
    _pdfContent = pdfContent;
    // Start a new chat session with the PDF context
    _chatSession = _model.startChat(
      history: [
        Content.text(
          'I have uploaded a PDF document. Here is its content:\n\n$pdfContent\n\n'
          'Please analyze this document and answer any questions I have about it. '
          'Provide detailed and accurate answers based on the content.',
        ),
        Content.model([
          TextPart(
            'I have received and analyzed the PDF document content. '
            'I\'m ready to answer your questions about this document. '
            'Feel free to ask me anything about the content, and I\'ll provide detailed answers.',
          ),
        ]),
      ],
    );
  }

  /// Send a query about the PDF
  Future<String> queryPdf(String query) async {
    try {
      if (_pdfContent == null || _pdfContent!.isEmpty) {
        return 'Please upload a PDF document first.';
      }

      final response = await _chatSession.sendMessage(
        Content.text(query),
      );

      return response.text ?? 'No response received from AI.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Reset the chat session
  void resetChat() {
    _chatSession = _model.startChat();
    _pdfContent = null;
  }

  /// Get a summary of the PDF
  Future<String> summarizePdf() async {
    try {
      if (_pdfContent == null || _pdfContent!.isEmpty) {
        return 'Please upload a PDF document first.';
      }

      return await queryPdf(
        'Please provide a comprehensive summary of this document, '
        'highlighting the key points, main topics, and important information.',
      );
    } catch (e) {
      return 'Error generating summary: ${e.toString()}';
    }
  }

  /// Check if PDF is loaded
  bool get isPdfLoaded => _pdfContent != null && _pdfContent!.isNotEmpty;

  /// Get PDF content
  String? get pdfContent => _pdfContent;
}
