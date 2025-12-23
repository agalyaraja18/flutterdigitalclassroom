// PdfAnalyzerProvider: clean provider for interacting with the backend pdf-analyzer
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/api_service.dart';
import '../../domain/models/analyzer_document.dart';
import '../../domain/models/chat_session.dart' as domain_session;
import '../../models/chat_message.dart' as ui_models;

enum AnalyzerState { loading, loaded, uploading, error }

class PdfAnalyzerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AnalyzerState _state = AnalyzerState.loading;
  List<AnalyzerDocument> _documents = [];
  String? _errorMessage;

  domain_session.ChatSession? _chatSession;
  List<ui_models.ChatMessage> _uiMessages = [];

  Timer? _pollTimer;
  Timer? _docPollTimer;

  AnalyzerState get state => _state;
  List<AnalyzerDocument> get documents => _documents;
  String? get errorMessage => _errorMessage;
  domain_session.ChatSession? get chatSession => _chatSession;
  List<ui_models.ChatMessage> get uiMessages => _uiMessages;

  bool get isLoading => _state == AnalyzerState.loading;
  bool get isUploading => _state == AnalyzerState.uploading;

  // UI-friendly aliases expected by the screen
  List<ui_models.ChatMessage> get messages => _uiMessages;
  // Consider a session present as "active" for the UI so users can ask
  // questions as soon as a session exists on the backend. The backend may
  // toggle `is_active` separately, but queries work with a session id.
  bool get hasActiveSession => _chatSession != null;
  String? get currentPdfTitle => _chatSession?.pdfTitle;

  PdfAnalyzerProvider() {
    try {
      _apiService.init();
    } catch (_) {}
    loadDocuments();

    Future.delayed(const Duration(seconds: 15), () {
      if (_state == AnalyzerState.loading) {
        _setError('Connection timeout. Please refresh and try again.');
      }
    });
  }

  Future<void> loadDocuments({bool refresh = false}) async {
    try {
      if (refresh) _documents.clear();

      _state = AnalyzerState.loading;
      _errorMessage = null;
      notifyListeners();

      final resp = await _apiService.getMyPdfDocuments().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        List<AnalyzerDocument> docs = [];
        if (data is List) {
          docs = data.map((d) => AnalyzerDocument.fromJson(d as Map<String, dynamic>)).toList();
        } else if (data is Map<String, dynamic>) {
          // Handle FastAPI response format: {"indexes": [{"id": "uuid", "name": "filename"}]}
          if (data.containsKey('indexes')) {
            final indexes = data['indexes'] as List<dynamic>? ?? [];
            docs = indexes.map((idx) {
              final idxMap = idx as Map<String, dynamic>;
              return AnalyzerDocument(
                id: idxMap['id'].hashCode, // Use hash of UUID as temporary ID
                title: idxMap['name'] as String,
                pdfFile: idxMap['name'] as String,
                uploadDate: DateTime.now(),
                lastQueried: null,
                uploadedByUsername: 'current_user',
                isActive: true,
                conversionStatus: 'done',
                sessionId: idxMap['id'] as String, // Use UUID as session_id
              );
            }).toList();
          } else {
            // Handle Django backend response format
            final results = data['results'] as List<dynamic>? ?? [];
            docs = results.map((d) => AnalyzerDocument.fromJson(d as Map<String, dynamic>)).toList();
          }
        }
        _documents = docs;
        _state = AnalyzerState.loaded;

        // If any existing document already has a session id, load its chat
        // history so the UI becomes interactive immediately. This helps when
        // the backend created sessions earlier and the client needs to pick
        // them up on start.
        // try {
        //   if (_chatSession == null) {
        //     final docWithSession = _documents.firstWhere((d) => d.sessionId != null && d.sessionId!.isNotEmpty);
        //     // load chat and start polling; ignore errors here (best-effort)
        //     await getChatHistory(docWithSession.sessionId!);
        //     startPolling(docWithSession.sessionId!);
        //   }
        // } catch (_) {
        //   // no document with session found — that's fine
        // }
      } else {
        _setError('Failed to load documents');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else {
        _setError('Network error. Please check your connection.');
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) print('loadDocuments error: $e');
    }
    notifyListeners();
  }

  Future<bool> uploadPdf(File file, String title) async {
    try {
      _state = AnalyzerState.uploading;
      _errorMessage = null;
      notifyListeners();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
      });

      final resp = await _apiService.uploadPdfForAnalysis(title: title, pdfFile: formData);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          final data = resp.data as Map<String, dynamic>;

          // Handle FastAPI response format: {"message": "...", "index_id": "...", "file_name": "..."}
          if (data.containsKey('index_id') && data.containsKey('file_name')) {
            // FastAPI backend response
            final indexId = data['index_id'] as String;
            final fileName = data['file_name'] as String;

            // Create a minimal AnalyzerDocument
            final created = AnalyzerDocument(
              id: DateTime.now().millisecondsSinceEpoch, // Generate a temporary ID
              title: title, // Use the title from the form
              pdfFile: fileName,
              uploadDate: DateTime.now(),
              lastQueried: null,
              uploadedByUsername: 'current_user',
              isActive: true,
              conversionStatus: 'done',
              sessionId: indexId, // Use index_id as session_id
            );

            _documents.insert(0, created);

            // Create a minimal ChatSession
            _chatSession = domain_session.ChatSession(
              id: 0,
              sessionId: indexId,
              pdfDocument: created.id,
              pdfTitle: title,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              messages: [],
            );

            _uiMessages.clear();
            _state = AnalyzerState.loaded;
            notifyListeners();
            return true;
          }

          // Handle Django backend response format
          final respMap = data;
      final docJson = respMap.containsKey('pdf_document') && respMap['pdf_document'] is Map<String, dynamic>
        ? respMap['pdf_document'] as Map<String, dynamic>
        : data;
      final created = AnalyzerDocument.fromJson(docJson);
          _documents.insert(0, created);

          if (data.containsKey('session') && data['session'] is Map<String, dynamic>) {
            try {
              _chatSession = domain_session.ChatSession.fromJson(data['session'] as Map<String, dynamic>);
              _uiMessages = _chatSession!.messages.map((dm) {
                return ui_models.ChatMessage(
                  content: dm.content,
                  isUser: dm.messageType.toLowerCase() == 'user',
                  timestamp: dm.timestamp,
                  isLoading: false,
                );
              }).toList();
              startPolling(_chatSession!.sessionId);
            } catch (_) {
              if (created.sessionId != null && created.sessionId!.isNotEmpty) {
                startPolling(created.sessionId!);
              }
            }
          } else if (created.sessionId != null && created.sessionId!.isNotEmpty) {
            startPolling(created.sessionId!);
          }

          _state = AnalyzerState.loaded;
          notifyListeners();
        } catch (e) {
          if (kDebugMode) print('Upload response parsing error: $e');
          _setError('Failed to process upload response');
          return false;
        }

        return true;
      } else {
        _setError('Failed to upload PDF');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final err = e.response?.data;
        if (err is Map<String, dynamic>) {
          for (final k in err.keys) {
            final val = err[k];
            if (val is List && val.isNotEmpty) {
              _setError(val.first.toString());
              break;
            }
          }
        } else {
          _setError('Invalid file or data');
        }
      } else if (e.response?.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else {
        _setError('Network error. Please check your connection.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) print('uploadPdf error: $e');
      return false;
    }
  }

  Future<bool> uploadPdfFromPlatformFile(PlatformFile pf, String title) async {
    try {
      _state = AnalyzerState.uploading;
      _errorMessage = null;
      notifyListeners();

      Response resp;
      if (kIsWeb && pf.bytes != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(pf.bytes!, filename: pf.name),
        });
        resp = await _apiService.uploadPdfForAnalysis(title: title, pdfFile: formData);
      } else if (pf.path != null) {
        final file = File(pf.path!);
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
        });
        resp = await _apiService.uploadPdfForAnalysis(title: title, pdfFile: formData);
      } else {
        _setError('Unable to access file');
        return false;
      }

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          final data = resp.data as Map<String, dynamic>;

          // Handle FastAPI response format: {"message": "...", "index_id": "...", "file_name": "..."}
          if (data.containsKey('index_id') && data.containsKey('file_name')) {
            // FastAPI backend response
            final indexId = data['index_id'] as String;
            final fileName = data['file_name'] as String;

            // Create a minimal AnalyzerDocument
            final created = AnalyzerDocument(
              id: DateTime.now().millisecondsSinceEpoch, // Generate a temporary ID
              title: title, // Use the title from the form
              pdfFile: fileName,
              uploadDate: DateTime.now(),
              lastQueried: null,
              uploadedByUsername: 'current_user',
              isActive: true,
              conversionStatus: 'done',
              sessionId: indexId, // Use index_id as session_id
            );

            _documents.insert(0, created);

            // Create a minimal ChatSession
            _chatSession = domain_session.ChatSession(
              id: 0,
              sessionId: indexId,
              pdfDocument: created.id,
              pdfTitle: title,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              messages: [],
            );

            _uiMessages.clear();
            _state = AnalyzerState.loaded;
            notifyListeners();
            return true;
          }

          // Handle Django backend response format
          final respMap = data;
      final docJson = respMap.containsKey('pdf_document') && respMap['pdf_document'] is Map<String, dynamic>
        ? respMap['pdf_document'] as Map<String, dynamic>
        : data;
      final created = AnalyzerDocument.fromJson(docJson);
          _documents.insert(0, created);

          if (data.containsKey('session') && data['session'] is Map<String, dynamic>) {
            try {
              _chatSession = domain_session.ChatSession.fromJson(data['session'] as Map<String, dynamic>);
              _uiMessages = _chatSession!.messages.map((dm) {
                return ui_models.ChatMessage(
                  content: dm.content,
                  isUser: dm.messageType.toLowerCase() == 'user',
                  timestamp: dm.timestamp,
                  isLoading: false,
                );
              }).toList();
              startPolling(_chatSession!.sessionId);
            } catch (_) {
              if (created.sessionId != null && created.sessionId!.isNotEmpty) {
                startPolling(created.sessionId!);
              }
            }
          } else if (created.sessionId != null && created.sessionId!.isNotEmpty) {
            startPolling(created.sessionId!);
          }

          _state = AnalyzerState.loaded;
          notifyListeners();
        } catch (e) {
          if (kDebugMode) print('Upload response parsing error: $e');
          _setError('Failed to process upload response');
          return false;
        }

        return true;
      } else {
        _setError('Failed to upload PDF');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _setError('Invalid file or data');
      } else if (e.response?.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else {
        _setError('Network error. Please check your connection.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) print('uploadPdfFromPlatformFile error: $e');
      return false;
    }
  }

  // Upload from raw bytes (used by web flow). Returns a record (success, errorMessage)
  Future<(bool, String?)> uploadPdfFromBytes({
    required String title,
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      _state = AnalyzerState.uploading;
      _errorMessage = null;
      notifyListeners();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final resp = await _apiService.uploadPdfForAnalysis(title: title, pdfFile: formData);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          final data = resp.data as Map<String, dynamic>;

          // Handle FastAPI response format: {"message": "...", "index_id": "...", "file_name": "..."}
          if (data.containsKey('index_id') && data.containsKey('file_name')) {
            // FastAPI backend response
            final indexId = data['index_id'] as String;
            final fileNameFromResp = data['file_name'] as String;

            // Create a minimal AnalyzerDocument
            final created = AnalyzerDocument(
              id: DateTime.now().millisecondsSinceEpoch, // Generate a temporary ID
              title: title, // Use the title from the form
              pdfFile: fileNameFromResp,
              uploadDate: DateTime.now(),
              lastQueried: null,
              uploadedByUsername: 'current_user',
              isActive: true,
              conversionStatus: 'done',
              sessionId: indexId, // Use index_id as session_id
            );

            _documents.insert(0, created);

            // Create a minimal ChatSession
            _chatSession = domain_session.ChatSession(
              id: 0,
              sessionId: indexId,
              pdfDocument: created.id,
              pdfTitle: title,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              messages: [],
            );

            _uiMessages.clear();
            _state = AnalyzerState.loaded;
            notifyListeners();
            return (true, null);
          }

          // Handle Django backend response format
          final respMap = data;
      final docJson = respMap.containsKey('pdf_document') && respMap['pdf_document'] is Map<String, dynamic>
        ? respMap['pdf_document'] as Map<String, dynamic>
        : data;
      final created = AnalyzerDocument.fromJson(docJson);
          _documents.insert(0, created);

          if (data.containsKey('session') && data['session'] is Map<String, dynamic>) {
            try {
              _chatSession = domain_session.ChatSession.fromJson(data['session'] as Map<String, dynamic>);
              _uiMessages = _chatSession!.messages.map((dm) {
                return ui_models.ChatMessage(
                  content: dm.content,
                  isUser: dm.messageType.toLowerCase() == 'user',
                  timestamp: dm.timestamp,
                  isLoading: false,
                );
              }).toList();
              startPolling(_chatSession!.sessionId);
            } catch (_) {
              if (created.sessionId != null && created.sessionId!.isNotEmpty) {
                startPolling(created.sessionId!);
              }
            }
          } else if (created.sessionId != null && created.sessionId!.isNotEmpty) {
            startPolling(created.sessionId!);
          }

          _state = AnalyzerState.loaded;
          notifyListeners();
        } catch (e) {
          if (kDebugMode) print('Upload response parsing error: $e');
          _setError('Failed to process upload response');
          return (false, 'Failed to process upload response');
        }
        return (true, null);
      } else {
        final msg = resp.data is Map<String, dynamic> ? (resp.data['detail']?.toString() ?? 'Failed to upload') : 'Failed to upload';
        _setError(msg);
        return (false, msg);
      }
    } on DioException catch (e) {
      String? msg;
      if (e.response?.statusCode == 400) {
        final err = e.response?.data;
        if (err is Map<String, dynamic>) {
          for (final k in err.keys) {
            final val = err[k];
            if (val is List && val.isNotEmpty) {
              msg = val.first.toString();
              break;
            }
          }
        } else {
          msg = 'Invalid file or data';
        }
      } else if (e.response?.statusCode == 401) {
        msg = 'Session expired. Please login again.';
      } else {
        msg = 'Network error. Please check your connection.';
      }
      _setError(msg!);
      return (false, msg);
    } catch (e) {
      const msg = 'An unexpected error occurred';
      _setError(msg);
      if (kDebugMode) print('uploadPdfFromBytes error: $e');
      return (false, msg);
    }
  }

  // Internal helper: send a query for a specific session
  Future<bool> _queryPdfWithSession(String sessionId, String query) async {
    try {
      // Add user message to UI immediately
      _uiMessages.add(ui_models.ChatMessage(
        content: query,
        isUser: true,
        timestamp: DateTime.now(),
        isLoading: false,
      ));

      // Add loading message for AI response
      _uiMessages.add(ui_models.ChatMessage(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
      notifyListeners();

      final resp = await _apiService.queryPdf(sessionId: sessionId, query: query);

      // Remove loading message
      _uiMessages.removeLast();

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final answer = data['answer'] as String? ?? 'No response received';

        // Add AI response
        _uiMessages.add(ui_models.ChatMessage(
          content: answer,
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: false,
        ));
        notifyListeners();
        return true;
      } else {
        _setError('Failed to send query');
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Remove loading message if present
      if (_uiMessages.isNotEmpty && _uiMessages.last.isLoading) {
        _uiMessages.removeLast();
      }
      _setError('An unexpected error occurred while querying');
      if (kDebugMode) print('queryPdf error: $e');
      notifyListeners();
      return false;
    }
  }

  // Internal helper: fetch summary for a specific session
  // Future<bool> _getSummaryForSession(String sessionId) async {
  //   try {
  //     final resp = await _apiService.getPdfSummary(sessionId);
  //     if (resp.statusCode == 200) {
  //       await getChatHistory(sessionId);
  //       return true;
  //     } else {
  //       _setError('Failed to fetch summary');
  //       return false;
  //     }
  //   } catch (e) {
  //     _setError('An unexpected error occurred while fetching summary');
  //     if (kDebugMode) print('getSummary error: $e');
  //     return false;
  //   }
  // }

  // Future<void> getChatHistory(String sessionId) async {
  //   try {
  //     final resp = await _apiService.getPdfChatHistory(sessionId);
  //     if (resp.statusCode == 200) {
  //       final data = resp.data;
  //
  //       if (data is Map<String, dynamic>) {
  //         // Prefer full session payload
  //         try {
  //           _chatSession = domain_session.ChatSession.fromJson(data);
  //         } catch (e) {
  //           // If payload is only messages/pdf_title, attempt to build a minimal session
  //           if (kDebugMode) print('ChatSession.fromJson failed, building fallback: $e');
  //           final msgs = (data['messages'] as List<dynamic>?) ?? [];
  //           _chatSession = domain_session.ChatSession(
  //             id: 0,
  //             sessionId: sessionId,
  //             pdfDocument: 0,
  //             pdfTitle: (data['pdf_title'] ?? data['pdfTitle'] ?? '').toString(),
  //             createdAt: DateTime.now(),
  //             updatedAt: DateTime.now(),
  //             isActive: true,
  //             messages: msgs.map((m) => domain_message.ChatMessage.fromJson(m as Map<String, dynamic>)).toList(),
  //           );
  //         }
  //       } else if (data is List) {
  //         // If the server returns only messages
  //         final msgs = data;
  //         _chatSession = domain_session.ChatSession(
  //           id: 0,
  //           sessionId: sessionId,
  //           pdfDocument: 0,
  //           pdfTitle: '',
  //           createdAt: DateTime.now(),
  //           updatedAt: DateTime.now(),
  //           isActive: true,
  //           messages: msgs.map((m) => domain_message.ChatMessage.fromJson(m as Map<String, dynamic>)).toList(),
  //         );
  //       } else {
  //         throw Exception('Unexpected chat history payload');
  //       }
  //
  //       _uiMessages = _chatSession!.messages.map((dm) {
  //         return ui_models.ChatMessage(
  //           content: dm.content,
  //           isUser: dm.messageType.toLowerCase() == 'user',
  //           timestamp: dm.timestamp,
  //           isLoading: false,
  //         );
  //       }).toList();
  //
  //       notifyListeners();
  //     } else {
  //       _setError('Failed to load chat history');
  //     }
  //   } catch (e) {
  //     _setError('An unexpected error occurred while loading chat history');
  //     if (kDebugMode) print('getChatHistory error: $e');
  //   }
  // }

  // Public query method used by UI: operates on the active session
  Future<(bool, String?)> queryPdf(String query) async {
    if (_chatSession == null) {
      const msg = 'No active session. Please upload a PDF first.';
      _setError(msg);
      return (false, msg);
    }
    final ok = await _queryPdfWithSession(_chatSession!.sessionId, query);
    return (ok, ok ? null : _errorMessage);
  }

  // Public summary method used by UI: operates on active session
  // Future<(bool, String?)> getSummary() async {
  //   if (_chatSession == null) {
  //     const msg = 'No active session. Please upload a PDF first.';
  //     _setError(msg);
  //     return (false, msg);
  //   }
  //   final ok = await _getSummaryForSession(_chatSession!.sessionId);
  //   return (ok, ok ? null : _errorMessage);
  // }

  void clearSession() {
    _chatSession = null;
    _uiMessages.clear();
    notifyListeners();
  }

  void selectDocument(AnalyzerDocument document) {
    // Set the document as the active session
    if (document.sessionId != null && document.sessionId!.isNotEmpty) {
      _chatSession = domain_session.ChatSession(
        id: document.id,
        sessionId: document.sessionId!,
        pdfDocument: document.id,
        pdfTitle: document.title,
        createdAt: document.uploadDate,
        updatedAt: document.uploadDate,
        isActive: document.isActive,
        messages: [],
      );
      
      // Clear previous messages and add welcome message for this document
      _uiMessages.clear();
      _uiMessages.add(ui_models.ChatMessage(
        content: 'Document "${document.title}" selected. Ask me anything about this PDF!',
        isUser: false,
        isLoading: false,
      ));
      
      notifyListeners();
    }
  }

  void addWelcomeMessage() {
    if (_uiMessages.isNotEmpty) return;
    _uiMessages.add(ui_models.ChatMessage(
      content: 'Welcome — upload a PDF to start analyzing. Try asking for a summary or key points.',
      isUser: false,
      isLoading: false,
    ));
    notifyListeners();
  }

  void startPolling(String sessionId, {Duration interval = const Duration(seconds: 5)}) {
    stopPolling();
    _pollTimer = Timer.periodic(interval, (_) async {
      // await getChatHistory(sessionId);
      if (_chatSession != null && !_chatSession!.isActive) stopPolling();
    });
  }

  void stopDocumentPolling() {
    _docPollTimer?.cancel();
    _docPollTimer = null;
  }

  void startDocumentPolling(int documentId, {Duration interval = const Duration(seconds: 3)}) {
    stopDocumentPolling();
    _docPollTimer = Timer.periodic(interval, (_) async {
      try {
        final resp = await _apiService.getPdfDocument(documentId);
        if (resp.statusCode == 200) {
          final data = resp.data as Map<String, dynamic>;
          // Build AnalyzerDocument using model factory which is resilient
          try {
            final updated = AnalyzerDocument.fromJson(data);
            // replace in _documents
            final idx = _documents.indexWhere((d) => d.id == updated.id);
            if (idx >= 0) {
              _documents[idx] = updated;
            } else {
              _documents.insert(0, updated);
            }

            // If backend provided a session id, load chat and start session polling
            final sid = updated.sessionId;
            if (sid != null && sid.isNotEmpty) {
              stopDocumentPolling();
              // await getChatHistory(sid);
              startPolling(sid);
            }
          } catch (e) {
            if (kDebugMode) print('document polling parse error: $e');
          }
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) print('document polling error: $e');
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = AnalyzerState.error;
    if (kDebugMode) print('PdfAnalyzerProvider error: $message');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AnalyzerState.error) _state = AnalyzerState.loaded;
    notifyListeners();
  }
}