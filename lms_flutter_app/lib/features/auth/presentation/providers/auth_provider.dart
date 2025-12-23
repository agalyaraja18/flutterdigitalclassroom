import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/user_model.dart';

enum AuthState {
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.loading;
  User? _user;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _apiService.init();
    // Add a small delay to ensure initialization
    Future.delayed(Duration.zero, () {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      if (kDebugMode) {
        print('AuthProvider: Checking auth status...');
      }
      final hasToken = await StorageService.hasToken();
      if (kDebugMode) {
        print('AuthProvider: Has token: $hasToken');
      }
      if (hasToken) {
        final userData = await StorageService.getUser();
        if (userData != null) {
          _user = User.fromJson(userData);
          _state = AuthState.authenticated;
          if (kDebugMode) {
            print('AuthProvider: User authenticated: ${_user?.username}');
          }
        } else {
          // Token exists but no user data, try to fetch profile
          if (kDebugMode) {
            print('AuthProvider: Token exists but no user data, fetching profile...');
          }
          await _fetchProfile();
        }
      } else {
        _state = AuthState.unauthenticated;
        if (kDebugMode) {
          print('AuthProvider: No token, setting unauthenticated state');
        }
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      if (kDebugMode) {
        print('Auth check error: $e');
      }
    }
    if (kDebugMode) {
      print('AuthProvider: Final state: $_state');
    }
    notifyListeners();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        await StorageService.saveUser(_user!.toJson());
        _state = AuthState.authenticated;
      } else {
        await _logout();
      }
    } catch (e) {
      await _logout();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.login(username, password);

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await StorageService.saveToken(token);
        _user = User.fromJson(userData);
        await StorageService.saveUser(_user!.toJson());

        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _setError('Login failed. Please check your credentials.');
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          _setError(errorData['non_field_errors']?.first ?? 'Invalid credentials');
        } else {
          _setError('Invalid credentials');
        }
      } else {
        _setError('Network error. Please check your connection.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _apiService.register(userData);

      if (response.statusCode == 201) {
        final data = response.data;
        final token = data['token'] as String;
        final userInfo = data['user'] as Map<String, dynamic>;

        await StorageService.saveToken(token);
        _user = User.fromJson(userInfo);
        await StorageService.saveUser(_user!.toJson());

        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed. Please try again.');
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
          _setError('Registration failed. Please check your data.');
        }
      } else {
        _setError('Network error. Please check your connection.');
      }
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Try to call logout endpoint
      await _apiService.logout();
    } catch (e) {
      // Ignore logout API errors and proceed with local logout
      if (kDebugMode) {
        print('Logout API error: $e');
      }
    }

    await _logout();
  }

  Future<void> _logout() async {
    await StorageService.clearAppData();
    _user = null;
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = AuthState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_state == AuthState.authenticated) {
      await _fetchProfile();
      notifyListeners();
    }
  }
}