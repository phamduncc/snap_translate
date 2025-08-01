import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/language_model.dart';
import '../../services/quiz_service.dart';
import 'quiz_play_screen.dart';


class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final QuizService _quizService = QuizService();
  
  QuizMode _selectedMode = QuizMode.mixed;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;
  String? _selectedSourceLanguage;
  String? _selectedTargetLanguage;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Setup'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeSelection(),
            const SizedBox(height: 24),
            _buildDifficultySelection(),
            const SizedBox(height: 24),
            _buildLanguageSelection(),
            const SizedBox(height: 32),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Quiz Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...QuizMode.values.map((mode) => _buildModeOption(mode)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(QuizMode mode) {
    final isSelected = _selectedMode == mode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModeName(mode),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primaryColor : null,
                      ),
                    ),
                    Text(
                      _getModeDescription(mode),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryColor,
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

  Widget _buildDifficultySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.warningColor),
                const SizedBox(width: 8),
                const Text(
                  'Difficulty Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...QuizDifficulty.values.map((difficulty) => _buildDifficultyOption(difficulty)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(QuizDifficulty difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    final color = _getDifficultyColor(difficulty);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedDifficulty = difficulty),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getDifficultyName(difficulty),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getDifficultyQuestionCount(difficulty),
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getDifficultyDescription(difficulty),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryColor,
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

  Widget _buildLanguageSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: AppColors.successColor),
                const SizedBox(width: 8),
                const Text(
                  'Language Filter (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to include all vocabulary',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSourceLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Source Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _getLanguageDropdownItems(),
                    onChanged: (value) => setState(() => _selectedSourceLanguage = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTargetLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Target Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _getLanguageDropdownItems(),
                    onChanged: (value) => setState(() => _selectedTargetLanguage = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createAndStartQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Start Quiz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getLanguageDropdownItems() {
    final languages = LanguageModel.defaultLanguages;
    return languages.map((language) {
      return DropdownMenuItem<String>(
        value: language.code,
        child: Text(language.nativeName),
      );
    }).toList();
  }

  String _getModeName(QuizMode mode) {
    switch (mode) {
      case QuizMode.mixed:
        return 'Mixed Mode';
      case QuizMode.translationOnly:
        return 'Translation Only';
      case QuizMode.multipleChoiceOnly:
        return 'Multiple Choice Only';
      case QuizMode.listeningOnly:
        return 'Listening Only';
      case QuizMode.custom:
        return 'Custom Mode';
    }
  }

  String _getModeDescription(QuizMode mode) {
    switch (mode) {
      case QuizMode.mixed:
        return 'Mix of all question types for comprehensive practice';
      case QuizMode.translationOnly:
        return 'Focus on translation skills';
      case QuizMode.multipleChoiceOnly:
        return 'Quick recognition practice';
      case QuizMode.listeningOnly:
        return 'Audio-based questions';
      case QuizMode.custom:
        return 'Customizable question types';
    }
  }

  String _getDifficultyName(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
      case QuizDifficulty.expert:
        return 'Expert';
    }
  }

  String _getDifficultyQuestionCount(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return '10 questions';
      case QuizDifficulty.medium:
        return '15 questions';
      case QuizDifficulty.hard:
        return '20 questions';
      case QuizDifficulty.expert:
        return '25 questions';
    }
  }

  String _getDifficultyDescription(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Perfect for beginners, includes hints';
      case QuizDifficulty.medium:
        return 'Balanced challenge for regular practice';
      case QuizDifficulty.hard:
        return 'Challenging questions, fewer options';
      case QuizDifficulty.expert:
        return 'Maximum challenge with time limits';
    }
  }

  Color _getDifficultyColor(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return AppColors.successColor;
      case QuizDifficulty.medium:
        return AppColors.warningColor;
      case QuizDifficulty.hard:
        return AppColors.errorColor;
      case QuizDifficulty.expert:
        return Colors.purple;
    }
  }

  Future<void> _createAndStartQuiz() async {
    setState(() => _isCreating = true);

    try {
      final session = await _quizService.createQuizSession(
        mode: _selectedMode,
        difficulty: _selectedDifficulty,
        sourceLanguage: _selectedSourceLanguage,
        targetLanguage: _selectedTargetLanguage,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPlayScreen(session: session),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        AppUtils.showSnackBar(context, 'Error creating quiz: $e', isError: true);
      }
    }
  }
}
