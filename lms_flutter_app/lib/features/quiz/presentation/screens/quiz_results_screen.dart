import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/quiz_provider.dart';
import '../../domain/models/quiz_models.dart';
// Note: We intentionally avoid importing DashboardScreen here to keep
// navigation consistent with the legacy MainDashboard as the app's root.

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final session = provider.currentSession;
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('No quiz results available')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quiz Results'),
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score Card
                _buildScoreCard(session),

                const SizedBox(height: 24),

                // Quiz Info
                _buildQuizInfo(session.quiz),

                const SizedBox(height: 24),

                // Performance Analysis
                if (session.isCompleted) _buildPerformanceAnalysis(session),

                const SizedBox(height: 24),

                // Questions Review
                if (session.isCompleted) _buildQuestionsReview(session),

                const SizedBox(height: 32),

                // Actions
                _buildActions(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(QuizSession session) {
    final score = session.score ?? 0.0;
    final isCompleted = session.isCompleted;

    Color getScoreColor() {
      if (!isCompleted) return Colors.grey;
      if (score >= 90) return Colors.green;
      if (score >= 70) return Colors.blue;
      if (score >= 50) return Colors.orange;
      return Colors.red;
    }

    String getScoreLabel() {
      if (!isCompleted) return 'Not Completed';
      if (score >= 90) return 'Excellent!';
      if (score >= 70) return 'Good Job!';
      if (score >= 50) return 'Fair';
      return 'Needs Improvement';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            getScoreColor(),
            getScoreColor().withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            getScoreLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isCompleted ? score.toStringAsFixed(1) : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isCompleted && session.totalPoints != null) ...[
            const SizedBox(height: 8),
            Text(
              'Total Points: ${((score / 100) * session.totalPoints!).round()}/${session.totalPoints}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizInfo(Quiz quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.onSurfaceColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Topic', quiz.topic),
          _buildInfoRow('Difficulty', quiz.difficulty.toUpperCase()),
          _buildInfoRow('Questions', '${quiz.numberOfQuestions}'),
          _buildInfoRow('Time Limit', '${quiz.timeLimit} minutes'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis(QuizSession session) {
    final quiz = session.quiz;
    final totalQuestions = quiz.questions.length;
    final answeredQuestions = session.userAnswers.length;
    final correctAnswers = session.userAnswers.values
        .where((answer) => answer.isCorrect)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.onSurfaceColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Questions',
                  totalQuestions.toString(),
                  Icons.quiz,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Answered',
                  answeredQuestions.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Correct',
                  correctAnswers.toString(),
                  Icons.check,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Incorrect',
                  (answeredQuestions - correctAnswers).toString(),
                  Icons.close,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsReview(QuizSession session) {
    final quiz = session.quiz;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.onSurfaceColor,
            ),
          ),
          const SizedBox(height: 16),
          ...quiz.questions.map((question) {
            final userAnswer = session.userAnswers[question.id];
            return _buildQuestionReviewCard(question, userAnswer);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(Question question, UserAnswer? userAnswer) {
    final isCorrect = userAnswer?.isCorrect ?? false;
    final userSelectedChoice = userAnswer?.selectedChoiceId;
    // Prefer the flagged correct choice; otherwise fallback to first choice if available
    final correctChoice = question.choices
            .where((choice) => choice.isCorrect)
            .isNotEmpty
        ? question.choices.firstWhere((choice) => choice.isCorrect)
        : (question.choices.isNotEmpty ? question.choices.first : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Question ${question.order}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
              Text(
                isCorrect ? '+${question.points}' : '0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Show user's answer if they answered
          if (userSelectedChoice != null) ...[
            const Text(
              'Your Answer:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                (() {
                  final matches = question.choices
                      .where((choice) => choice.id == userSelectedChoice)
                      .toList();
                  return matches.isNotEmpty
                      ? matches.first.choiceText
                      : 'Unknown selection';
                })(),
                style: TextStyle(
                  fontSize: 12,
                  color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Not Answered',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Show correct answer
          const Text(
            'Correct Answer:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              correctChoice?.choiceText ?? 'Unknown',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, QuizProvider provider) {
    return Column(
      children: [
        CustomButton(
          text: 'Back to Dashboard',
          onPressed: () {
            provider.clearCurrentSession();
            // Pop back to the root (legacy MainDashboard)
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          height: 50,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'View Quiz History',
          onPressed: () {
            provider.clearCurrentSession();
            Navigator.of(context).popUntil((route) => route.isFirst);
            // Navigate to quiz history
          },
          type: ButtonType.outline,
          height: 50,
        ),
      ],
    );
  }
}