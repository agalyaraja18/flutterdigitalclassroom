
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuizCreationForm extends StatefulWidget {
  final String token;
  final Function onQuizCreated;

  const QuizCreationForm({
    super.key,
    required this.token,
    required this.onQuizCreated,
  });

  @override
  State<QuizCreationForm> createState() => _QuizCreationFormState();
}

class _QuizCreationFormState extends State<QuizCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _numQuestionsController = TextEditingController();
  String _difficulty = 'easy';
  bool _isLoading = false;

  Future<void> _createQuiz() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/quiz/create/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token ${widget.token}',
          },
          body: jsonEncode({
            'title': _topicController.text,
            'topic': _topicController.text,
            'difficulty': _difficulty,
            'number_of_questions': int.parse(_numQuestionsController.text),
          }),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          // Backend may return either 'room_code' or 'quiz_code'. Accept either.
          final roomCode = data['room_code'] ?? data['quiz_code']?.toString();
          if (roomCode == null || roomCode.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz created but server did not return a room code')),
            );
          } else {
            widget.onQuizCreated(roomCode);
          }
        } else {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create quiz: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating quiz: $e')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Quiz with AI',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a topic';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _numQuestionsController,
            decoration: const InputDecoration(
              labelText: 'Number of Questions',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the number of questions';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'easy', child: Text('Easy')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'hard', child: Text('Hard')),
              DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
            ],
            onChanged: (value) {
              setState(() {
                _difficulty = value!;
              });
            },
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _createQuiz,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Create Quiz'),
                ),
        ],
      ),
    );
  }
}
