import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'features/quiz/presentation/providers/quiz_provider.dart';
import 'features/quiz/presentation/screens/take_quiz_screen.dart';
// live_play_screen removed — no longer imported
// ignore_for_file: unused_field

class MainDashboard extends StatefulWidget {
  final String token;
  final String userRole;
  final String username;
  final int userId;

  const MainDashboard({
    super.key,
    required this.token,
    required this.userRole,
    required this.username,
    required this.userId,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  List<dynamic> _documents = [];
  List<dynamic> _quizSessions = [];
  String _status = 'Welcome to Digital Classroom';
  bool _loading = false;

  // Quiz Creation
  final _quizTopicController = TextEditingController();
  String _selectedDifficulty = 'mixed';
  int _numberOfQuestions = 10;

  // Quiz Session
  String? _currentSessionCode;
  Map<String, dynamic>? _currentQuiz;
  int _currentQuestionIndex = 0;
  final Map<int, String> _userAnswers = {};
  bool _quizCompleted = false;
  int _score = 0;
  // Audio playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingUrl;
  bool _isPlaying = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadDocuments();
    await _loadQuizSessions();
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
          if (_selectedIndex == 0) {
            _status = 'Loaded ${_documents.length} PDF documents';
          }
        });
      }
    } catch (e) {
      setState(() => _status = 'Error loading documents: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _loadQuizSessions() async {
    try {
      // Load created quizzes so teachers see newly-created quizzes and their codes
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/quiz/quizzes/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _quizSessions = data['results'] ?? data ?? []);
      } else {
        setState(() => _quizSessions = []);
      }
    } catch (e) {
      setState(() => _status = 'Error loading quiz sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Classroom - ${_getRoleTitle()}'),
        backgroundColor: _getRoleColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(_getRoleIcon()),
                const SizedBox(width: 8),
                Text(widget.username),
                const SizedBox(width: 16),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'logout') {
                      Navigator.of(context).pushReplacementNamed('/');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getRoleColor().withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _getRoleColor()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(color: _getRoleColor(), fontWeight: FontWeight.w500),
                  ),
                ),
                if (_loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _getRoleColor(),
                    ),
                  ),
              ],
            ),
          ),

          // Feature Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    0,
                    'PDF to Audio',
                    Icons.picture_as_pdf,
                    'Convert documents to speech',
                    widget.userRole == 'student' ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFeatureCard(
                    1,
                    'AI Quizzes',
                    Icons.quiz,
                    widget.userRole == 'student'
                        ? 'Join quiz sessions'
                        : 'Create & manage quizzes',
                    widget.userRole == 'student' ? Colors.blue : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(int index, String title, IconData icon, String subtitle, Color color) {
    final isSelected = _selectedIndex == index;
    final isTeacherQuizCard = (widget.userRole != 'student' && index == 1);
    final shouldHighlight = isSelected || isTeacherQuizCard;
    final highlightColor = isTeacherQuizCard ? Colors.orange : color;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: shouldHighlight ? highlightColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldHighlight ? highlightColor : Colors.grey[300]!,
            width: shouldHighlight ? 2 : 1,
          ),
          boxShadow: shouldHighlight ? [
            BoxShadow(
              color: highlightColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: shouldHighlight ? highlightColor : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: shouldHighlight ? highlightColor : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return widget.userRole == 'student'
            ? _buildPDFToAudio()
            : _buildPDFToAudio();
      case 1:
        return widget.userRole == 'student'
            ? _buildQuizSection()
            : _buildQuizSection();
      default:
        return widget.userRole == 'student'
            ? _buildPDFToAudio()
            : _buildPDFToAudio();
    }
  }

  Widget _buildPDFToAudio() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red[600], size: 28),
              const SizedBox(width: 12),
              const Text(
                'PDF to Audio Converter',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Convert your PDF documents into audio files for better accessibility',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Upload Section (All users can upload PDFs)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Upload New PDF',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPDFUploadSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Documents List
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.library_books, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Audio Library',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.blue[600]),
          const SizedBox(height: 16),
          const Text(
            'Drag & Drop PDF or Click to Browse',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported format: PDF files only (Max 10MB)',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No documents available yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your first PDF to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
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
            title: Text(
              doc['title'] ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${_getStatusText(doc['conversion_status'])}'),
                Text('Uploaded by: ${doc['uploaded_by'] ?? 'Unknown'}'),
                if (doc['created_at'] != null)
                  Text('Date: ${DateTime.parse(doc['created_at']).toString().split(' ')[0]}'),
              ],
            ),
            trailing: doc['audio_file'] != null
                ? Builder(builder: (context) {
                    final audioPath = doc['audio_file'] as String?;
                    final src = (audioPath != null && audioPath.startsWith('http'))
                        ? audioPath
                        : (audioPath != null ? 'http://127.0.0.1:8000${audioPath.startsWith('/') ? audioPath : '/$audioPath'}' : null);

                    final isCurrent = src != null && _currentPlayingUrl == src;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent && _isPlaying) ...[
                          IconButton(
                            onPressed: _pauseAudio,
                            icon: const Icon(Icons.pause_circle_filled, color: Colors.orange),
                            tooltip: 'Pause',
                          ),
                          IconButton(
                            onPressed: _stopAudio,
                            icon: const Icon(Icons.stop, color: Colors.red),
                            tooltip: 'Stop',
                          ),
                        ] else if (isCurrent && _isPaused) ...[
                          IconButton(
                            onPressed: _resumeAudio,
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            tooltip: 'Resume',
                          ),
                          IconButton(
                            onPressed: _stopAudio,
                            icon: const Icon(Icons.stop, color: Colors.red),
                            tooltip: 'Stop',
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: () => _playAudio(doc),
                            icon: const Icon(Icons.play_circle_filled, color: Colors.green),
                            tooltip: 'Play Audio',
                          ),
                          IconButton(
                            onPressed: () => _downloadAudio(
                              src ?? 'http://127.0.0.1:8000${doc['audio_file']}',
                              doc['title'],
                            ),
                            icon: const Icon(Icons.download, color: Colors.blue),
                            tooltip: 'Download Audio',
                          ),
                        ],
                      ],
                    );
                  })
                : doc['conversion_status'] == 'processing'
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
          ),
        );
      },
    );
  }

  Widget _buildQuizSection() {
    if (widget.userRole == 'student') {
      return _buildStudentQuizSection();
    } else {
      return _buildTeacherQuizSection();
    }
  }

  Widget _buildStudentQuizSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.blue[600], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Join Quiz Session',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a room code to join a quiz',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Join Quiz Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.meeting_room, size: 48, color: Colors.blue[600]),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Room Code',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit quiz code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _currentSessionCode = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _currentSessionCode?.length == 6 ? _joinQuizSession : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Join Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 'Available Sessions' removed — students join by entering a room code above.
        ],
      ),
    );
  }

  Widget _buildTeacherQuizSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz, color: Colors.blue[600], size: 28),
              const SizedBox(width: 12),
              const Text(
                'AI Quiz Generator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create AI-powered quizzes and share with students',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Quiz Creation Form
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Create New Quiz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quizTopicController,
                    decoration: InputDecoration(
                      labelText: 'Quiz Topic',
                      hintText: 'e.g., Mathematics, Science, History',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDifficulty,
                          decoration: InputDecoration(
                            labelText: 'Difficulty Level',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'easy', child: Text('Easy')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'hard', child: Text('Hard')),
                            DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Number of Questions',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _numberOfQuestions = int.tryParse(value) ?? 10;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createQuiz,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Quiz with AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active Sessions
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Quiz Sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_quizSessions.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No active quiz sessions',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quizSessions.length,
                      itemBuilder: (context, index) {
                        final session = _quizSessions[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[600],
                              child: Text(
                                session['quiz_code'] ?? session['room_code'] ?? '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(session['topic'] ?? 'Quiz ${index + 1}'),
                            subtitle: Text('Room Code: ${session['quiz_code'] ?? session['room_code'] ?? '-'} • ${session['num_questions'] ?? 0} questions'),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('View Results'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {},
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          setState(() => _status = 'PDF uploaded successfully! Converting to audio...');
          await _loadDocuments();
        } else {
          setState(() => _status = 'Upload failed. Please try again.');
        }
      }
    } catch (e) {
      setState(() => _status = 'Error uploading PDF: $e');
    }
  }

  void _downloadAudio(String audioUrl, String title) {
    try {
      // Create and click anchor element without assigning to an unused local variable
      html.AnchorElement(href: audioUrl)
        ..target = '_blank'
        ..download = '${title.replaceAll(' ', '_')}.wav'
        ..click();

      setState(() => _status = 'Downloading audio: $title');
    } catch (e) {
      setState(() => _status = 'Error downloading audio: $e');
    }
  }

  void _playAudio(Map<String, dynamic> doc) {
    final audioPath = doc['audio_file'] as String?;
    if (audioPath == null) return;
    final src = audioPath.startsWith('http')
        ? audioPath
        : 'http://127.0.0.1:8000${audioPath.startsWith('/') ? audioPath : '/$audioPath'}';

    _playAudioUrl(src, doc['title'] ?? 'Audio');
  }

  Future<void> _playAudioUrl(String src, String title) async {
    try {
      if (_currentPlayingUrl != null && _currentPlayingUrl != src) {
        await _audioPlayer.stop();
      }
      _currentPlayingUrl = src;
      await _audioPlayer.play(UrlSource(src));
      _isPlaying = true;
      _isPaused = false;
      setState(() => _status = 'Playing audio: $title');
    } catch (e) {
      setState(() => _status = 'Failed to play audio: $e');
    }
  }

  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      _isPaused = true;
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Failed to pause audio: $e');
    }
  }

  Future<void> _resumeAudio() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
      _isPaused = false;
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Failed to resume audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      _currentPlayingUrl = null;
      _isPlaying = false;
      _isPaused = false;
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Failed to stop audio: $e');
    }
  }

  Future<void> _createQuiz() async {
    if (_quizTopicController.text.trim().isEmpty) {
      setState(() => _status = 'Please enter a quiz topic');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Creating quiz with AI...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/quiz/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
        body: jsonEncode({
          'title': 'Quiz: ${_quizTopicController.text.trim()}',
          'topic': _quizTopicController.text.trim(),
          'difficulty': _selectedDifficulty,
          'number_of_questions': _numberOfQuestions,
          'time_limit': 30,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final roomCode = data['room_code'] ?? data['quiz_code']?.toString() ?? '-';
        setState(() => _status = 'Quiz created! Room code: $roomCode');
        _quizTopicController.clear();
        await _loadQuizSessions();
      } else {
        setState(() => _status = 'Failed to create quiz. Please try again.');
      }
    } catch (e) {
      setState(() => _status = 'Error creating quiz: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _joinQuizSession() async {
    if (_currentSessionCode == null || _currentSessionCode!.length != 6) {
      setState(() => _status = 'Please enter a valid 6-digit room code');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Joining quiz session...';
    });

    try {
      final provider = Provider.of<QuizProvider>(context, listen: false);
      final result = await provider.joinAndEnter(_currentSessionCode!.trim());

      if (result == null) {
        setState(() => _status = provider.errorMessage ?? 'Failed to join quiz. Check room code.');
        return;
      }

      // Self-paced / take-quiz flow
      setState(() {
        _currentQuiz = provider.currentSession?.quiz.toJson();
        _currentQuestionIndex = 0;
        _userAnswers.clear();
        _quizCompleted = false;
        _score = 0;
        _status = 'Quiz started! Good luck!';
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const TakeQuizScreen(),
          ),
        ),
      );
    } catch (e) {
      setState(() => _status = 'Error joining quiz: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Live session endpoints removed from frontend; host/end actions are no longer available.

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

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Audio Ready';
      case 'processing':
        return 'Converting...';
      case 'failed':
        return 'Conversion Failed';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _quizTopicController.dispose();
    // No manual provider listeners to remove (UI consumes provider directly)
    super.dispose();
  }
}