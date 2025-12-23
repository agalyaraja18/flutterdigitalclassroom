import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/quiz_provider.dart';
import '../../domain/models/quiz_models.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).loadQuizHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<QuizProvider>(context, listen: false).loadQuizHistory();
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.quizHistory.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadQuizHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.quizHistory.length,
              itemBuilder: (context, index) {
                final session = provider.quizHistory[index];
                return _buildQuizHistoryCard(session);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No quiz history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed quizzes will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistoryCard(QuizSession session) {
    final quiz = session.quiz;
    final score = session.score ?? 0.0;

    Color getScoreColor() {
      if (!session.isCompleted) return Colors.grey;
      if (score >= 90) return Colors.green;
      if (score >= 70) return Colors.blue;
      if (score >= 50) return Colors.orange;
      return Colors.red;
    }

    String getScoreLabel() {
      if (!session.isCompleted) return 'Not Completed';
      if (score >= 90) return 'Excellent';
      if (score >= 70) return 'Good';
      if (score >= 50) return 'Fair';
      return 'Poor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getScoreColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: getScoreColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: session.isCompleted
                        ? Text(
                            '${score.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.onSurfaceColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz.topic,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getScoreColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        getScoreLabel(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.isCompleted ? '${score.toStringAsFixed(1)}%' : 'Incomplete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: getScoreColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quiz details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quiz stats
                Row(
                  children: [
                    _buildStatChip(
                      Icons.bar_chart,
                      quiz.difficulty.toUpperCase(),
                      _getDifficultyColor(quiz.difficulty),
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.question_answer,
                      '${quiz.numberOfQuestions} Questions',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.timer,
                      '${quiz.timeLimit} min',
                      Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Performance summary for completed quizzes
                if (session.isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPerformanceStat(
                          'Score',
                          '${score.toStringAsFixed(1)}%',
                          getScoreColor(),
                        ),
                        _buildPerformanceStat(
                          'Answered',
                          '${session.userAnswers.length}/${quiz.numberOfQuestions}',
                          Colors.blue,
                        ),
                        _buildPerformanceStat(
                          'Correct',
                          '${session.userAnswers.values.where((a) => a.isCorrect).length}',
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Date information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Started ${_formatDate(session.startedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (session.completedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed ${_formatDate(session.completedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewQuizDetails(session),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      side: const BorderSide(color: AppConstants.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'mixed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _viewQuizDetails(QuizSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.quiz.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic: ${session.quiz.topic}'),
            Text('Difficulty: ${session.quiz.difficulty.toUpperCase()}'),
            Text('Questions: ${session.quiz.numberOfQuestions}'),
            Text('Time Limit: ${session.quiz.timeLimit} minutes'),
            if (session.isCompleted) ...[
              const SizedBox(height: 8),
              Text('Score: ${session.score?.toStringAsFixed(1)}%'),
              Text('Answered: ${session.userAnswers.length}/${session.quiz.numberOfQuestions}'),
              Text('Correct: ${session.userAnswers.values.where((a) => a.isCorrect).length}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (session.isCompleted)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _viewDetailedResults(session);
              },
              child: const Text('View Results'),
            ),
        ],
      ),
    );
  }

  void _viewDetailedResults(QuizSession session) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed results feature coming soon!'),
      ),
    );
  }
}