import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/quiz_models.dart';

enum QuizState {
  loading,
  loaded,
  creating,
  error,
}

class QuizProvider extends ChangeNotifier {
  // Start in 'loaded' state so UI doesn't show a perpetual loading spinner
  // until an explicit operation (load/create/join) sets the state to loading.
  QuizState _state = QuizState.loaded;
  List<Quiz> _myQuizzes = [];
  List<QuizSession> _quizHistory = [];
  QuizSession? _currentSession;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  QuizState get state => _state;
  List<Quiz> get myQuizzes => _myQuizzes;
  List<QuizSession> get quizHistory => _quizHistory;
  // live session features removed — provider now focuses on self-paced quizzes
  QuizSession? get currentSession => _currentSession;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == QuizState.loading;
  bool get isCreating => _state == QuizState.creating;

  QuizProvider() {
    _apiService.init();
  }

  // --- Deduplication helpers ---
  // Ensures we don't display the same items repeatedly if backend sends duplicates
  List<Quiz> _dedupeQuizzes(List<Quiz> items) {
    final seen = <String>{};
    final result = <Quiz>[];
    for (final q in items) {
      final key = (q.id.isNotEmpty ? q.id : q.quizCode).toString();
      if (seen.add(key)) {
        result.add(q);
      }
    }
    return result;
  }

  List<QuizSession> _dedupeSessions(List<QuizSession> items) {
    final seen = <String>{};
    final result = <QuizSession>[];
    for (final s in items) {
      final key = s.id.toString();
      if (seen.add(key)) {
        result.add(s);
      }
    }
    return result;
  }

  // Live/session-based APIs removed from provider — self-paced quizzes only.

