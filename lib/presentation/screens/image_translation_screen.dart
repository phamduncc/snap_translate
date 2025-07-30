import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/ocr_service.dart';
import '../../services/translation_service.dart';
import '../../services/database_service.dart';
import '../../services/tts_service.dart';
import '../../data/models/translation_model.dart';
import '../widgets/language_selector.dart';

class ImageTranslationScreen extends StatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;

  const ImageTranslationScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<ImageTranslationScreen> createState() => _ImageTranslationScreenState();
}

class _ImageTranslationScreenState extends State<ImageTranslationScreen> {
  File? _selectedImage;
  String _originalText = '';
  String _translatedText = '';
  String _sourceLanguage = '';
  String _targetLanguage = '';
  bool _isProcessing = false;
  bool _isTranslating = false;
  double _ocrConfidence = 0.0;

  final OCRService _ocrService = OCRService();
  final TranslationService _translationService = TranslationService();
  final DatabaseService _databaseService = DatabaseService();
  final TTSService _ttsService = TTSService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _sourceLanguage = widget.sourceLanguage;
    _targetLanguage = widget.targetLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch từ ảnh'),
        actions: [
          if (_translatedText.isNotEmpty)
            IconButton(
              onPressed: _speakTranslatedText,
              icon: const Icon(Icons.volume_up),
              tooltip: 'Đọc bản dịch',
            ),
          if (_translatedText.isNotEmpty)
            IconButton(
              onPressed: _shareTranslation,
              icon: const Icon(Icons.share),
              tooltip: 'Chia sẻ',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: _selectedImage == null
                ? _buildImageSelector()
                : _buildTranslationResult(),
          ),
          _buildActionButtons(),
        ],
      ),
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
          if (_originalText.isNotEmpty) {
            _translateText();
          }
        },
      ),
    );
  }

  Widget _buildImageSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 100,
            color: AppColors.textSecondaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Chọn ảnh để dịch văn bản',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chụp ảnh mới hoặc chọn từ thư viện',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Original text section
          if (_originalText.isNotEmpty) ...[
            _buildTextSection(
              title: 'Văn bản gốc',
              text: _originalText,
              confidence: _ocrConfidence,
              onSpeak: () => _speakText(_originalText, _sourceLanguage),
              onCopy: () => _copyText(_originalText),
            ),
            const SizedBox(height: 16),
          ],

          // Translated text section
          if (_translatedText.isNotEmpty) ...[
            _buildTextSection(
              title: 'Bản dịch',
              text: _translatedText,
              onSpeak: () => _speakText(_translatedText, _targetLanguage),
              onCopy: () => _copyText(_translatedText),
              isTranslation: true,
            ),
          ],

          // Processing indicators
          if (_isProcessing) ...[
            const SizedBox(height: 16),
            _buildProcessingIndicator('Đang nhận dạng văn bản...'),
          ],

          if (_isTranslating) ...[
            const SizedBox(height: 16),
            _buildProcessingIndicator('Đang dịch...'),
          ],
        ],
      ),
    );
  }

  Widget _buildTextSection({
    required String title,
    required String text,
    double? confidence,
    required VoidCallback onSpeak,
    required VoidCallback onCopy,
    bool isTranslation = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTranslation ? AppColors.primaryColor : AppColors.textPrimaryColor,
                  ),
                ),
                if (confidence != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: confidence > 0.7 ? AppColors.successColor : AppColors.warningColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(confidence * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up),
                  iconSize: 20,
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImageFromGallery,
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
              onPressed: _isProcessing ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh'),
            ),
          ),
        ],
      ),
    );
  }

  // Image selection methods
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _originalText = '';
          _translatedText = '';
          _ocrConfidence = 0.0;
        });

        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi chọn ảnh: $e', isError: true);
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _originalText = '';
          _translatedText = '';
          _ocrConfidence = 0.0;
        });

        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi chụp ảnh: $e', isError: true);
      }
    }
  }

  // OCR and Translation methods
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Perform OCR
      final ocrResult = await _ocrService.extractTextFromImage(_selectedImage!);

      setState(() {
        _originalText = ocrResult.fullText;
        _ocrConfidence = ocrResult.confidence;
        _isProcessing = false;
      });

      if (_originalText.isNotEmpty) {
        await _translateText();

        if (mounted) {
          AppUtils.showSnackBar(context, 'Đã nhận dạng và dịch văn bản thành công!');
        }
      } else {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Không tìm thấy văn bản trong ảnh', isError: true);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi nhận dạng văn bản: $e', isError: true);
      }
    }
  }

  Future<void> _translateText() async {
    if (_originalText.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _translationService.translateText(
        text: _originalText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      setState(() {
        _translatedText = result.translatedText;
        _isTranslating = false;
      });

      // Save to database
      await _saveTranslation();
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi dịch thuật: $e', isError: true);
      }
    }
  }

  Future<void> _saveTranslation() async {
    if (_originalText.isEmpty || _translatedText.isEmpty) return;

    try {
      final translation = TranslationModel(
        id: AppUtils.generateUniqueId(),
        originalText: _originalText,
        translatedText: _translatedText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
        createdAt: DateTime.now(),
        confidence: _ocrConfidence,
        imagePath: _selectedImage?.path,
        type: TranslationType.image,
      );

      await _databaseService.insertTranslation(translation);
    } catch (e) {
      // Ignore database errors for now
      debugPrint('Error saving translation: $e');
    }
  }

  // Text-to-Speech methods
  Future<void> _speakText(String text, String languageCode) async {
    try {
      await _ttsService.speak(text, languageCode: languageCode);
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi đọc văn bản: $e', isError: true);
      }
    }
  }

  Future<void> _speakTranslatedText() async {
    if (_translatedText.isNotEmpty) {
      await _speakText(_translatedText, _targetLanguage);
    }
  }

  // Utility methods
  void _copyText(String text) {
    AppUtils.copyToClipboard(text);
    if (mounted) {
      AppUtils.showSnackBar(context, 'Đã sao chép vào clipboard');
    }
  }

  void _shareTranslation() {
    if (_originalText.isNotEmpty && _translatedText.isNotEmpty) {
      final shareText = 'Gốc: $_originalText\n\nDịch: $_translatedText';
      AppUtils.shareText(shareText);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
