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
  final bool isVisible;

  TranslationOverlay({
    required this.originalText,
    required this.translatedText,
    required this.position,
    required this.createdAt,
    this.isVisible = true,
  });

  TranslationOverlay copyWith({
    String? originalText,
    String? translatedText,
    Offset? position,
    DateTime? createdAt,
    bool? isVisible,
  }) {
    return TranslationOverlay(
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      isVisible: isVisible ?? this.isVisible,
    );
  }
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
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 0.8 + (0.2 * opacity),
              child: GestureDetector(
                onTap: () => _speakTranslation(overlay.translatedText),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryDarkColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppColors.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    minHeight: 44,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          overlay.translatedText,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

  // Auto-clear old overlays
  void _autoCleanupOverlays() {
    final now = DateTime.now();
    setState(() {
      _translationOverlays.removeWhere((overlay) {
        final age = now.difference(overlay.createdAt);
        return age.inSeconds > 15; // Remove overlays older than 15 seconds
      });
    });
  }

  // Real-time processing methods
  void _startRealTimeProcessing() {
    if (_isPaused) return;

    _processingTimer?.cancel();
    // Increase interval to 3 seconds to reduce processing frequency
    _processingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isPaused && _isInitialized && !_isProcessing && !_isTranslating) {
        _processCurrentFrame();
        _autoCleanupOverlays(); // Clean up old overlays
      }
    });
  }

  Future<void> _processCurrentFrame() async {
    if (_isProcessing || _isPaused || _isTranslating) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take a picture for processing
      final imageFile = await _cameraService.takePicture();

      // Perform OCR
      final ocrResult = await _ocrService.extractTextFromImage(imageFile);

      // Only process if text is found, has high confidence, and is substantial
      if (ocrResult.hasText &&
          ocrResult.isHighConfidence &&
          ocrResult.fullText.trim().length > 3) {

        // Check if this text is significantly different from existing overlays
        final normalizedNewText = ocrResult.fullText.trim().toLowerCase();
        bool isDifferentText = true;

        for (final overlay in _translationOverlays) {
          final normalizedExistingText = overlay.originalText.trim().toLowerCase();

          // Calculate similarity (simple approach)
          if (_calculateTextSimilarity(normalizedNewText, normalizedExistingText) > 0.8) {
            isDifferentText = false;
            break;
          }
        }

        // Only translate if it's significantly different text
        if (isDifferentText) {
          await _translateAndAddOverlay(ocrResult.fullText);
        }
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

    // Check if this text is already being translated or already exists
    final normalizedText = originalText.trim().toLowerCase();
    final existingOverlay = _translationOverlays.firstWhere(
      (overlay) => overlay.originalText.trim().toLowerCase() == normalizedText,
      orElse: () => TranslationOverlay(
        originalText: '',
        translatedText: '',
        position: const Offset(0, 0),
        createdAt: DateTime.now(),
      ),
    );

    // If overlay already exists and is recent (within 10 seconds), don't create new one
    if (existingOverlay.originalText.isNotEmpty) {
      final timeDifference = DateTime.now().difference(existingOverlay.createdAt);
      if (timeDifference.inSeconds < 10) {
        return; // Skip duplicate translation
      }
    }

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
        // Remove any existing overlay with the same original text
        _translationOverlays.removeWhere(
          (overlay) => overlay.originalText.trim().toLowerCase() == normalizedText,
        );

        // Add new translation overlay
        final overlay = TranslationOverlay(
          originalText: originalText,
          translatedText: result.translatedText,
          position: _generateRandomPosition(),
          createdAt: DateTime.now(),
        );

        setState(() {
          _translationOverlays.add(overlay);

          // Keep only the last 3 overlays to avoid clutter
          if (_translationOverlays.length > 3) {
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

    // Define safe area for overlays
    const overlayWidth = 200.0;
    const overlayHeight = 80.0;
    const margin = 20.0;

    final safeWidth = screenSize.width - overlayWidth - margin * 2;
    final safeHeight = screenSize.height - overlayHeight - 300; // Account for top/bottom controls

    // Try to find a position that doesn't overlap with existing overlays
    for (int attempt = 0; attempt < 10; attempt++) {
      final random = DateTime.now().millisecondsSinceEpoch + attempt;
      final x = (random % safeWidth.toInt()).toDouble() + margin;
      final y = (random % safeHeight.toInt()).toDouble() + 250; // Start below language selector

      final newPosition = Offset(x, y);

      // Check if this position overlaps with existing overlays
      bool hasOverlap = false;
      for (final overlay in _translationOverlays) {
        final distance = (newPosition - overlay.position).distance;
        if (distance < 120) { // Minimum distance between overlays
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return newPosition;
      }
    }

    // Fallback to a basic position if no good position found
    return Offset(margin, 250 + (_translationOverlays.length * 90).toDouble());
  }

  // Calculate text similarity (simple Jaccard similarity)
  double _calculateTextSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Split into words
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();

    // Calculate Jaccard similarity
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
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
