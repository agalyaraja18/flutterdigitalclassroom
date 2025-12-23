import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/models/pdf_document_model.dart';

enum PdfConverterState {
  loading,
  loaded,
  uploading,
  error,
}

class PdfProvider extends ChangeNotifier {
  PdfConverterState _state = PdfConverterState.loading;
  List<PdfDocument> _documents = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ApiService _apiService = ApiService();

  PdfConverterState get state => _state;
  List<PdfDocument> get documents => _documents;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PdfConverterState.loading;
  bool get isUploading => _state == PdfConverterState.uploading;
  bool get hasMorePages => _hasMorePages;

  PdfProvider() {
    _apiService.init();
    loadDocuments();

    // Fallback: force error state if still loading after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (_state == PdfConverterState.loading) {
        if (kDebugMode) {
          print('PdfProvider: Forcing timeout after 15 seconds');
        }
        _setError('Connection timeout. Please refresh and try again.');
      }
    });
  }

  Future<void> loadDocuments({bool refresh = false}) async {
    try {
      if (kDebugMode) {
        print('PdfProvider: Starting loadDocuments, refresh=$refresh');
      }

      if (refresh) {
        _currentPage = 1;
        _hasMorePages = true;
        _documents.clear();
      }

      _state = PdfConverterState.loading;
      _errorMessage = null;
      notifyListeners();

      if (kDebugMode) {
        print('PdfProvider: Making API call to getPdfDocuments');
      }

      final response = await _apiService.getPdfDocuments(page: _currentPage).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Unable to load documents');
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (kDebugMode) {
          print('PdfProvider: API response received: ${response.statusCode}');
          print('PdfProvider: Response data type: ${data.runtimeType}');
          print('PdfProvider: Response data: $data');
        }

        if (data is Map<String, dynamic>) {
          // Paginated response
          final results = data['results'] as List<dynamic>? ?? [];
          final documents = results
              .map((doc) => PdfDocument.fromJson(doc as Map<String, dynamic>))
              .toList();

          if (kDebugMode) {
            print('PdfProvider: Parsed ${documents.length} documents');
          }

          if (refresh) {
            _documents = documents;
          } else {
            _documents.addAll(documents);
          }

          _hasMorePages = data['next'] != null;
          if (_hasMorePages) {
            _currentPage++;
          }
        } else if (data is List<dynamic>) {
          // Non-paginated response
          final documents = data
              .map((doc) => PdfDocument.fromJson(doc as Map<String, dynamic>))
              .toList();

          if (kDebugMode) {
            print('PdfProvider: Parsed ${documents.length} documents (non-paginated)');
          }

          _documents = documents;
          _hasMorePages = false;
        }

        _state = PdfConverterState.loaded;
        if (kDebugMode) {
          print('PdfProvider: State changed to loaded');
        }
        // Notify listeners after successful load so UI updates
        notifyListeners();
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
      if (kDebugMode) {
        print('Load documents error: $e');
      }
    }
  }

  Future<void> loadMoreDocuments() async {
    if (!_hasMorePages || _state == PdfConverterState.loading) return;
    await loadDocuments();
  }

  Future<bool> uploadPdf(File file, String title) async {
    try {
      _state = PdfConverterState.uploading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.uploadPdf(file, title);

      if (response.statusCode == 201) {
        final documentData = response.data as Map<String, dynamic>;
        final newDocument = PdfDocument.fromJson(documentData);

        // Add the new document to the beginning of the list
        _documents.insert(0, newDocument);
        _state = PdfConverterState.loaded;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to upload PDF');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          // Extract first error message
          for (final key in errorData.keys) {
            final errors = errorData[key];
            if (errors is List && errors.isNotEmpty) {
              _setError(errors.first.toString());
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
      if (kDebugMode) {
        print('Upload PDF error: $e');
      }
      return false;
    }
  }

  // Web-compatible upload method using PlatformFile
  Future<bool> uploadPdfFromPlatformFile(PlatformFile platformFile, String title) async {
    try {
      _state = PdfConverterState.uploading;
      _errorMessage = null;
      notifyListeners();

      Response response;

      if (kIsWeb && platformFile.bytes != null) {
        // For web, use bytes
        response = await _apiService.uploadPdfFromBytes(
          platformFile.bytes!,
          platformFile.name,
          title,
        );
      } else if (platformFile.path != null) {
        // For mobile/desktop, use file path
        final file = File(platformFile.path!);
        response = await _apiService.uploadPdf(file, title);
      } else {
        _setError('Unable to access file');
        return false;
      }

      if (response.statusCode == 201) {
        final documentData = response.data as Map<String, dynamic>;
        final newDocument = PdfDocument.fromJson(documentData);

        // Add the new document to the beginning of the list
        _documents.insert(0, newDocument);
        _state = PdfConverterState.loaded;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to upload PDF');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          // Extract first error message
          for (final key in errorData.keys) {
            final errors = errorData[key];
            if (errors is List && errors.isNotEmpty) {
              _setError(errors.first.toString());
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
      if (kDebugMode) {
        print('Upload PDF error: $e');
      }
      return false;
    }
  }

  Future<bool> deleteDocument(int documentId) async {
    try {
      final response = await _apiService.deletePdfDocument(documentId);

      if (response.statusCode == 200) {
        // Remove the document from the list
        _documents.removeWhere((doc) => doc.id == documentId);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete document');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else if (e.response?.statusCode == 404) {
        _setError('Document not found');
      } else {
        _setError('Network error. Please check your connection.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Delete document error: $e');
      }
      return false;
    }
  }

  Future<bool> retryConversion(int documentId) async {
    try {
      final response = await _apiService.retryPdfConversion(documentId);

      if (response.statusCode == 200) {
        final documentData = response.data as Map<String, dynamic>;
        final updatedDocument = PdfDocument.fromJson(documentData);

        // Update the document in the list
        final index = _documents.indexWhere((doc) => doc.id == documentId);
        if (index != -1) {
          _documents[index] = updatedDocument;
          notifyListeners();
        }
        return true;
      } else {
        _setError('Failed to retry conversion');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else if (e.response?.statusCode == 404) {
        _setError('Document not found');
      } else {
        _setError('Network error. Please check your connection.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Retry conversion error: $e');
      }
      return false;
    }
  }

  void refreshDocumentStatus(int documentId) async {
    try {
      final response = await _apiService.getPdfDocument(documentId);

      if (response.statusCode == 200) {
        final documentData = response.data as Map<String, dynamic>;
        final updatedDocument = PdfDocument.fromJson(documentData);

        // Update the document in the list
        final index = _documents.indexWhere((doc) => doc.id == documentId);
        if (index != -1) {
          _documents[index] = updatedDocument;
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently fail for status updates
      if (kDebugMode) {
        print('Refresh document status error: $e');
      }
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = PdfConverterState.error;
    if (kDebugMode) {
      print('PdfProvider: Error occurred: $message');
      print('PdfProvider: State changed to error');
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == PdfConverterState.error) {
      _state = PdfConverterState.loaded;
      notifyListeners();
    }
  }

  void startPollingForUpdates() {
    // Poll for updates every 10 seconds for documents that are processing
    Future.delayed(const Duration(seconds: 10), () {
      final processingDocs = _documents.where((doc) =>
          doc.isProcessing || doc.isPending).toList();

      for (final doc in processingDocs) {
        refreshDocumentStatus(doc.id);
      }

      // Continue polling if there are still processing documents
      if (processingDocs.isNotEmpty) {
        startPollingForUpdates();
      }
    });
  }
}