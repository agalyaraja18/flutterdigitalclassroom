// LivePlayScreen removed — live session features have been removed from the app.
// Placeholder kept to avoid import issues during cleanup.

import 'package:flutter/material.dart';

class LivePlayScreen extends StatelessWidget {
  final String roomCode;
  const LivePlayScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Removed')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Live sessions have been removed. Use the Join screen to enter a room code and take the quiz at your own pace.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// No question card — live UI removed. This file only contains a small placeholder class.


