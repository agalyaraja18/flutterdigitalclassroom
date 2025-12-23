import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lms_dashboard_screen.dart';

class LMSLoginScreen extends StatefulWidget {
  const LMSLoginScreen({super.key});

  @override
  State<LMSLoginScreen> createState() => _LMSLoginScreenState();
}

class _LMSLoginScreenState extends State<LMSLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, Map<String, String>> _demoCredentials = {
    'admin': {'username': 'admin', 'password': 'admin123'},
    'teacher': {'username': 'teacher', 'password': 'teacher123'},
    'student': {'username': 'student', 'password': 'student123'},
  };

  @override
  void initState() {
    super.initState();
    _updateCredentials();
  }

  void _updateCredentials() {
    final credentials = _demoCredentials[_selectedRole]!;
    _usernameController.text = credentials['username']!;
    _passwordController.text = credentials['password']!;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requestBody = jsonEncode({
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
      });

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/login/'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LMSDashboardScreen(
                token: data['token'],
                userRole: _selectedRole,
                username: _usernameController.text.trim(),
              ),
            ),
          );
        }
      } else {
        // Try to show backend error details for easier debugging
        String serverMessage = 'Login failed. Please check your credentials.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            // DRF commonly returns {'non_field_errors': [...]} or field errors
            if (decoded['non_field_errors'] != null) {
              serverMessage = (decoded['non_field_errors'] is List)
                  ? decoded['non_field_errors'].join(' ')
                  : decoded['non_field_errors'].toString();
            } else if (decoded['detail'] != null) {
              serverMessage = decoded['detail'].toString();
            } else if (decoded['username'] != null || decoded['password'] != null) {
              final parts = [];
              if (decoded['username'] != null) parts.add(decoded['username'].toString());
              if (decoded['password'] != null) parts.add(decoded['password'].toString());
              serverMessage = parts.join(' ');
            } else {
              serverMessage = decoded.toString();
            }
          } else {
            serverMessage = response.body;
          }
        } catch (_) {
          serverMessage = response.body;
        }

        // Debug log
        // ignore: avoid_print
        print('Login failed (${response.statusCode}): ${response.body}');

        if (mounted) {
          setState(() {
            _errorMessage = serverMessage;
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Login network error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Title
                      Icon(
                        Icons.school,
                        size: 64,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI-Integrated LMS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learning Management System',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Role Selection
                      Text(
                        'Select Your Role',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              'admin',
                              'Admin',
                              Icons.admin_panel_settings,
                              Colors.red,
                              'System Management',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleCard(
                              'teacher',
                              'Teacher',
                              Icons.person_outline,
                              Colors.green,
                              'Create & Manage',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleCard(
                              'student',
                              'Student',
                              Icons.school_outlined,
                              Colors.blue,
                              'Learn & Explore',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Login Form
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Login to LMS',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Demo Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Demo Credentials',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Credentials auto-fill when you select a role',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String title, IconData icon, Color color, String subtitle) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
        _updateCredentials();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[500],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? color : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}