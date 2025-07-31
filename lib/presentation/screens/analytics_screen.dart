import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/database_service.dart';
import '../../data/models/translation_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();

  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalytics();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final translations = await _databaseService.getTranslationHistory();
      final analytics = _calculateAnalytics(translations);
      
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
      
      _chartController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<TranslationModel> translations) {
    if (translations.isEmpty) {
      return {
        'totalTranslations': 0,
        'todayTranslations': 0,
        'weekTranslations': 0,
        'monthTranslations': 0,
        'averageConfidence': 0.0,
        'languagePairs': <String, int>{},
        'translationTypes': <String, int>{},
        'dailyActivity': <String, int>{},
        'topLanguages': <String, int>{},
        'confidenceDistribution': <String, int>{},
      };
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;
    double totalConfidence = 0.0;
    
    final languagePairs = <String, int>{};
    final translationTypes = <String, int>{};
    final dailyActivity = <String, int>{};
    final topLanguages = <String, int>{};
    final confidenceDistribution = <String, int>{};

    for (final translation in translations) {
      final date = DateTime(
        translation.createdAt.year,
        translation.createdAt.month,
        translation.createdAt.day,
      );
      
      // Count by time period
      if (date.isAtSameMomentAs(today)) todayCount++;
      if (date.isAfter(weekAgo) || date.isAtSameMomentAs(weekAgo)) weekCount++;
      if (date.isAfter(monthAgo) || date.isAtSameMomentAs(monthAgo)) monthCount++;
      
      // Confidence
      totalConfidence += translation.confidence;
      
      // Language pairs
      final pair = '${translation.sourceLanguage} → ${translation.targetLanguage}';
      languagePairs[pair] = (languagePairs[pair] ?? 0) + 1;
      
      // Translation types
      final type = translation.type.toString().split('.').last;
      translationTypes[type] = (translationTypes[type] ?? 0) + 1;
      
      // Daily activity
      final dayKey = '${date.day}/${date.month}';
      dailyActivity[dayKey] = (dailyActivity[dayKey] ?? 0) + 1;
      
      // Top languages
      topLanguages[translation.sourceLanguage] = 
          (topLanguages[translation.sourceLanguage] ?? 0) + 1;
      topLanguages[translation.targetLanguage] = 
          (topLanguages[translation.targetLanguage] ?? 0) + 1;
      
      // Confidence distribution
      final confidenceRange = _getConfidenceRange(translation.confidence);
      confidenceDistribution[confidenceRange] = 
          (confidenceDistribution[confidenceRange] ?? 0) + 1;
    }

    return {
      'totalTranslations': translations.length,
      'todayTranslations': todayCount,
      'weekTranslations': weekCount,
      'monthTranslations': monthCount,
      'averageConfidence': translations.isNotEmpty 
          ? totalConfidence / translations.length 
          : 0.0,
      'languagePairs': languagePairs,
      'translationTypes': translationTypes,
      'dailyActivity': dailyActivity,
      'topLanguages': topLanguages,
      'confidenceDistribution': confidenceDistribution,
    };
  }

  String _getConfidenceRange(double confidence) {
    if (confidence >= 0.9) return 'Rất cao (90-100%)';
    if (confidence >= 0.7) return 'Cao (70-89%)';
    if (confidence >= 0.5) return 'Trung bình (50-69%)';
    return 'Thấp (<50%)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê sử dụng'),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_analytics['totalTranslations'] == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 80,
              color: AppColors.textHintColor,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu thống kê',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy sử dụng ứng dụng để xem thống kê',
              style: TextStyle(color: AppColors.textHintColor),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildLanguagePairsChart(),
          const SizedBox(height: 24),
          _buildTranslationTypesChart(),
          const SizedBox(height: 24),
          _buildConfidenceChart(),
          const SizedBox(height: 24),
          _buildTopLanguages(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Hôm nay',
            _analytics['todayTranslations'].toString(),
            Icons.today,
            AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tuần này',
            _analytics['weekTranslations'].toString(),
            Icons.date_range,
            AppColors.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tháng này',
            _analytics['monthTranslations'].toString(),
            Icons.calendar_month,
            AppColors.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _chartAnimation.value),
          child: Opacity(
            opacity: _chartAnimation.value,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguagePairsChart() {
    final languagePairs = _analytics['languagePairs'] as Map<String, int>;
    final sortedPairs = languagePairs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cặp ngôn ngữ phổ biến',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedPairs.take(5).map((entry) => 
              _buildBarChart(entry.key, entry.value, languagePairs.values.reduce(math.max))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationTypesChart() {
    final types = _analytics['translationTypes'] as Map<String, int>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại dịch thuật',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...types.entries.map((entry) => 
              _buildBarChart(
                _getTypeDisplayName(entry.key), 
                entry.value, 
                types.values.reduce(math.max)
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceChart() {
    final confidence = _analytics['confidenceDistribution'] as Map<String, int>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Độ tin cậy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'TB: ${(_analytics['averageConfidence'] * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.successColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...confidence.entries.map((entry) => 
              _buildBarChart(entry.key, entry.value, confidence.values.reduce(math.max))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopLanguages() {
    final languages = _analytics['topLanguages'] as Map<String, int>;
    final sortedLanguages = languages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ngôn ngữ sử dụng nhiều nhất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedLanguages.take(5).map((entry) => 
              _buildBarChart(
                _getLanguageDisplayName(entry.key), 
                entry.value, 
                languages.values.reduce(math.max)
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String label, int value, int maxValue) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;
    
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage * _chartAnimation.value,
                backgroundColor: AppColors.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'text':
        return 'Văn bản';
      case 'image':
        return 'Hình ảnh';
      case 'voice':
        return 'Giọng nói';
      case 'camera':
        return 'Camera';
      default:
        return type;
    }
  }

  String _getLanguageDisplayName(String code) {
    const languageNames = {
      'en': 'Tiếng Anh',
      'vi': 'Tiếng Việt',
      'zh': 'Tiếng Trung',
      'ja': 'Tiếng Nhật',
      'ko': 'Tiếng Hàn',
      'fr': 'Tiếng Pháp',
      'de': 'Tiếng Đức',
      'es': 'Tiếng Tây Ban Nha',
      'it': 'Tiếng Ý',
      'ru': 'Tiếng Nga',
      'th': 'Tiếng Thái',
      'ar': 'Tiếng Ả Rập',
      'hi': 'Tiếng Hindi',
    };
    
    return languageNames[code] ?? code.toUpperCase();
  }
}
