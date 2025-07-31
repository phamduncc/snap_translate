import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/database_service.dart';
import '../../services/tts_service.dart';
import '../../data/models/translation_model.dart';
import '../../data/models/language_model.dart';
import 'favorites_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TTSService _ttsService = TTSService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<TranslationModel> _translations = [];
  List<TranslationModel> _filteredTranslations = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Filter options
  String? _selectedSourceLanguage;
  String? _selectedTargetLanguage;
  TranslationType? _selectedType;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildTranslationsList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Lịch sử dịch'),
      actions: [
        IconButton(
          onPressed: _navigateToFavorites,
          icon: const Icon(Icons.favorite),
          tooltip: 'Yêu thích',
        ),
        IconButton(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Lọc',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, color: AppColors.errorColor),
                  SizedBox(width: 8),
                  Text('Xóa tất cả'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: AppColors.primaryColor),
                  SizedBox(width: 8),
                  Text('Xuất dữ liệu'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm trong lịch sử...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          filled: true,
          fillColor: AppColors.surfaceColor,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Favorites filter
          FilterChip(
            label: const Text('Yêu thích'),
            selected: _showFavoritesOnly,
            onSelected: (selected) {
              setState(() {
                _showFavoritesOnly = selected;
              });
              _applyFilters();
            },
            avatar: const Icon(Icons.favorite, size: 16),
          ),
          const SizedBox(width: 8),

          // Type filters
          ...TranslationType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type.displayName),
              selected: _selectedType == type,
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? type : null;
                });
                _applyFilters();
              },
              avatar: Text(type.icon, style: const TextStyle(fontSize: 12)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTranslationsList() {
    if (_isLoading && _translations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredTranslations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshTranslations,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _filteredTranslations.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredTranslations.length) {
            return _buildLoadingIndicator();
          }

          final translation = _filteredTranslations[index];
          return _buildTranslationCard(translation);
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
            size: 80,
            color: AppColors.textSecondaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'Không tìm thấy kết quả'
                : 'Chưa có lịch sử dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Bắt đầu dịch để xem lịch sử tại đây',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildTranslationCard(TranslationModel translation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTranslationDetail(translation),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(translation.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          translation.type.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          translation.type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(translation.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppUtils.formatDateTime(translation.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHintColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(translation),
                    icon: Icon(
                      translation.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: translation.isFavorite ? AppColors.errorColor : AppColors.textHintColor,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Original text
              _buildTextSection(
                title: _getLanguageName(translation.sourceLanguage),
                text: translation.originalText,
                onSpeak: () => _speakText(translation.originalText, translation.sourceLanguage),
                onCopy: () => _copyText(translation.originalText),
              ),

              const SizedBox(height: 8),

              // Translated text
              _buildTextSection(
                title: _getLanguageName(translation.targetLanguage),
                text: translation.translatedText,
                onSpeak: () => _speakText(translation.translatedText, translation.targetLanguage),
                onCopy: () => _copyText(translation.translatedText),
                isTranslation: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection({
    required String title,
    required String text,
    required VoidCallback onSpeak,
    required VoidCallback onCopy,
    bool isTranslation = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isTranslation ? AppColors.primaryColor : AppColors.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up),
              iconSize: 16,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy),
              iconSize: 16,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTranslation ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.pop(context),
      tooltip: 'Quay lại',
      child: const Icon(Icons.add),
    );
  }

  // Data loading methods
  Future<void> _loadTranslations() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final translations = await _databaseService.getTranslationHistory(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      setState(() {
        if (_currentPage == 0) {
          _translations = translations;
        } else {
          _translations.addAll(translations);
        }
        _hasMore = translations.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi tải dữ liệu: $e', isError: true);
      }
    }
  }

  Future<void> _refreshTranslations() async {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
      _translations.clear();
      _filteredTranslations.clear();
    });
    await _loadTranslations();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading) {
        _loadTranslations();
      }
    }
  }





  // Filter and search methods
  void _applyFilters() {
    setState(() {
      _filteredTranslations = _translations.where((translation) {
        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          if (!translation.originalText.toLowerCase().contains(searchTerm) &&
              !translation.translatedText.toLowerCase().contains(searchTerm)) {
            return false;
          }
        }

        // Favorites filter
        if (_showFavoritesOnly && !translation.isFavorite) {
          return false;
        }

        // Type filter
        if (_selectedType != null && translation.type != _selectedType) {
          return false;
        }

        // Language filters
        if (_selectedSourceLanguage != null &&
            translation.sourceLanguage != _selectedSourceLanguage) {
          return false;
        }

        if (_selectedTargetLanguage != null &&
            translation.targetLanguage != _selectedTargetLanguage) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    AppUtils.debounce(() {
      _applyFilters();
    }, const Duration(milliseconds: 300));
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilters();
  }

  // Action methods
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc lịch sử'),
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
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'export':
        AppUtils.showSnackBar(context, 'Tính năng xuất dữ liệu sẽ được thêm sau');
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả lịch sử'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả lịch sử dịch? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllHistory();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    try {
      await _databaseService.clearAllData();
      setState(() {
        _translations.clear();
        _filteredTranslations.clear();
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Đã xóa tất cả lịch sử');
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi xóa dữ liệu: $e', isError: true);
      }
    }
  }

  // Utility methods
  Future<void> _toggleFavorite(TranslationModel translation) async {
    try {
      await _databaseService.updateTranslationFavorite(
        translation.id,
        !translation.isFavorite,
      );

      setState(() {
        final index = _translations.indexWhere((t) => t.id == translation.id);
        if (index != -1) {
          _translations[index] = translation.copyWith(isFavorite: !translation.isFavorite);
        }
      });

      _applyFilters();

      if (mounted) {
        AppUtils.showSnackBar(
          context,
          translation.isFavorite ? 'Đã bỏ yêu thích' : 'Đã thêm vào yêu thích',
        );
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi cập nhật: $e', isError: true);
      }
    }
  }

  void _showTranslationDetail(TranslationModel translation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết dịch thuật'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Loại:', translation.type.displayName),
              _buildDetailRow('Thời gian:', AppUtils.formatDateTime(translation.createdAt)),
              _buildDetailRow('Từ:', _getLanguageName(translation.sourceLanguage)),
              _buildDetailRow('Sang:', _getLanguageName(translation.targetLanguage)),
              if (translation.confidence > 0)
                _buildDetailRow('Độ tin cậy:', '${(translation.confidence * 100).toInt()}%'),
              const SizedBox(height: 16),
              const Text('Văn bản gốc:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(translation.originalText),
              const SizedBox(height: 16),
              const Text('Bản dịch:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(translation.translatedText),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _shareTranslation(translation),
            child: const Text('Chia sẻ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _shareTranslation(TranslationModel translation) {
    final shareText = '''
${_getLanguageName(translation.sourceLanguage)}: ${translation.originalText}

${_getLanguageName(translation.targetLanguage)}: ${translation.translatedText}

Dịch bởi SnapTranslate
''';
    AppUtils.shareText(shareText);
  }

  Future<void> _speakText(String text, String languageCode) async {
    try {
      await _ttsService.speak(text, languageCode: languageCode);
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi đọc văn bản: $e', isError: true);
      }
    }
  }

  void _copyText(String text) {
    AppUtils.copyToClipboard(text);
    if (mounted) {
      AppUtils.showSnackBar(context, 'Đã sao chép vào clipboard');
    }
  }

  Color _getTypeColor(TranslationType type) {
    switch (type) {
      case TranslationType.text:
        return AppColors.primaryColor;
      case TranslationType.image:
        return AppColors.successColor;
      case TranslationType.camera:
        return AppColors.warningColor;
      case TranslationType.voice:
        return AppColors.secondaryColor;
    }
  }

  String _getLanguageName(String languageCode) {
    final language = LanguageModel.defaultLanguages
        .firstWhere((lang) => lang.code == languageCode,
                   orElse: () => LanguageModel(code: languageCode, name: languageCode, nativeName: languageCode));
    return language.nativeName;
  }

  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesScreen(),
      ),
    );
  }
}
