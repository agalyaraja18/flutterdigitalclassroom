
// Host/control UI removed — live-session management is no longer part of the frontend.

import 'package:flutter/material.dart';

class QuizManagementScreen extends StatelessWidget {
  final String roomCode;
  final String token;

  const QuizManagementScreen({super.key, required this.roomCode, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Quiz: $roomCode')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Quiz management and host controls were removed. Quizzes are self-paced; students can join using the room code and take the quiz any time.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
