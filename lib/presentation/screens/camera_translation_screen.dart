import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/camera_service.dart';
import '../../services/ocr_service.dart';
import '../../services/translation_service.dart';
import '../../services/tts_service.dart';
import '../widgets/language_selector.dart';

// Translation overlay model
class TranslationOverlay {
  final String originalText;
  final String translatedText;
  final Offset position;
  final DateTime createdAt;

  TranslationOverlay({
    required this.originalText,
    required this.translatedText,
    required this.position,
    required this.createdAt,
  });
}

class CameraTranslationScreen extends StatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;

  const CameraTranslationScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<CameraTranslationScreen> createState() => _CameraTranslationScreenState();
}

class _CameraTranslationScreenState extends State<CameraTranslationScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final OCRService _ocrService = OCRService();
  final TranslationService _translationService = TranslationService();
  final TTSService _ttsService = TTSService();

  String _sourceLanguage = '';
  String _targetLanguage = '';
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isTranslating = false;
  bool _isPaused = false;

  // Translation results
  final List<TranslationOverlay> _translationOverlays = [];
  Timer? _processingTimer;

  // Camera controls
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _sourceLanguage = widget.sourceLanguage;
    _targetLanguage = widget.targetLanguage;
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _processingTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.resumePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized ? _buildCameraView() : _buildLoadingView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryColor),
          SizedBox(height: 16),
          Text(
            'Đang khởi tạo camera...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: _cameraService.getCameraPreview(),
        ),

        // Translation overlays
        ..._translationOverlays.map((overlay) => _buildTranslationOverlay(overlay)),

        // Top controls
        _buildTopControls(),

        // Bottom controls
        _buildBottomControls(),

        // Language selector
        _buildLanguageSelectorOverlay(),

        // Processing indicator
        if (_isProcessing || _isTranslating) _buildProcessingIndicator(),
      ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          const Spacer(),

          // Flash toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Camera switch
          if (_cameraService.availableCamerasCount > 1)
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: _switchCamera,
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pause/Resume button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _toggleProcessing,
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Capture button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(35),
            ),
            child: IconButton(
              onPressed: _captureAndTranslate,
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Clear overlays button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _clearOverlays,
              icon: const Icon(
                Icons.clear_all,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectorOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        padding: const EdgeInsets.all(8),
        child: LanguageSelector(
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
          onLanguagesChanged: (source, target) {
            setState(() {
              _sourceLanguage = source;
              _targetLanguage = target;
            });
            _clearOverlays();
          },
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 200,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isProcessing ? 'Đang nhận dạng...' : 'Đang dịch...',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationOverlay(TranslationOverlay overlay) {
    return Positioned(
      left: overlay.position.dx,
      top: overlay.position.dy,
      child: GestureDetector(
        onTap: () => _speakTranslation(overlay.translatedText),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.translationOverlayColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                overlay.originalText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                overlay.translatedText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Camera initialization and control methods
  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      setState(() {
        _isInitialized = true;
      });

      // Start real-time processing
      _startRealTimeProcessing();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi khởi tạo camera: $e', isError: true);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraService.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi bật/tắt đèn flash: $e', isError: true);
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraService.switchCamera();
      setState(() {
        // Reset flash state when switching camera
        _isFlashOn = false;
      });
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi chuyển camera: $e', isError: true);
      }
    }
  }

  void _toggleProcessing() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _processingTimer?.cancel();
    } else {
      _startRealTimeProcessing();
    }
  }

  void _clearOverlays() {
    setState(() {
      _translationOverlays.clear();
    });
  }

  // Real-time processing methods
  void _startRealTimeProcessing() {
    if (_isPaused) return;

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isPaused && _isInitialized && !_isProcessing) {
        _processCurrentFrame();
      }
    });
  }

  Future<void> _processCurrentFrame() async {
    if (_isProcessing || _isPaused) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take a picture for processing
      final imageFile = await _cameraService.takePicture();

      // Perform OCR
      final ocrResult = await _ocrService.extractTextFromImage(imageFile);

      if (ocrResult.hasText && ocrResult.isHighConfidence) {
        await _translateAndAddOverlay(ocrResult.fullText);
      }

      // Clean up temporary image
      await imageFile.delete();
    } catch (e) {
      // Ignore errors in real-time processing to avoid spam
      debugPrint('Real-time processing error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _captureAndTranslate() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take a high-quality picture
      final imageFile = await _cameraService.takePicture();

      // Perform OCR
      final ocrResult = await _ocrService.extractTextFromImage(imageFile);

      if (ocrResult.hasText) {
        await _translateAndAddOverlay(ocrResult.fullText);

        if (mounted) {
          AppUtils.showSnackBar(context, 'Đã nhận dạng và dịch văn bản!');
        }
      } else {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Không tìm thấy văn bản trong ảnh', isError: true);
        }
      }

      // Clean up temporary image
      await imageFile.delete();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi xử lý ảnh: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Translation methods
  Future<void> _translateAndAddOverlay(String originalText) async {
    if (originalText.trim().isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _translationService.translateText(
        text: originalText,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      if (result.isSuccessful) {
        // Add translation overlay at a random position
        final overlay = TranslationOverlay(
          originalText: originalText,
          translatedText: result.translatedText,
          position: _generateRandomPosition(),
          createdAt: DateTime.now(),
        );

        setState(() {
          _translationOverlays.add(overlay);

          // Keep only the last 5 overlays to avoid clutter
          if (_translationOverlays.length > 5) {
            _translationOverlays.removeAt(0);
          }
        });
      }
    } catch (e) {
      // Ignore translation errors in real-time mode
      debugPrint('Translation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  Offset _generateRandomPosition() {
    final screenSize = MediaQuery.of(context).size;
    final random = DateTime.now().millisecondsSinceEpoch;

    // Generate position in the middle area of the screen
    final x = (random % (screenSize.width - 220).toInt()).toDouble() + 10;
    final y = (random % (screenSize.height - 400).toInt()).toDouble() + 200;

    return Offset(x, y);
  }

  // Text-to-Speech methods
  Future<void> _speakTranslation(String text) async {
    try {
      await _ttsService.speak(text, languageCode: _targetLanguage);
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi đọc văn bản: $e', isError: true);
      }
    }
  }
}
