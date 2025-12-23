
import 'package:flutter/material.dart';

class JoinQuizDialog extends StatefulWidget {
  final Function(String) onJoin;

  const JoinQuizDialog({super.key, required this.onJoin});

  @override
  State<JoinQuizDialog> createState() => _JoinQuizDialogState();
}

class _JoinQuizDialogState extends State<JoinQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onJoin(_roomCodeController.text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Quiz'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roomCodeController,
              decoration: const InputDecoration(
                labelText: 'Room Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a room code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Join'),
        ),
      ],
    );
  }
}
