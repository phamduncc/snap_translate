import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/translation_service.dart';
import '../../services/tts_service.dart';
import '../../services/database_service.dart';
import '../../services/haptic_service.dart';
import '../../data/models/translation_model.dart';
import '../widgets/language_selector.dart';

class TextTranslationScreen extends StatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final String? initialText;

  const TextTranslationScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.initialText,
  });

  @override
  State<TextTranslationScreen> createState() => _TextTranslationScreenState();
}

class _TextTranslationScreenState extends State<TextTranslationScreen>
    with TickerProviderStateMixin {
  final TranslationService _translationService = TranslationService();
  final TTSService _ttsService = TTSService();
  final DatabaseService _databaseService = DatabaseService();
  final HapticService _hapticService = HapticService();

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  String _sourceLanguage = '';
  String _targetLanguage = '';
  String _translatedText = '';
  bool _isTranslating = false;
  bool _hasTranslation = false;
  double _confidence = 0.0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Quick actions
  final List<String> _quickPhrases = [
    'Hello, how are you?',
    'Thank you very much',
    'Excuse me',
    'Where is the bathroom?',
    'How much does this cost?',
    'I don\'t understand',
    'Can you help me?',
    'What time is it?',
  ];

  @override
  void initState() {
    super.initState();
    _sourceLanguage = widget.sourceLanguage;
    _targetLanguage = widget.targetLanguage;
    
    if (widget.initialText != null) {
      _inputController.text = widget.initialText!;
    }
    
    _initializeAnimations();
    _setupTextListener();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupTextListener() {
    _inputController.addListener(() {
      if (_inputController.text.isEmpty && _hasTranslation) {
        setState(() {
          _translatedText = '';
          _hasTranslation = false;
          _confidence = 0.0;
        });
        _fadeController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: _buildTranslationInterface(),
          ),
          _buildQuickPhrases(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Dịch văn bản'),
      actions: [
        IconButton(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all),
          tooltip: 'Xóa tất cả',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'swap_languages',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.primaryColor),
                  SizedBox(width: 8),
                  Text('Đổi ngôn ngữ'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'detect_language',
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.successColor),
                  SizedBox(width: 8),
                  Text('Tự động nhận dạng'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'copy_translation',
              child: Row(
                children: [
                  Icon(Icons.copy, color: AppColors.warningColor),
                  SizedBox(width: 8),
                  Text('Sao chép bản dịch'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: LanguageSelector(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        onLanguagesChanged: (source, target) {
          setState(() {
            _sourceLanguage = source;
            _targetLanguage = target;
          });
          
          // Auto-translate if there's text
          if (_inputController.text.isNotEmpty) {
            _translateText();
          }
        },
      ),
    );
  }

  Widget _buildTranslationInterface() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Column(
        children: [
          // Input section
          Expanded(
            flex: 1,
            child: _buildInputSection(),
          ),
          
          // Divider with translate button
          _buildTranslateButton(),
          
          // Output section
          Expanded(
            flex: 1,
            child: _buildOutputSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nhập văn bản',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_inputController.text.isNotEmpty) ...[
                  IconButton(
                    onPressed: () => _speakText(_inputController.text, _sourceLanguage),
                    icon: const Icon(Icons.volume_up, size: 20),
                    tooltip: 'Nghe phát âm',
                  ),
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste, size: 20),
                    tooltip: 'Dán từ clipboard',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Nhập văn bản cần dịch...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textHintColor),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: _onTextChanged,
              ),
            ),
            if (_inputController.text.isNotEmpty)
              Text(
                '${_inputController.text.length} ký tự',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHintColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bản dịch',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_hasTranslation) ...[
                  if (_confidence > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_confidence * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getConfidenceColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _speakText(_translatedText, _targetLanguage),
                    icon: const Icon(Icons.volume_up, size: 20),
                    tooltip: 'Nghe phát âm',
                  ),
                  IconButton(
                    onPressed: _copyTranslation,
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Sao chép',
                  ),
                  IconButton(
                    onPressed: _shareTranslation,
                    icon: const Icon(Icons.share, size: 20),
                    tooltip: 'Chia sẻ',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _hasTranslation
                  ? FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _translatedText,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Bản dịch sẽ hiển thị ở đây',
                        style: TextStyle(
                          color: AppColors.textHintColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPhrases() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cụm từ thông dụng:',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPhrases.length,
              itemBuilder: (context, index) {
                final phrase = _quickPhrases[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(phrase),
                    onPressed: () => _useQuickPhrase(phrase),
                    backgroundColor: AppColors.cardColor,
                    side: BorderSide(color: AppColors.borderColor),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _hasTranslation ? _saveToVocabulary : null,
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Lưu từ vựng'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _hasTranslation ? _saveToHistory : null,
              icon: const Icon(Icons.save),
              label: const Text('Lưu lịch sử'),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'swap_languages':
        _swapLanguages();
        break;
      case 'detect_language':
        _detectLanguage();
        break;
      case 'copy_translation':
        _copyTranslation();
        break;
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _translatedText = '';
      _hasTranslation = false;
      _confidence = 0.0;
    });
    _fadeController.reverse();
    _hapticService.buttonPress();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      // Swap text if both exist
      if (_hasTranslation) {
        final tempText = _inputController.text;
        _inputController.text = _translatedText;
        _translatedText = tempText;
      }
    });

    _hapticService.buttonPress();
    if (_inputController.text.isNotEmpty) {
      _translateText();
    }
  }

  Future<void> _detectLanguage() async {
    if (_inputController.text.isEmpty) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Vui lòng nhập văn bản trước', isError: true);
      }
      return;
    }

    try {
      final detectedLanguage = await _translationService.detectLanguage(_inputController.text);
      if (detectedLanguage != 'unknown') {
        setState(() {
          _sourceLanguage = detectedLanguage;
        });

        if (mounted) {
          AppUtils.showSnackBar(
            context,
            'Đã nhận dạng ngôn ngữ: ${_getLanguageName(detectedLanguage)}'
          );
        }

        _translateText();
      } else {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Không thể nhận dạng ngôn ngữ', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi nhận dạng ngôn ngữ: $e', isError: true);
      }
    }
  }

  void _onTextChanged(String text) {
    // Auto-translate after user stops typing for 1 second
    AppUtils.debounce(() {
      if (text.isNotEmpty && text != _inputController.text) {
        _translateText();
      }
    }, const Duration(seconds: 1));
  }

  Future<void> _translateText() async {
    if (_inputController.text.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _translationService.translateText(
        text: _inputController.text,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      if (result.isSuccessful) {
        setState(() {
          _translatedText = result.translatedText;
          _confidence = result.confidence;
          _hasTranslation = true;
        });

        _fadeController.forward();
        _slideController.forward();
        _hapticService.translationComplete();
      } else {
        if (mounted) {
          AppUtils.showSnackBar(
            context,
            'Lỗi dịch thuật',
            isError: true
          );
        }
        _hapticService.error();
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi dịch thuật: $e', isError: true);
      }
      _hapticService.error();
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  Future<void> _speakText(String text, String languageCode) async {
    try {
      await _ttsService.speak(text, languageCode: languageCode);
      _hapticService.buttonPress();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi phát âm: $e', isError: true);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _inputController.text = clipboardData!.text!;
        _hapticService.buttonPress();
        _translateText();
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi dán từ clipboard: $e', isError: true);
      }
    }
  }

  void _copyTranslation() {
    if (_hasTranslation) {
      Clipboard.setData(ClipboardData(text: _translatedText));
      AppUtils.showSnackBar(context, 'Đã sao chép bản dịch');
      _hapticService.buttonPress();
    }
  }

  void _shareTranslation() {
    if (_hasTranslation) {
      final shareText = 'Gốc: ${_inputController.text}\nDịch: $_translatedText\n\n- Từ SnapTranslate';
      // Would use share_plus package in real implementation
      Clipboard.setData(ClipboardData(text: shareText));
      AppUtils.showSnackBar(context, 'Đã sao chép để chia sẻ');
      _hapticService.buttonPress();
    }
  }

  void _useQuickPhrase(String phrase) {
    _inputController.text = phrase;
    _hapticService.buttonPress();
    _translateText();
  }

  Future<void> _saveToVocabulary() async {
    // This would open a dialog to save to vocabulary
    AppUtils.showSnackBar(context, 'Tính năng lưu từ vựng sẽ được thêm sau');
  }

  Future<void> _saveToHistory() async {
    if (!_hasTranslation) return;

    try {
      final translation = TranslationModel(
        id: AppUtils.generateUniqueId(),
        originalText: _inputController.text,
        translatedText: _translatedText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        createdAt: DateTime.now(),
        confidence: _confidence,
        type: TranslationType.text,
      );

      await _databaseService.insertTranslation(translation);
      if (mounted) {
        AppUtils.showSnackBar(context, 'Đã lưu vào lịch sử');
      }
      _hapticService.success();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi lưu lịch sử: $e', isError: true);
      }
      _hapticService.error();
    }
  }

  Color _getConfidenceColor() {
    if (_confidence >= 0.8) return AppColors.successColor;
    if (_confidence >= 0.6) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  Widget _buildTranslateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _inputController.text.isEmpty || _isTranslating
                ? null
                : _translateText,
            icon: _isTranslating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate),
            label: Text(_isTranslating ? 'Đang dịch...' : 'Dịch'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _getLanguageName(String languageCode) {
    // This would use the language model to get display name
    return languageCode.toUpperCase();
  }
}
