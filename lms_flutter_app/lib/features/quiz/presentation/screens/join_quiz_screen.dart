import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/quiz_provider.dart';
import 'take_quiz_screen.dart';
// live session screens removed — join always opens TakeQuizScreen (self-paced)

class JoinQuizScreen extends StatefulWidget {
  const JoinQuizScreen({super.key});

  @override
  State<JoinQuizScreen> createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quizCodeController = TextEditingController();

  @override
  void dispose() {
    _quizCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final raw = _quizCodeController.text.trim();
  // Always treat code as self-paced (no live sessions)
  final success = await quizProvider.joinQuiz(raw);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
            value: quizProvider,
            child: const TakeQuizScreen(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quizProvider.errorMessage ?? 'Failed to join quiz'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Quiz'),
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
              const SizedBox(height: 40),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.login,
                        size: 50,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Join a Quiz',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the quiz code provided by your teacher',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Quiz Code Input
              CustomTextField(
                label: 'Quiz Code',
                hint: 'Enter 6-digit room code (numbers only)',
                controller: _quizCodeController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _joinQuiz(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter the quiz code';
                  final v = value.trim();
                    final isSixDigits = RegExp(r'^\d{6}$').hasMatch(v);
                  if (!isSixDigits) return 'Enter a 6-digit numeric room code';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Join Button
              Consumer<QuizProvider>(
                builder: (context, provider, child) {
                  return CustomButton(
                    text: 'Join Quiz',
                    onPressed: provider.isLoading ? null : _joinQuiz,
                    isLoading: provider.isLoading,
                    height: 56,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Instructions & Tips
              Container(
                padding: const EdgeInsets.all(20),
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
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to Join',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep('1.', 'Get the quiz code from your teacher', Icons.person),
                    const SizedBox(height: 8),
                    _buildInstructionStep('2.', 'Enter the 6-digit numeric room code above', Icons.keyboard),
                    const SizedBox(height: 8),
                    _buildInstructionStep('3.', 'Start answering questions immediately', Icons.quiz),
                    const SizedBox(height: 16),
                    _buildTip('Make sure you have a stable internet connection'),
                    _buildTip('Read each question carefully before answering'),
                    _buildTip('Keep an eye on the timer during the quiz'),
                    _buildTip('You cannot change answers once submitted'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sample Quiz Code Format
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: [
                    Text('Quiz Code Format:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                      child: Text('123456', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.grey.shade800)),
                    ),
                    const SizedBox(height: 4),
                    Text('6 digits (numbers only)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.blue.shade700, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.orange.shade700))),
        ],
      ),
    );
  }
}