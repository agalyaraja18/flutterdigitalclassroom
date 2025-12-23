// LiveHostScreen removed — host controls and live sessions were removed from the frontend.

import 'package:flutter/material.dart';

class LiveHostScreen extends StatelessWidget {
  final String roomCode;
  const LiveHostScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host (removed)')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Host controls have been removed. Quizzes are now self-paced; students can join any quiz using the room code and answer at their own pace.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


