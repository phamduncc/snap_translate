import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/database_service.dart';
import '../../services/tts_service.dart';

import '../../data/models/vocabulary_model.dart';
import '../../data/models/language_model.dart';


class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final TTSService _ttsService = TTSService();

  List<VocabularyModel> _vocabulary = [];
  List<VocabularyModel> _filteredVocabulary = [];
  bool _isLoading = false;

  // Study mode
  bool _isStudyMode = false;
  int _currentCardIndex = 0;
  bool _showAnswer = false;

  // Filter options
  String? _selectedSourceLanguage;
  String? _selectedTargetLanguage;
  bool _showDueForReview = false;
  bool _showMastered = true;

  // Animation controllers
  late AnimationController _flipController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isStudyMode ? _buildStudyMode() : _buildVocabularyList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isStudyMode ? 'Học từ vựng' : 'Từ vựng của tôi'),
      actions: [
        if (!_isStudyMode) ...[
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'study_mode',
                child: Row(
                  children: [
                    Icon(Icons.school, color: AppColors.primaryColor),
                    SizedBox(width: 8),
                    Text('Chế độ học'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_from_history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.successColor),
                    SizedBox(width: 8),
                    Text('Nhập từ lịch sử'),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          IconButton(
            onPressed: _exitStudyMode,
            icon: const Icon(Icons.close),
            tooltip: 'Thoát chế độ học',
          ),
        ],
      ],
    );
  }

  Widget _buildVocabularyList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredVocabulary.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshVocabulary,
      child: Column(
        children: [
          _buildStatsCard(),
          _buildFilterChips(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: _filteredVocabulary.length,
              itemBuilder: (context, index) {
                final vocab = _filteredVocabulary[index];
                return _buildVocabularyCard(vocab);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyMode() {
    if (_filteredVocabulary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 80,
              color: AppColors.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có từ vựng để học',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm từ vựng mới để bắt đầu học',
              style: TextStyle(color: AppColors.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _exitStudyMode,
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStudyProgress(),
        Expanded(
          child: Center(
            child: _buildFlashCard(),
          ),
        ),
        _buildStudyControls(),
      ],
    );
  }

  // Data loading methods
  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vocabulary = await _databaseService.getVocabulary();
      setState(() {
        _vocabulary = vocabulary;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi tải từ vựng: $e', isError: true);
      }
    }
  }

  Future<void> _refreshVocabulary() async {
    await _loadVocabulary();
  }

  void _applyFilters() {
    setState(() {
      _filteredVocabulary = _vocabulary.where((vocab) {
        // Language filters
        if (_selectedSourceLanguage != null &&
            vocab.sourceLanguage != _selectedSourceLanguage) {
          return false;
        }

        if (_selectedTargetLanguage != null &&
            vocab.targetLanguage != _selectedTargetLanguage) {
          return false;
        }

        // Due for review filter
        if (_showDueForReview && !vocab.isDueForReview) {
          return false;
        }

        // Mastered filter
        if (!_showMastered && vocab.isMastered) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  // UI Builder methods
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 80,
            color: AppColors.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có từ vựng nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm từ vựng mới để bắt đầu học',
            style: TextStyle(color: AppColors.textHintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddVocabularyDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm từ vựng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalWords = _vocabulary.length;
    final masteredWords = _vocabulary.where((v) => v.isMastered).length;
    final dueForReview = _vocabulary.where((v) => v.isDueForReview).length;

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Tổng số', totalWords.toString(), Icons.book),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem('Đã thuộc', masteredWords.toString(), Icons.check_circle),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem('Cần ôn', dueForReview.toString(), Icons.schedule),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Cần ôn tập'),
            selected: _showDueForReview,
            onSelected: (selected) {
              setState(() {
                _showDueForReview = selected;
              });
              _applyFilters();
            },
            avatar: const Icon(Icons.schedule, size: 16),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Đã thuộc'),
            selected: !_showMastered,
            onSelected: (selected) {
              setState(() {
                _showMastered = !selected;
              });
              _applyFilters();
            },
            avatar: const Icon(Icons.check_circle, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyCard(VocabularyModel vocab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showVocabularyDetail(vocab),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (vocab.isMastered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Đã thuộc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (vocab.isDueForReview && !vocab.isMastered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Cần ôn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vocab.translation,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (vocab.definition != null) ...[
                const SizedBox(height: 4),
                Text(
                  vocab.definition!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_getLanguageName(vocab.sourceLanguage)} → ${_getLanguageName(vocab.targetLanguage)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHintColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _speakWord(vocab.word, vocab.sourceLanguage),
                    icon: const Icon(Icons.volume_up, size: 20),
                  ),
                  IconButton(
                    onPressed: () => _speakWord(vocab.translation, vocab.targetLanguage),
                    icon: const Icon(Icons.volume_up_outlined, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action methods
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc từ vựng'),
        content: const Text('Tính năng lọc nâng cao sẽ được thêm sau'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'study_mode':
        _enterStudyMode();
        break;
      case 'import_from_history':
        AppUtils.showSnackBar(context, 'Tính năng nhập từ lịch sử sẽ được thêm sau');
        break;
    }
  }

  void _enterStudyMode() {
    if (_filteredVocabulary.isEmpty) {
      AppUtils.showSnackBar(context, 'Không có từ vựng để học', isError: true);
      return;
    }

    setState(() {
      _isStudyMode = true;
      _currentCardIndex = 0;
      _showAnswer = false;
    });
  }

  void _exitStudyMode() {
    setState(() {
      _isStudyMode = false;
      _currentCardIndex = 0;
      _showAnswer = false;
    });
  }

  void _showAddVocabularyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm từ vựng'),
        content: const Text('Tính năng thêm từ vựng sẽ được thêm sau'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showVocabularyDetail(VocabularyModel vocab) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vocab.word),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nghĩa: ${vocab.translation}'),
            if (vocab.definition != null) ...[
              const SizedBox(height: 8),
              Text('Định nghĩa: ${vocab.definition}'),
            ],
            if (vocab.example != null) ...[
              const SizedBox(height: 8),
              Text('Ví dụ: ${vocab.example}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _speakWord(String text, String languageCode) async {
    try {
      await _ttsService.speak(text, languageCode: languageCode);
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi đọc từ: $e', isError: true);
      }
    }
  }

  String _getLanguageName(String languageCode) {
    final language = LanguageModel.defaultLanguages
        .firstWhere((lang) => lang.code == languageCode,
                   orElse: () => LanguageModel(code: languageCode, name: languageCode, nativeName: languageCode));
    return language.nativeName;
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddVocabularyDialog,
      tooltip: 'Thêm từ vựng',
      child: const Icon(Icons.add),
    );
  }

  // Study mode methods (simplified)
  Widget _buildStudyProgress() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: LinearProgressIndicator(
        value: _filteredVocabulary.isNotEmpty
            ? (_currentCardIndex + 1) / _filteredVocabulary.length
            : 0,
        backgroundColor: AppColors.borderColor,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
      ),
    );
  }

  Widget _buildFlashCard() {
    if (_currentCardIndex >= _filteredVocabulary.length) {
      return const Text('Không có thẻ từ vựng');
    }

    final vocab = _filteredVocabulary[_currentCardIndex];

    return GestureDetector(
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: Container(
        width: 300,
        height: 200,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _showAnswer ? vocab.translation : vocab.word,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStudyControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _currentCardIndex > 0 ? _previousCard : null,
            child: const Text('Trước'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showAnswer = !_showAnswer;
              });
            },
            child: Text(_showAnswer ? 'Ẩn đáp án' : 'Hiện đáp án'),
          ),
          ElevatedButton(
            onPressed: _currentCardIndex < _filteredVocabulary.length - 1 ? _nextCard : null,
            child: const Text('Sau'),
          ),
        ],
      ),
    );
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        _showAnswer = false;
      });
    }
  }

  void _nextCard() {
    if (_currentCardIndex < _filteredVocabulary.length - 1) {
      setState(() {
        _currentCardIndex++;
        _showAnswer = false;
      });
    }
  }
}
