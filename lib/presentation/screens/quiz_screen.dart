import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/quiz_model.dart';
import '../../services/quiz_service.dart';
import 'quiz_setup_screen.dart';
import 'quiz_play_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  QuizStats? _stats;
  List<QuizSession> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await _quizService.getQuizStats();
      final sessions = await _quizService.getRecentQuizSessions(limit: 5);
      
      setState(() {
        _stats = stats;
        _recentSessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppUtils.showSnackBar(context, 'Error loading quiz data: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewQuiz,
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.quiz, color: Colors.white),
        label: Text(
          'Start Quiz',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Quiz Mode'),
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: _showDetailedStats,
          tooltip: 'Statistics',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentSessions(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_stats!.currentStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, 
                               color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_stats!.currentStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Quizzes',
                    '${_stats!.totalQuizzes}',
                    Icons.quiz,
                    AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Accuracy',
                    _stats!.formattedAverageAccuracy,
                    Icons.track_changes,
                    AppColors.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Questions',
                    '${_stats!.totalQuestions}',
                    Icons.help,
                    AppColors.warningColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Time Spent',
                    _stats!.formattedTotalTime,
                    Icons.timer,
                    AppColors.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Start',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Easy Quiz',
                '10 questions',
                Icons.sentiment_satisfied,
                AppColors.successColor,
                () => _startQuickQuiz(QuizDifficulty.easy),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Medium Quiz',
                '15 questions',
                Icons.sentiment_neutral,
                AppColors.warningColor,
                () => _startQuickQuiz(QuizDifficulty.medium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Hard Quiz',
                '20 questions',
                Icons.sentiment_dissatisfied,
                AppColors.errorColor,
                () => _startQuickQuiz(QuizDifficulty.hard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Custom Quiz',
                'Your settings',
                Icons.settings,
                AppColors.primaryColor,
                _startNewQuiz,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessions() {
    if (_recentSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 48,
                color: AppColors.textSecondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No quiz sessions yet',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your first quiz to see your progress here',
                style: TextStyle(
                  color: AppColors.textHintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...(_recentSessions.map((session) => _buildSessionCard(session)).toList()),
      ],
    );
  }

  Widget _buildSessionCard(QuizSession session) {
    final accuracyColor = session.accuracy >= 0.8
        ? AppColors.successColor
        : session.accuracy >= 0.6
            ? AppColors.warningColor
            : AppColors.errorColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accuracyColor.withOpacity(0.2),
          child: Icon(
            Icons.quiz,
            color: accuracyColor,
          ),
        ),
        title: Text(
          '${session.difficulty.toString().split('.').last.toUpperCase()} - ${session.mode.toString().split('.').last}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${session.correctAnswers}/${session.totalQuestions} correct • ${session.formattedTime}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accuracyColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            session.formattedAccuracy,
            style: TextStyle(
              color: accuracyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _startNewQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizSetupScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _startQuickQuiz(QuizDifficulty difficulty) async {
    try {
      final session = await _quizService.createQuizSession(
        mode: QuizMode.mixed,
        difficulty: difficulty,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPlayScreen(session: session),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Error creating quiz: $e', isError: true);
      }
    }
  }

  void _showDetailedStats() {
    // TODO: Implement detailed stats screen
    AppUtils.showSnackBar(context, 'Detailed stats coming soon!');
  }
}
