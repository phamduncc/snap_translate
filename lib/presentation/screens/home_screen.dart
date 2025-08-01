import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/feature_card.dart';
import '../widgets/language_selector.dart';
import 'quiz_screen.dart';
import 'image_translation_screen.dart';
import 'camera_translation_screen.dart';
import 'history_screen.dart';
import 'vocabulary_screen.dart';
import 'voice_translation_screen.dart';
import 'text_translation_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sourceLanguage = AppConstants.defaultSourceLanguage;
  String _targetLanguage = AppConstants.defaultTargetLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildLanguageSelector(),
              Expanded(
                child: _buildFeatureGrid(),
              ),
              // _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.translate,
              color: AppColors.textOnPrimaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                Text(
                  'Smart Translation', // Keep English for now as it's a tagline
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigateToAnalytics(),
            icon: const Icon(
              Icons.analytics,
              color: AppColors.textSecondaryColor,
            ),
          ),
          IconButton(
            onPressed: () => _navigateToSettings(),
            icon: const Icon(
              Icons.settings,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: LanguageSelector(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        onLanguagesChanged: (source, target) {
          setState(() {
            _sourceLanguage = source;
            _targetLanguage = target;
          });
        },
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: [
          FeatureCard(
            icon: Icons.translate,
            title: AppLocalizations.of(context)?.textTranslation ?? 'Text Translation',
            subtitle: 'Enter and translate text',
            color: AppColors.primaryColor,
            onTap: () => _navigateToTextTranslation(),
          ),
          FeatureCard(
            icon: Icons.camera_alt,
            title: AppLocalizations.of(context)?.imageTranslation ?? 'Image Translation',
            subtitle: 'Take photo and translate text',
            color: AppColors.secondaryColor,
            onTap: () => _navigateToImageTranslation(),
          ),
          FeatureCard(
            icon: Icons.quiz,
            title: AppLocalizations.of(context)?.quizMode ?? 'Quiz Mode',
            subtitle: AppLocalizations.of(context)?.testYourKnowledge ?? 'Test your vocabulary knowledge',
            color: Colors.purple,
            onTap: () => _navigateToQuiz(),
          ),
          FeatureCard(
            icon: Icons.history,
            title: AppLocalizations.of(context)?.history ?? 'History',
            subtitle: 'View translation history',
            color: AppColors.successColor,
            onTap: () => _navigateToHistory(),
          ),
          FeatureCard(
            icon: Icons.school,
            title: AppLocalizations.of(context)?.vocabulary ?? 'Vocabulary',
            subtitle: 'Flashcards and review',
            color: AppColors.warningColor,
            onTap: () => _navigateToVocabulary(),
          ),
          FeatureCard(
            icon: Icons.mic,
            title: AppLocalizations.of(context)?.voiceTranslation ?? 'Voice Translation',
            subtitle: 'Two-way voice translation',
            color: AppColors.errorColor,
            onTap: () => _navigateToVoiceTranslation(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToImageTranslation(),
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonSecondaryColor,
                foregroundColor: AppColors.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCameraTranslation(),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Mở camera'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToImageTranslation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageTranslationScreen(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ),
      ),
    );
  }

  void _navigateToCameraTranslation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraTranslationScreen(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  void _navigateToVocabulary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VocabularyScreen(),
      ),
    );
  }

  void _navigateToQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizScreen(),
      ),
    );
  }

  void _navigateToVoiceTranslation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceTranslationScreen(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ),
      ),
    );
  }

  void _navigateToTextTranslation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextTranslationScreen(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ),
      ),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnalyticsScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
