
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lms_flutter_app/features/quiz/presentation/screens/quiz_result_screen.dart';

class QuizTakingScreen extends StatefulWidget {
  final String roomCode;
  final String token;
  final String sessionId;

  const QuizTakingScreen({
    super.key,
    required this.roomCode,
    required this.token,
    required this.sessionId,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _quizData;
  String? _statusMessage;
  final Map<int, int> _selectedAnswers = {};
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/quiz/session/${widget.sessionId}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _quizData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        // Handle error: show a message instead of leaving the spinner indefinitely
        setState(() {
          _isLoading = false;
          _quizData = null; // ensure null
          _statusMessage = 'Failed to load quiz session: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _quizData = null;
        _statusMessage = 'Error loading quiz: $e';
      });
    }
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isLoading = true;
    });

    final answers = _selectedAnswers.entries.map((entry) {
      return {
        'question': entry.key,
        'selected_choice': entry.value,
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/quiz/session/${widget.sessionId}/submit/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.token}',
        },
        body: jsonEncode({'answers': answers}),
      );

      if (response.statusCode == 200) {
        final sessionResponse = await http.get(
          Uri.parse('http://127.0.0.1:8000/api/quiz/session/${widget.sessionId}/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token ${widget.token}',
          },
        );
        final sessionData = jsonDecode(sessionResponse.body);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(resultData: sessionData),
          ),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit quiz: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting quiz: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quizData != null ? _quizData!['quiz']['title'] : 'Quiz'),
      ),
    body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _quizData == null
        ? Center(child: Text(_statusMessage ?? 'Failed to load quiz'))
        : PageView.builder(
                  controller: _pageController,
                  itemCount: _quizData!['quiz']['questions'].length,
                  itemBuilder: (context, index) {
                    final question = _quizData!['quiz']['questions'][index];
                    return _buildQuestionCard(question, index);
                  },
                ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int questionIndex) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${questionIndex + 1} of ${_quizData!['quiz']['questions'].length}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              question['question_text'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...question['choices'].map<Widget>((choice) {
              final choiceIndex = choice['id'];
              return RadioListTile<int>(
                title: Text(choice['choice_text']),
                value: choiceIndex,
                groupValue: _selectedAnswers[question['id']],
                onChanged: (value) {
                  setState(() {
                    _selectedAnswers[question['id']] = value!;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              if (_pageController.page! >= _quizData!['quiz']['questions'].length - 1) {
                _submitQuiz();
              }
            },
            child: Text(
              _pageController.hasClients && _pageController.page == _quizData!['quiz']['questions'].length - 1
                  ? 'Submit'
                  : 'End of Quiz',
            ),
          ),
        ],
      ),
    );
  }
}
