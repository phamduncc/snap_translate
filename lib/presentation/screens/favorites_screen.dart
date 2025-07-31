import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/database_service.dart';
import '../../services/tts_service.dart';
import '../../services/haptic_service.dart';
import '../../data/models/translation_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();

  List<TranslationModel> _favorites = [];
  List<TranslationModel> _filteredFavorites = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedLanguageFilter = 'all';

  late AnimationController _listController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavorites();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _databaseService.getFavoriteTranslations();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
      
      _applyFilters();
      _listController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi tải yêu thích: $e', isError: true);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredFavorites = _favorites.where((translation) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!translation.originalText.toLowerCase().contains(query) &&
              !translation.translatedText.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        // Language filter
        if (_selectedLanguageFilter != 'all') {
          if (translation.sourceLanguage != _selectedLanguageFilter &&
              translation.targetLanguage != _selectedLanguageFilter) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildFavoritesList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Yêu thích (${_filteredFavorites.length})'),
      actions: [
        if (_favorites.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_favorites',
                child: Row(
                  children: [
                    Icon(Icons.download, color: AppColors.primaryColor),
                    SizedBox(width: 8),
                    Text('Xuất danh sách'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: AppColors.errorColor),
                    SizedBox(width: 8),
                    Text('Xóa tất cả'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm trong yêu thích...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Language filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                _buildFilterChip('Tiếng Anh', 'en'),
                _buildFilterChip('Tiếng Việt', 'vi'),
                _buildFilterChip('Tiếng Trung', 'zh'),
                _buildFilterChip('Tiếng Nhật', 'ja'),
                _buildFilterChip('Tiếng Hàn', 'ko'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedLanguageFilter == value;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedLanguageFilter = value;
          });
          _applyFilters();
          _hapticService.buttonPress();
        },
        selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredFavorites.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _listAnimation.value,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: _filteredFavorites.length,
            itemBuilder: (context, index) {
              final translation = _filteredFavorites[index];
              return _buildFavoriteCard(translation, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.favorite_border,
            size: 80,
            color: AppColors.textHintColor,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Không tìm thấy kết quả'
                : 'Chưa có bản dịch yêu thích',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Đánh dấu yêu thích các bản dịch để xem ở đây',
            style: const TextStyle(color: AppColors.textHintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(TranslationModel translation, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _showTranslationDetail(translation),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with language info and actions
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_getLanguageName(translation.sourceLanguage)} → ${_getLanguageName(translation.targetLanguage)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _speakText(translation.originalText, translation.sourceLanguage),
                            icon: const Icon(Icons.volume_up, size: 20),
                            tooltip: 'Nghe bản gốc',
                          ),
                          IconButton(
                            onPressed: () => _speakText(translation.translatedText, translation.targetLanguage),
                            icon: const Icon(Icons.volume_up_outlined, size: 20),
                            tooltip: 'Nghe bản dịch',
                          ),
                          IconButton(
                            onPressed: () => _removeFavorite(translation),
                            icon: const Icon(Icons.favorite, color: AppColors.errorColor, size: 20),
                            tooltip: 'Bỏ yêu thích',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Original text
                      Text(
                        translation.originalText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Translated text
                      Text(
                        translation.translatedText,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Footer with date and actions
                      Row(
                        children: [
                          Text(
                            AppUtils.formatDateTime(translation.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHintColor,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _copyTranslation(translation),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Sao chép'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _shareTranslation(translation),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Chia sẻ'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Action methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_favorites':
        _exportFavorites();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  Future<void> _removeFavorite(TranslationModel translation) async {
    try {
      await _databaseService.updateTranslationFavorite(translation.id, false);
      setState(() {
        _favorites.removeWhere((t) => t.id == translation.id);
      });
      _applyFilters();
      
      await _hapticService.success();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Đã bỏ yêu thích');
      }
    } catch (e) {
      await _hapticService.error();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi bỏ yêu thích: $e', isError: true);
      }
    }
  }

  Future<void> _speakText(String text, String languageCode) async {
    try {
      await _ttsService.speak(text, languageCode: languageCode);
      await _hapticService.buttonPress();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi phát âm: $e', isError: true);
      }
    }
  }

  void _copyTranslation(TranslationModel translation) {
    final text = '${translation.originalText}\n${translation.translatedText}';
    Clipboard.setData(ClipboardData(text: text));
    AppUtils.showSnackBar(context, 'Đã sao chép');
    _hapticService.buttonPress();
  }

  void _shareTranslation(TranslationModel translation) {
    final shareText = 'Gốc: ${translation.originalText}\nDịch: ${translation.translatedText}\n\n- Từ SnapTranslate';
    Clipboard.setData(ClipboardData(text: shareText));
    AppUtils.showSnackBar(context, 'Đã sao chép để chia sẻ');
    _hapticService.buttonPress();
  }

  void _showTranslationDetail(TranslationModel translation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết bản dịch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngôn ngữ: ${_getLanguageName(translation.sourceLanguage)} → ${_getLanguageName(translation.targetLanguage)}'),
            const SizedBox(height: 8),
            Text('Loại: ${_getTypeDisplayName(translation.type)}'),
            const SizedBox(height: 8),
            Text('Độ tin cậy: ${(translation.confidence * 100).toInt()}%'),
            const SizedBox(height: 8),
            Text('Thời gian: ${AppUtils.formatDateTime(translation.createdAt)}'),
            const SizedBox(height: 16),
            const Text('Văn bản gốc:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(translation.originalText),
            const SizedBox(height: 12),
            const Text('Bản dịch:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(translation.translatedText),
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

  void _exportFavorites() {
    final favoritesText = _favorites.map((t) => 
      '${t.originalText} | ${t.translatedText} | ${_getLanguageName(t.sourceLanguage)} → ${_getLanguageName(t.targetLanguage)}'
    ).join('\n');
    
    Clipboard.setData(ClipboardData(text: favoritesText));
    AppUtils.showSnackBar(context, 'Đã sao chép danh sách yêu thích');
    _hapticService.buttonPress();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả yêu thích'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả bản dịch yêu thích? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllFavorites();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllFavorites() async {
    try {
      for (final translation in _favorites) {
        await _databaseService.updateTranslationFavorite(translation.id, false);
      }
      
      setState(() {
        _favorites.clear();
      });
      _applyFilters();
      
      await _hapticService.success();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Đã xóa tất cả yêu thích');
      }
    } catch (e) {
      await _hapticService.error();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi xóa yêu thích: $e', isError: true);
      }
    }
  }

  String _getLanguageName(String languageCode) {
    const languageNames = {
      'en': 'EN',
      'vi': 'VI',
      'zh': 'ZH',
      'ja': 'JA',
      'ko': 'KO',
      'fr': 'FR',
      'de': 'DE',
      'es': 'ES',
      'it': 'IT',
      'ru': 'RU',
      'th': 'TH',
      'ar': 'AR',
      'hi': 'HI',
    };
    
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  String _getTypeDisplayName(TranslationType type) {
    switch (type) {
      case TranslationType.text:
        return 'Văn bản';
      case TranslationType.image:
        return 'Hình ảnh';
      case TranslationType.voice:
        return 'Giọng nói';
      case TranslationType.camera:
        return 'Camera';
    }
  }
}
