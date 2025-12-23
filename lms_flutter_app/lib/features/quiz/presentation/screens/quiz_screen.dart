import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth_screen.dart';
import '../providers/quiz_provider.dart';
import 'create_quiz_screen.dart';
import 'quiz_history_screen.dart';
import 'join_quiz_screen.dart';
import 'my_quizzes_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late QuizProvider _quizProvider;

  @override
  void initState() {
    super.initState();
    _quizProvider = QuizProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _quizProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz System'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            if (authProvider.state == AuthState.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Please log in to access the Quiz System',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        },
                        child: const Text('Go to Login'),
                      )
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.quiz,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quiz System',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.isStudent
                              ? 'Test your knowledge with AI-generated quizzes'
                              : 'Create engaging quizzes for your students',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions based on user type
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (user.isStudent) ...[
                    // Student Actions: Join a live quiz or view history
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(
                          context,
                          'Join Quiz',
                          'Enter quiz code to participate',
                          Icons.login,
                          Colors.blue,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: _quizProvider,
                                  child: const JoinQuizScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          'Quiz History',
                          'View your completed quizzes',
                          Icons.history,
                          Colors.orange,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: _quizProvider,
                                  child: const QuizHistoryScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    // Teacher/Admin Actions
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildActionCard(
                          context,
                          'Create Quiz',
                          'Generate AI-powered quiz',
                          Icons.add_circle,
                          Colors.green,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: _quizProvider,
                                  child: const CreateQuizScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          'My Quizzes',
                          'Manage your created quizzes',
                          Icons.quiz,
                          Colors.purple,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: _quizProvider,
                                  child: const MyQuizzesScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Recent Activity/Statistics
                  Text(
                    user.isStudent ? 'Recent Quizzes' : 'Quiz Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live sessions are no longer listed here. Students should join using the room code
                  // from the teacher portal via the Join Quiz action above.

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          user.isStudent ? Icons.quiz_outlined : Icons.analytics_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.isStudent ? 'No recent quizzes' : 'No quiz data yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.isStudent
                              ? 'Your quiz attempts will appear here'
                              : 'Quiz analytics will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // How it Works Section
                  Text(
                    'How it Works',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (user.isStudent) ...[
                    _buildHowItWorksCard(
                      '1. Join Quiz',
                      'Get the quiz code from your teacher and enter it to join',
                      Icons.login,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildHowItWorksCard(
                      '2. Answer Questions',
                      'Answer multiple-choice questions within the time limit',
                      Icons.quiz,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildHowItWorksCard(
                      '3. View Results',
                      'See your score and review correct answers after submission',
                      Icons.analytics,
                      Colors.orange,
                    ),
                  ] else ...[
                    _buildHowItWorksCard(
                      '1. Set Topic & Difficulty',
                      'Choose your quiz topic and difficulty level (Easy, Medium, Hard, Mixed)',
                      Icons.topic,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildHowItWorksCard(
                      '2. AI Generates Questions',
                      'Our AI creates relevant questions based on your specifications',
                      Icons.auto_awesome,
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildHowItWorksCard(
                      '3. Share Quiz Code',
                      'Get a unique quiz code to share with your students',
                      Icons.share,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildHowItWorksCard(
                      '4. Monitor Results',
                      'Track student participation and view detailed analytics',
                      Icons.analytics,
                      Colors.orange,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}