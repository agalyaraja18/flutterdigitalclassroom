import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/quiz_provider.dart';
import '../../domain/models/quiz_models.dart';
import 'quiz_results_screen.dart';

class TakeQuizScreen extends StatefulWidget {
  const TakeQuizScreen({super.key});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final PageController _pageController = PageController();
  final Map<String, String?> _answers = {};
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _remainingTimeInSeconds = 0;

  @override
  void initState() {
    super.initState();
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final session = quizProvider.currentSession;
    if (session != null) {
      _remainingTimeInSeconds = session.quiz.timeLimit * 60; // Convert minutes to seconds
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTimeInSeconds > 0) {
          _remainingTimeInSeconds--;
        } else {
          _submitQuiz();
        }
      });
    });
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final session = quizProvider.currentSession;
    if (session == null) return;

    final success = await quizProvider.submitQuiz(session.id, _answers);

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: quizProvider,
              child: const QuizResultsScreen(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizProvider.errorMessage ?? 'Failed to submit quiz'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final session = provider.currentSession;
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('No active quiz session')),
          );
        }

        final quiz = session.quiz;
        final questions = quiz.questions;

        if (questions.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No questions available')),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) {
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Quiz'),
                  content: const Text('Are you sure you want to exit? Your progress will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
              if (shouldExit == true) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(quiz.title),
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingTimeInSeconds <= 300 ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: _remainingTimeInSeconds <= 300 ? Colors.white : AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_remainingTimeInSeconds),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _remainingTimeInSeconds <= 300 ? Colors.white : AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Progress Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_answers.length}/${questions.length} answered',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / questions.length,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                      ),
                    ],
                  ),
                ),

                // Questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return _buildQuestionCard(question);
                    },
                  ),
                ),

                // Navigation
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_currentQuestionIndex > 0)
                        Expanded(
                          child: CustomButton(
                            text: 'Previous',
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            type: ButtonType.outline,
                            height: 48,
                          ),
                        ),
                      if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: _currentQuestionIndex == questions.length - 1
                              ? 'Submit Quiz'
                              : 'Next',
                          onPressed: () {
                            if (_currentQuestionIndex == questions.length - 1) {
                              _showSubmitDialog();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          height: 48,
                          backgroundColor: _currentQuestionIndex == questions.length - 1
                              ? Colors.green
                              : AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(Question question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.onSurfaceColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Options
          Column(
            children: question.choices.map((choice) {
              final isSelected = _answers[question.id] == choice.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _onSelect(question, choice.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.primaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppConstants.primaryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            choice.choiceText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : AppConstants.onSurfaceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onSelect(Question question, String choiceId) {
    setState(() {
      _answers[question.id] = choiceId;
    });

    // If not the last question, auto-advance a short moment after selecting
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final total = quizProvider.currentSession?.quiz.questions.length ?? 0;
    final currentIndex = quizProvider.currentSession?.quiz.questions.indexWhere((q) => q.id == question.id) ?? _currentQuestionIndex;

    if (currentIndex < total - 1) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      });
    }
  }

  void _showSubmitDialog() {
    final unansweredCount = Provider.of<QuizProvider>(context, listen: false)
        .currentSession!.quiz.questions.length - _answers.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to submit your quiz?'),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have $unansweredCount unanswered questions.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review'),
          ),
          CustomButton(
            text: 'Submit',
            onPressed: () {
              Navigator.of(context).pop();
              _submitQuiz();
            },
            backgroundColor: Colors.green,
            height: 40,
          ),
        ],
      ),
    );
  }
}