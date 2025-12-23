import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000/api/';
  // PDF analyzer now uses Django backend on port 8000
  static const String pdfAnalyzerBaseUrl = 'http://localhost:8000/api/pdf-analysis/';
  static const String authEndpoint = 'auth';
  static const String pdfEndpoint = 'pdf';
  static const String quizEndpoint = 'quiz';

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color onSurfaceColor = Color(0xFF1A1A1A);

  // User Types
  static const String adminUser = 'admin';
  static const String teacherUser = 'teacher';
  static const String studentUser = 'student';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Animation Durations
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration slowAnimation = Duration(milliseconds: 600);

  // Quiz Difficulty Levels
  static const Map<String, String> quizDifficulties = {
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'mixed': 'Mixed',
  };

  // File Size Limits
  static const int maxPdfSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedPdfExtensions = ['.pdf'];

  // Quiz Settings
  static const int minQuestions = 1;
  static const int maxQuestions = 50;
  static const int minTimeLimit = 1;
  static const int maxTimeLimit = 300; // 5 hours
}