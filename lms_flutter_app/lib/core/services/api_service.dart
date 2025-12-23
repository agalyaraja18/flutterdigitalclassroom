import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  late Dio _dioPdfAnalyzer;

  String _resolveBaseUrl(String base) {
    // If running on Android emulator, localhost should be accessed via 10.0.2.2
    try {
      if (!kIsWeb && Platform.isAndroid && base.contains('localhost')) {
        return base.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {
      // Platform lookup can throw on some platforms; fallback to base
    }
    return base;
  }

  void init() {
    final resolved = _resolveBaseUrl(AppConstants.baseUrl);
    final ensured = resolved.endsWith('/') ? resolved : '$resolved/';
    if (kDebugMode) {
      print('ApiService baseUrl => $ensured');
      print('PDF Analyzer baseUrl => ${_resolveBaseUrl(AppConstants.pdfAnalyzerBaseUrl)}');
    }
    _dio = Dio(BaseOptions(
      baseUrl: ensured,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // PDF Analyzer now uses Django backend (same as main API)
    _dioPdfAnalyzer = Dio(BaseOptions(
      baseUrl: _resolveBaseUrl(AppConstants.pdfAnalyzerBaseUrl),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    final interceptorsWrapper = InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await StorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Token $token';
          }

          if (kDebugMode) {
            print('REQUEST: ${options.method} ${options.uri}');
            print('HEADERS: ${options.headers}');
            print('AUTH TOKEN PRESENT: ${token != null}');
            if (options.data != null) {
              print('DATA: ${options.data}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
            print('DATA: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
            print('ERROR DATA: ${error.response?.data}');
          }
          handler.next(error);
        },
      );

    // Add interceptors
    _dio.interceptors.add(interceptorsWrapper);
    _dioPdfAnalyzer.interceptors.add(interceptorsWrapper);
  }

  // Authentication endpoints
  Future<Response> login(String username, String password) async {
    return await _dio.post(
      '${AppConstants.authEndpoint}/login/',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    // Normalize and ensure password confirmation fields are present
    final data = Map<String, dynamic>.from(userData);
    final dynamicConfirm = data['password_confirm'] ??
        data['confirm_password'] ??
        data['password2'] ??
        data['passwordConfirm'] ??
        data['password_confirmation'] ??
        data['password'];
    if (dynamicConfirm != null) {
      data['password_confirm'] = dynamicConfirm;
      // Add common alias for compatibility with some backends
      data['password2'] = dynamicConfirm;
    }

    return await _dio.post(
      '${AppConstants.authEndpoint}/register/',
      data: data,
    );
  }

  Future<Response> logout() async {
    return await _dio.post('${AppConstants.authEndpoint}/logout/');
  }

  Future<Response> getProfile() async {
    return await _dio.get('${AppConstants.authEndpoint}/profile/');
  }

  // PDF Converter endpoints
  Future<Response> uploadPdf(File file, String title) async {
    FormData formData = FormData.fromMap({
      'title': title,
      'pdf_file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    return await _dio.post(
      '${AppConstants.pdfEndpoint}/upload/',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        sendTimeout: const Duration(minutes: 5), // Increase timeout for file uploads
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }

  // Web-compatible PDF upload method
  Future<Response> uploadPdfFromBytes(List<int> bytes, String filename, String title) async {
    FormData formData = FormData.fromMap({
      'title': title,
      'pdf_file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });

    return await _dio.post(
      '${AppConstants.pdfEndpoint}/upload/',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        sendTimeout: const Duration(minutes: 5), // Increase timeout for file uploads
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }

  Future<Response> getPdfDocuments({int page = 1}) async {
    return await _dio.get(
      '${AppConstants.pdfEndpoint}/documents/',
      queryParameters: {'page': page},
    );
  }

  Future<Response> getPdfDocument(int documentId) async {
    return await _dio.get('${AppConstants.pdfEndpoint}/documents/$documentId/');
  }

  Future<Response> deletePdfDocument(int documentId) async {
    return await _dio.delete('${AppConstants.pdfEndpoint}/documents/$documentId/delete/');
  }

  Future<Response> retryPdfConversion(int documentId) async {
    return await _dio.post('${AppConstants.pdfEndpoint}/documents/$documentId/retry/');
  }

  // Quiz endpoints
  Future<Response> createQuiz(Map<String, dynamic> quizData) async {
    return await _dio.post(
      '${AppConstants.quizEndpoint}/create/',
      data: quizData,
    );
  }

  Future<Response> getMyQuizzes({int page = 1}) async {
    return await _dio.get(
      '${AppConstants.quizEndpoint}/my-quizzes/',
      queryParameters: {'page': page},
    );
  }

  Future<Response> getQuizDetail(String quizId) async {
    return await _dio.get('${AppConstants.quizEndpoint}/$quizId/');
  }

  Future<Response> joinQuiz(String quizCode) async {
    // Fallback: include token in body as well for environments where headers may be stripped
    final token = await StorageService.getToken();
    final payload = {
      'quiz_code': quizCode,
      if (token != null) 'token': token,
    };
    return await _dio.post(
      '${AppConstants.quizEndpoint}/join/',
      data: payload,
    );
  }

  Future<Response> getQuizSession(String sessionId) async {
    return await _dio.get('${AppConstants.quizEndpoint}/session/$sessionId/');
  }

  Future<Response> submitQuiz(String sessionId, List<Map<String, dynamic>> answers) async {
    return await _dio.post(
      '${AppConstants.quizEndpoint}/session/$sessionId/submit/',
      data: {'answers': answers},
    );
  }

  Future<Response> getQuizHistory({int page = 1}) async {
    return await _dio.get(
      '${AppConstants.quizEndpoint}/history/',
      queryParameters: {'page': page},
    );
  }

  Future<Response> getQuizAnalytics(String quizId) async {
    return await _dio.get('${AppConstants.quizEndpoint}/$quizId/analytics/');
  }

  // Live Quiz endpoints removed — frontend uses self-paced quiz endpoints only.

  // PDF Analyzer endpoints (using new Django backend)
  Future<Response> uploadPdfForAnalysis({
    required String title,
    required FormData pdfFile,
  }) async {
    // New Django endpoint expects 'file' field (not 'title' in form data)
    // Title can be passed as metadata if needed, but for now we'll just send the file
    return await _dioPdfAnalyzer.post(
      'upload',
      data: pdfFile,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        sendTimeout: const Duration(minutes: 5), // Increase timeout for file uploads
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
  }

  Future<Response> queryPdf({
    required String sessionId,
    required String query,
  }) async {
    // New Django endpoint uses file_id and task structure
    // Step 1: Submit the analysis request
    final analyzeResponse = await _dioPdfAnalyzer.post(
      'analyze',
      data: {
        'file_id': sessionId, // Using file_id from upload response
        'task': 'answer',
        'task_options': {
          'question': query,
        },
        'response_format': 'text',
      },
    );
    
    // Step 2: Get the request_id from response
    final requestId = analyzeResponse.data['request_id'] as String;
    
    // Step 3: Poll the status endpoint until we get a result
    int maxAttempts = 30; // 30 attempts with 2 second intervals = 1 minute max
    int attempt = 0;
    
    while (attempt < maxAttempts) {
      await Future.delayed(const Duration(seconds: 2));
      
      final statusResponse = await _dioPdfAnalyzer.get('status/$requestId');
      final status = statusResponse.data['status'] as String;
      
      if (status == 'done') {
        // Extract the answer from the result
        final result = statusResponse.data['result'] as Map<String, dynamic>?;
        final answer = result?['content'] as String? ?? 'No response received';
        
        // Return a response that matches what the Flutter app expects
        return Response(
          requestOptions: analyzeResponse.requestOptions,
          data: {
            'answer': answer,
            'request_id': requestId,
            'result': result,
          },
          statusCode: 200,
        );
      } else if (status == 'error') {
        final error = statusResponse.data['error'] as String? ?? 'Analysis failed';
        throw DioException(
          requestOptions: analyzeResponse.requestOptions,
          response: Response(
            requestOptions: analyzeResponse.requestOptions,
            data: {'error': error},
            statusCode: 500,
          ),
          error: error,
        );
      }
      
      attempt++;
    }
    
    // Timeout
    throw DioException(
      requestOptions: analyzeResponse.requestOptions,
      error: 'Analysis timeout - please try again',
    );
  }

  Future<Response> getMyPdfDocuments() async {
    // Use the new pdf-analysis endpoint for listing documents
    return await _dioPdfAnalyzer.get('documents');
  }

  Future<Response> getAnalysisStatus(String requestId) async {
    return await _dioPdfAnalyzer.get('status/$requestId');
  }

  // Generic GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // Generic POST request
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // Generic PUT request
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  // Generic DELETE request
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
