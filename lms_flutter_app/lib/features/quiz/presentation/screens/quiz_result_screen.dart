
import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const QuizResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final score = resultData['score'];
    final userAnswers = resultData['user_answers'];
    final quiz = resultData['quiz'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Result: ${quiz['title']}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Score: $score%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Review Your Answers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quiz['questions'].length,
                itemBuilder: (context, index) {
                  final question = quiz['questions'][index];
                  final userAnswer = userAnswers[question['id'].toString()];
                  final isCorrect = userAnswer['is_correct'] as bool;

                  return Card(
                    color: isCorrect ? Colors.green[100] : Colors.red[100],
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question ${index + 1}: ${question['question_text']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...question['choices'].map<Widget>((choice) {
                            final isSelected = choice['id'] == userAnswer['selected_choice'];
                            final isCorrectChoice = choice['is_correct'] as bool;

                            return ListTile(
                              title: Text(choice['choice_text']),
                              leading: Icon(
                                isCorrectChoice
                                    ? Icons.check_circle
                                    : isSelected
                                        ? Icons.cancel
                                        : Icons.radio_button_unchecked,
                                color: isCorrectChoice
                                    ? Colors.green
                                    : isSelected
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
