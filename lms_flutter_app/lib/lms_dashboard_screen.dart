import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'features/quiz/presentation/screens/quiz_management_screen.dart';
import 'features/quiz/presentation/screens/quiz_taking_screen.dart';
import 'features/quiz/presentation/widgets/join_quiz_dialog.dart';
import 'features/quiz/presentation/widgets/quiz_creation_form.dart';

class LMSDashboardScreen extends StatefulWidget {
  final String token;
  final String userRole;
  final String username;

  const LMSDashboardScreen({
    super.key,
    required this.token,
    required this.userRole,
    required this.username,
  });

  @override
  State<LMSDashboardScreen> createState() => _LMSDashboardScreenState();
}

class _LMSDashboardScreenState extends State<LMSDashboardScreen> {
  int _selectedIndex = 0;
  List<dynamic> _documents = [];
  List<dynamic> _quizzes = [];
  bool _loading = false;
  String _status = 'Welcome to LMS';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadDocuments();
    if (widget.userRole == 'teacher' || widget.userRole == 'admin') {
      await _loadQuizzes();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/pdf/documents/?page=1'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _documents = data['results'] ?? [];
          _status = 'Loaded ${_documents.length} documents';
        });
      }
    } catch (e) {
      setState(() => _status = 'Error loading documents: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _loadQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/quiz/quizzes/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quizzes = data['results'] ?? data ?? [];
        });
      }
    } catch (e) {
      setState(() => _status = 'Error loading quizzes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LMS - ${_getRoleTitle()}'),
        backgroundColor: _getRoleColor(),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(_getRoleIcon()),
                const SizedBox(width: 8),
                Text(widget.username),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: Colors.grey[100],
            child: Column(
              children: [
                _buildNavHeader(),
                Expanded(
                  child: ListView(
                    children: _getNavigationItems(),
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getRoleColor().withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _getRoleColor(),
            child: Icon(_getRoleIcon(), size: 30, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            widget.username,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            _getRoleTitle(),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  List<Widget> _getNavigationItems() {
    List<Map<String, dynamic>> items = [
      {'icon': Icons.dashboard, 'title': 'Dashboard', 'index': 0},
    ];

    if (widget.userRole == 'admin' || widget.userRole == 'teacher') {
      items.addAll([
        {'icon': Icons.picture_as_pdf, 'title': 'PDF to Audio', 'index': 1},
        {'icon': Icons.quiz, 'title': 'AI Quiz Generator', 'index': 2},
      ]);
    } else {
      items.addAll([
        {'icon': Icons.picture_as_pdf, 'title': 'Audio Library', 'index': 1},
        {'icon': Icons.quiz, 'title': 'Take Quizzes', 'index': 2},
      ]);
    }

    return items.map((item) => _buildNavItem(
      item['icon'],
      item['title'],
      item['index'],
    )).toList();
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _getRoleColor() : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? _getRoleColor() : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: _getRoleColor().withOpacity(0.1),
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return widget.userRole == 'student'
            ? _buildAudioLibrary()
            : _buildPDFToAudio();
      case 2:
        return widget.userRole == 'student'
            ? _buildTakeQuizzes()
            : _buildQuizGenerator();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${widget.username}!',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Role: ${_getRoleTitle()}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'PDF Documents',
                  _documents.length.toString(),
                  Icons.picture_as_pdf,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Audio Files',
                  _documents.where((doc) => doc['audio_file'] != null).length.toString(),
                  Icons.audiotrack,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Quizzes',
                  _quizzes.length.toString(),
                  Icons.quiz,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          const Text(
            'Recent Documents',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDocumentsList(limit: 5),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFToAudio() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PDF to Audio Converter',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Upload Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildPDFUploadSection(),
            ),
          ),
          const SizedBox(height: 24),

          // Documents List
          const Text(
            'PDF Documents & Audio Files',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildDocumentsList(),
        ],
      ),
    );
  }

  Widget _buildPDFUploadSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_upload, size: 48, color: Colors.blue[600]),
              const SizedBox(height: 16),
              const Text(
                'Click to select PDF file',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Supported format: PDF files only',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectAndUploadPDF,
                icon: const Icon(Icons.file_upload),
                label: const Text('Select PDF File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioLibrary() {
    final audioDocuments = _documents.where((doc) => doc['audio_file'] != null).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Library',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Listen to converted audio files',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          if (audioDocuments.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.audiotrack_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No audio files available yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: audioDocuments.length,
              itemBuilder: (context, index) {
                final doc = audioDocuments[index];
                return _buildAudioCard(doc);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(Map<String, dynamic> doc) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.audiotrack, size: 32, color: Colors.green[600]),
            const SizedBox(height: 12),
            Text(
              doc['title'] ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadAudio(
                  'http://127.0.0.1:8000${doc['audio_file']}',
                  doc['title'],
                ),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizGenerator() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Quiz Generator',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Quiz Creation Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildQuizCreationForm(),
            ),
          ),
          const SizedBox(height: 24),

          // Existing Quizzes
          const Text(
            'Created Quizzes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildQuizzesList(),
        ],
      ),
    );
  }

  void _showRoomCodeDialog(String roomCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your room code is:'),
            const SizedBox(height: 16),
            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuizManagementScreen(
                    roomCode: roomCode,
                    token: widget.token,
                  ),
                ),
              );
            },
            child: const Text('Manage Quiz'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCreationForm() {
    return QuizCreationForm(
      token: widget.token,
      onQuizCreated: (roomCode) {
        _showRoomCodeDialog(roomCode);
        _loadQuizzes();
      },
    );
  }

  Widget _buildTakeQuizzes() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Quizzes',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => JoinQuizDialog(
                  onJoin: (roomCode) async {
                    setState(() {
                      _status = 'Joining quiz with code: $roomCode';
                    });

                    try {
                      final response = await http.post(
                        Uri.parse('http://127.0.0.1:8000/api/quiz/join/'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Token ${widget.token}',
                        },
                        body: jsonEncode({
                          'quiz_code': roomCode,
                        }),
                      );

                      if (response.statusCode == 201 || response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        final sessionId = data['id'];

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuizTakingScreen(
                              roomCode: roomCode,
                              token: widget.token,
                              sessionId: sessionId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to join quiz: ${response.body}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error joining quiz: $e')),
                      );
                    }
                  },
                ),
              );
            },
            child: const Text('Join Quiz'),
          ),
          const SizedBox(height: 24),
          _buildQuizzesList(),
        ],
      ),
    );
  }

  Widget _buildQuizzesList() {
    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No quizzes available yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.quiz, color: Colors.white),
            ),
            title: Text(quiz['title'] ?? 'Quiz ${index + 1}'),
            subtitle: Text(
              'Room Code: ${quiz['quiz_code'] ?? quiz['room_code'] ?? '-'} • Questions: ${quiz['questions']?.length ?? 0}',
            ),
            trailing: ElevatedButton(
              onPressed: () {
                setState(() => _status = 'Quiz taking feature coming soon!');
              },
              child: const Text('Take Quiz'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList({int? limit}) {
    final documentsToShow = limit != null
        ? _documents.take(limit).toList()
        : _documents;

    if (documentsToShow.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No documents uploaded yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentsToShow.length,
      itemBuilder: (context, index) {
        final doc = documentsToShow[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(doc['conversion_status']),
              child: Icon(
                _getStatusIcon(doc['conversion_status']),
                color: Colors.white,
              ),
            ),
            title: Text(doc['title'] ?? 'No title'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${doc['conversion_status'] ?? 'Unknown'}'),
                Text('Uploaded by: ${doc['uploaded_by'] ?? 'Unknown'}'),
              ],
            ),
            trailing: doc['audio_file'] != null
                ? ElevatedButton.icon(
                    onPressed: () => _downloadAudio(
                      'http://127.0.0.1:8000${doc['audio_file']}',
                      doc['title'],
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _selectAndUploadPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() => _status = 'Uploading PDF...');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/api/pdf/upload/'),
        );

        request.headers['Authorization'] = 'Token ${widget.token}';
        request.fields['title'] = result.files.first.name.replaceAll('.pdf', '');

        if (result.files.first.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'pdf_file',
              result.files.first.bytes!,
              filename: result.files.first.name,
            ),
          );
        }

        final response = await request.send();

        if (response.statusCode == 201) {
          setState(() => _status = 'PDF uploaded successfully! Processing...');
          await _loadDocuments();
        } else {
          setState(() => _status = 'Upload failed');
        }
      }
    } catch (e) {
      setState(() => _status = 'Error uploading PDF: $e');
    }
  }

  void _downloadAudio(String audioUrl, String title) {
    try {
      final anchor = html.AnchorElement(href: audioUrl)
        ..target = '_blank'
        ..download = '${title.replaceAll(' ', '_')}.wav'
        ..click();

      setState(() => _status = 'Downloading audio: $title');
    } catch (e) {
      setState(() => _status = 'Error downloading audio: $e');
    }
  }

  String _getRoleTitle() {
    switch (widget.userRole) {
      case 'admin':
        return 'Administrator';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      default:
        return 'User';
    }
  }

  Color _getRoleColor() {
    switch (widget.userRole) {
      case 'admin':
        return Colors.red[600]!;
      case 'teacher':
        return Colors.green[600]!;
      case 'student':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getRoleIcon() {
    switch (widget.userRole) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.person;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green[600]!;
      case 'processing':
        return Colors.orange[600]!;
      case 'failed':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}