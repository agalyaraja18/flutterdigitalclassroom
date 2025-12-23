import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/quiz_provider.dart';
import '../../domain/models/quiz_models.dart';
// Host controls screen removed from this flow

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _questionsController = TextEditingController(text: '10');
  final _timeLimitController = TextEditingController(text: '30');

  String _selectedDifficulty = 'medium';

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _questionsController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    final request = QuizCreateRequest(
      title: _titleController.text.trim(),
      topic: _topicController.text.trim(),
      difficulty: _selectedDifficulty,
      numberOfQuestions: int.parse(_questionsController.text),
      timeLimit: int.parse(_timeLimitController.text),
    );

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final success = await quizProvider.createQuiz(request);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizProvider.errorMessage ?? 'Failed to create quiz'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz (AI)'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'AI-Powered Quiz Creation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Describe your quiz requirements and let AI generate engaging questions for you',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quiz Title
              CustomTextField(
                label: 'Quiz Title',
                hint: 'Enter a descriptive title for your quiz',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quiz title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Topic
              CustomTextField(
                label: 'Topic',
                hint: 'e.g., "World History", "Basic Mathematics", "Science Concepts"',
                controller: _topicController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Difficulty Level
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppConstants.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildDifficultyOption('easy', 'Easy', 'Simple questions for beginners'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildDifficultyOption('medium', 'Medium', 'Moderate difficulty questions'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildDifficultyOption('hard', 'Hard', 'Challenging questions for advanced learners'),
                        Divider(height: 1, color: Colors.grey.shade300),
                        _buildDifficultyOption('mixed', 'Mixed', 'Combination of all difficulty levels'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Number of Questions and Time Limit
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Number of Questions',
                      controller: _questionsController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 1 || number > 50) {
                          return '1-50 only';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Time Limit (minutes)',
                      controller: _timeLimitController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final number = int.tryParse(value);
                        if (number == null || number < 1 || number > 300) {
                          return '1-300 only';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tips Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for Better Quizzes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Be specific with your topic (e.g., "Renaissance Art" instead of just "Art")'),
                    _buildTip('Choose difficulty based on your students\' level'),
                    _buildTip('Allow 1-2 minutes per question for the time limit'),
                    _buildTip('Start with 5-15 questions for better engagement'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Create AI Quiz Button
              Consumer<QuizProvider>(
                builder: (context, provider, child) {
                  return CustomButton(
                    text: 'Create Quiz with AI',
                    onPressed: provider.isCreating ? null : _createQuiz,
                    isLoading: provider.isCreating,
                    height: 56,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Live session feature removed — only AI-generated self-paced quizzes are supported.
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text('Live sessions have been removed. Students join using the quiz code and can take the quiz at their own pace.'),
              ),

              // Note about AI generation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quiz generation may take 30-60 seconds. Please be patient while AI creates your questions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String value, String title, String description) {
    final isSelected = _selectedDifficulty == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDifficulty = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedDifficulty,
              onChanged: (newValue) {
                setState(() {
                  _selectedDifficulty = newValue!;
                });
              },
              activeColor: AppConstants.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppConstants.primaryColor : AppConstants.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? AppConstants.primaryColor.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}