  // Teacher/Admin methods
  Future<void> loadMyQuizzes() async {
    try {
      _state = QuizState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.getMyQuizzes();

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // Paginated response
          final results = data['results'] as List<dynamic>;
          _myQuizzes = _dedupeQuizzes(
            results
                .map((quiz) => Quiz.fromJson(quiz as Map<String, dynamic>))
                .toList(),
          );
        } else if (data is List<dynamic>) {
          // Non-paginated response
          _myQuizzes = _dedupeQuizzes(
            data
                .map((quiz) => Quiz.fromJson(quiz as Map<String, dynamic>))
                .toList(),
          );
        }

        _state = QuizState.loaded;
      } else {
        _setError('Failed to load quizzes');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Load quizzes error: $e');
      }
    }
  }

  Future<bool> createQuiz(QuizCreateRequest request) async {
    try {
      _state = QuizState.creating;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.createQuiz(request.toJson());

      if (response.statusCode == 201) {
        final quizData = response.data as Map<String, dynamic>;
        final newQuiz = Quiz.fromJson(quizData);

        // Debug: Print the quiz code
        if (kDebugMode) {
          print('Created quiz with code: ${newQuiz.quizCode}');
          print('Full quiz data: $quizData');
        }

        _myQuizzes.insert(0, newQuiz);
        _state = QuizState.loaded;
        notifyListeners();
        
        // Reload the quiz list to ensure we have the latest data from server
        // This ensures quiz_code is properly populated
        await loadMyQuizzes();
        
        return true;
      } else {
        _setError('Failed to create quiz');
        return false;
      }
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Create quiz error: $e');
      }
      return false;
    }
  }

  // Student methods
  Future<void> loadQuizHistory() async {
    try {
      _state = QuizState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.getQuizHistory();

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // Paginated response
          final results = data['results'] as List<dynamic>;
          _quizHistory = _dedupeSessions(
            results
                .map((session) => QuizSession.fromJson(session as Map<String, dynamic>))
                .toList(),
          );
        } else if (data is List<dynamic>) {
          // Non-paginated response
          _quizHistory = _dedupeSessions(
            data
                .map((session) => QuizSession.fromJson(session as Map<String, dynamic>))
                .toList(),
          );
        }

        _state = QuizState.loaded;
      } else {
        _setError('Failed to load quiz history');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Load quiz history error: $e');
      }
    }
  }

  Future<bool> joinQuiz(String quizCode) async {
    try {
      _state = QuizState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.joinQuiz(quizCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resp = response.data as Map<String, dynamic>;
        // If backend returned guest token, persist it so subsequent requests are authenticated
        final token = resp['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await StorageService.saveToken(token);
        }
        // Session payload may be nested under 'session'
        final sessionData = (resp['session'] is Map<String, dynamic>)
            ? resp['session'] as Map<String, dynamic>
            : resp;
        _currentSession = QuizSession.fromJson(sessionData);
        // Immediately load full session details to ensure questions are populated
        try {
          await loadQuizSession(_currentSession!.id);
        } catch (_) {}
        _state = QuizState.loaded;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to join quiz');
        return false;
      }
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Join quiz error: $e');
      }
      return false;
    }
  }

  /// Join a quiz and also attempt to register as a live participant.
  /// Returns 'live' if a live session is available and joined, 'take' for self-paced quiz,
  /// or null on failure.
  Future<String?> joinAndEnter(String roomCode) async {
    try {
      final joined = await joinQuiz(roomCode);
      if (!joined) return null;

      // For self-paced quizzes we don't use live sessions. Always open the take-quiz flow.
      return 'take';
    } catch (e) {
      if (kDebugMode) print('joinAndEnter error: $e');
      return null;
    }
  }

  Future<void> loadQuizSession(String sessionId) async {
    try {
      _state = QuizState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.getQuizSession(sessionId);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('session') && data.containsKey('quiz')) {
          // Response contains session and quiz data
          final sessionData = data['session'] as Map<String, dynamic>;
          final quizData = data['quiz'] as Map<String, dynamic>;

          // Create quiz with questions
          final quiz = Quiz.fromJson(quizData);

          // Create session
          _currentSession = QuizSession(
            id: sessionData['id'] as String,
            quiz: quiz,
            student: sessionData['student'] as String,
            status: sessionData['status'] as String,
            score: (sessionData['score'] as num?)?.toDouble(),
            totalPoints: sessionData['total_points'] as int?,
            startedAt: DateTime.parse(sessionData['started_at'] as String),
            completedAt: sessionData['completed_at'] != null
                ? DateTime.parse(sessionData['completed_at'] as String)
                : null,
            userAnswers: (data['user_answers'] as Map<String, dynamic>?)
                    ?.map((key, value) => MapEntry(
                          key,
                          UserAnswer.fromJson(value as Map<String, dynamic>),
                        )) ??
                {},
          );
        } else {
          // Single session response
          _currentSession = QuizSession.fromJson(data);
        }

        _state = QuizState.loaded;
      } else {
        _setError('Failed to load quiz session');
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Load quiz session error: $e');
      }
    }
  }

  Future<bool> submitQuiz(String sessionId, Map<String, String?> answers) async {
    try {
      _state = QuizState.loading;
      _errorMessage = null;
      notifyListeners();

      // Convert answers to the expected backend format with integer IDs
      final answersData = answers.entries.map((entry) {
        final qId = int.tryParse(entry.key);
        final cId = entry.value != null ? int.tryParse(entry.value!) : null;
        return {
          'question': qId,
          'selected_choice': cId,
          'text_answer': '',
        };
      }).toList();

      final response = await _apiService.submitQuiz(sessionId, answersData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Immediately hydrate current session with user_answers for UI
        if (_currentSession != null) {
          final ua = (data['user_answers'] as Map<String, dynamic>?)
                  ?.map((key, value) => MapEntry(
                        key,
                        UserAnswer.fromJson(value as Map<String, dynamic>),
                      )) ??
              {};
          _currentSession = _currentSession!.quiz.let((quiz) => QuizSession(
                id: _currentSession!.id,
                quiz: quiz,
                student: _currentSession!.student,
                status: 'completed',
                score: (data['score'] as num?)?.toDouble(),
                totalPoints: _currentSession!.totalPoints,
                startedAt: _currentSession!.startedAt,
                completedAt: DateTime.now(),
                userAnswers: ua,
              ));
        }

        // Refresh the session from backend to get full details
        try {
          await loadQuizSession(sessionId);
        } catch (_) {}

        _state = QuizState.loaded;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to submit quiz');
        return false;
      }
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Submit quiz error: $e');
      }
      return false;
    }
  }

  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }

  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      _setError('Session expired. Please login again.');
    } else if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;
      if (errorData is Map<String, dynamic>) {
        // Extract first error message
        for (final key in errorData.keys) {
          final errors = errorData[key];
          if (errors is List && errors.isNotEmpty) {
            _setError(errors.first.toString());
            break;
          } else if (errors is String) {
            _setError(errors);
            break;
          }
        }
      } else {
        _setError('Invalid request');
      }
    } else {
      _setError('Network error. Please check your connection.');
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = QuizState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == QuizState.error) {
      _state = QuizState.loaded;
      notifyListeners();
    }
  }
}

extension _QuizExtension on Quiz {
  T let<T>(T Function(Quiz) operation) => operation(this);
}