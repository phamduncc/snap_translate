import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/speech_service.dart';
import '../../services/translation_service.dart';
import '../../services/tts_service.dart';
import '../../services/database_service.dart';
import '../../data/models/translation_model.dart';
import '../widgets/language_selector.dart';

// Conversation message model
class ConversationMessage {
  final String originalText;
  final String translatedText;
  final String speaker;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final double confidence;

  ConversationMessage({
    required this.originalText,
    required this.translatedText,
    required this.speaker,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    required this.confidence,
  });
}

class VoiceTranslationScreen extends StatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;

  const VoiceTranslationScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<VoiceTranslationScreen> createState() => _VoiceTranslationScreenState();
}

class _VoiceTranslationScreenState extends State<VoiceTranslationScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  final TranslationService _translationService = TranslationService();
  final TTSService _ttsService = TTSService();
  final DatabaseService _databaseService = DatabaseService();

  String _sourceLanguage = '';
  String _targetLanguage = '';
  
  // Conversation state
  final List<ConversationMessage> _conversation = [];
  bool _isListening = false;
  bool _isTranslating = false;
  String _currentSpeaker = 'A'; // A or B
  
  // Current recognition
  String _currentText = '';
  double _currentConfidence = 0.0;
  double _soundLevel = 0.0;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  
  Timer? _soundLevelTimer;

  @override
  void initState() {
    super.initState();
    _sourceLanguage = widget.sourceLanguage;
    _targetLanguage = widget.targetLanguage;
    _initializeAnimations();
    _initializeServices();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _soundLevelTimer?.cancel();
    _speechService.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    

  }

  Future<void> _initializeServices() async {
    try {
      await _speechService.initialize();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi khởi tạo dịch vụ: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(
            child: _buildConversationView(),
          ),
          _buildCurrentRecognition(),
          _buildVoiceControls(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Dịch hội thoại'),
      backgroundColor: Colors.black87,
      actions: [
        IconButton(
          onPressed: _clearConversation,
          icon: const Icon(Icons.clear_all),
          tooltip: 'Xóa hội thoại',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'switch_speaker',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.primaryColor),
                  SizedBox(width: 8),
                  Text('Đổi người nói'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'save_conversation',
              child: Row(
                children: [
                  Icon(Icons.save, color: AppColors.successColor),
                  SizedBox(width: 8),
                  Text('Lưu hội thoại'),
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
        },
      ),
    );
  }

  Widget _buildConversationView() {
    if (_conversation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              size: 80,
              color: AppColors.textSecondaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhấn micro để bắt đầu hội thoại',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nói vào micro, ứng dụng sẽ tự động dịch',
              style: TextStyle(
                color: AppColors.textHintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _conversation.length,
      itemBuilder: (context, index) {
        final message = _conversation[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    final isCurrentUser = message.speaker == _currentSpeaker;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              backgroundColor: AppColors.secondaryColor,
              child: Text(message.speaker, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppColors.primaryColor : AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.originalText,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrentUser ? Colors.white : AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.translatedText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrentUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppColors.textHintColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _speakMessage(message.originalText, message.sourceLanguage),
                        child: Icon(
                          Icons.volume_up,
                          size: 16,
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: Text(message.speaker, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentRecognition() {
    if (!_isListening && _currentText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_off,
                color: _isListening ? AppColors.primaryColor : AppColors.textSecondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isListening ? 'Đang nghe...' : 'Đã dừng nghe',
                style: TextStyle(
                  color: _isListening ? AppColors.primaryColor : AppColors.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_currentConfidence > 0)
                Text(
                  '${(_currentConfidence * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHintColor,
                  ),
                ),
            ],
          ),
          if (_currentText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentText,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Sound level indicator
          if (_isListening) ...[
            Container(
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(
                value: _soundLevel,
                backgroundColor: AppColors.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _soundLevel > 0.5 ? AppColors.successColor : AppColors.primaryColor,
                ),
              ),
            ),
          ],

          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speaker A button
              _buildSpeakerButton('A'),

              // Main mic button
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.errorColor : AppColors.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? AppColors.errorColor : AppColors.primaryColor)
                                  .withValues(alpha: 0.3),
                              blurRadius: _isListening ? 20 : 10,
                              spreadRadius: _isListening ? 5 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Speaker B button
              _buildSpeakerButton('B'),
            ],
          ),

          const SizedBox(height: 16),

          // Status text
          Text(
            _isListening
                ? 'Đang nghe người nói $_currentSpeaker...'
                : _isTranslating
                    ? 'Đang dịch...'
                    : 'Nhấn micro để bắt đầu',
            style: const TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerButton(String speaker) {
    final isSelected = _currentSpeaker == speaker;

    return GestureDetector(
      onTap: () => _selectSpeaker(speaker),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            speaker,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Action methods
  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hội thoại'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ hội thoại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _conversation.clear();
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'switch_speaker':
        _switchSpeaker();
        break;
      case 'save_conversation':
        _saveConversation();
        break;
    }
  }

  void _switchSpeaker() {
    setState(() {
      _currentSpeaker = _currentSpeaker == 'A' ? 'B' : 'A';
    });
  }

  void _selectSpeaker(String speaker) {
    setState(() {
      _currentSpeaker = speaker;
    });
  }

  void _saveConversation() {
    AppUtils.showSnackBar(context, 'Tính năng lưu hội thoại sẽ được thêm sau');
  }

  // Voice control methods
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      setState(() {
        _currentText = '';
        _currentConfidence = 0.0;
      });

      await _speechService.startListening(
        languageCode: _sourceLanguage,
        onResult: (text, confidence) {
          setState(() {
            _currentText = text;
            _currentConfidence = confidence;
          });
        },
        onError: (error) {
          if (mounted) {
            AppUtils.showSnackBar(context, 'Lỗi nhận dạng giọng nói: $error', isError: true);
          }
        },
      );

      setState(() {
        _isListening = true;
      });

      _pulseController.repeat(reverse: true);
      _startSoundLevelMonitoring();
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi bắt đầu nghe: $e', isError: true);
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechService.stopListening();

      setState(() {
        _isListening = false;
      });

      _pulseController.stop();
      _soundLevelTimer?.cancel();

      // Process the recognized text
      if (_currentText.isNotEmpty) {
        await _processRecognizedText(_currentText);
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi dừng nghe: $e', isError: true);
      }
    }
  }

  void _startSoundLevelMonitoring() {
    _soundLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isListening) {
        setState(() {
          _soundLevel = _speechService.soundLevel.clamp(0.0, 1.0);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _processRecognizedText(String text) async {
    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await _translationService.translateText(
        text: text,
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );

      if (result.isSuccessful) {
        final message = ConversationMessage(
          originalText: text,
          translatedText: result.translatedText,
          speaker: _currentSpeaker,
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
          timestamp: DateTime.now(),
          confidence: _currentConfidence,
        );

        setState(() {
          _conversation.add(message);
          _currentText = '';
          _currentConfidence = 0.0;
        });

        // Auto-speak the translation
        await _speakMessage(result.translatedText, _targetLanguage);

        // Save to database
        await _saveToDatabase(message);
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi dịch thuật: $e', isError: true);
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  Future<void> _speakMessage(String text, String languageCode) async {
    try {
      await _ttsService.speak(text, languageCode: languageCode);
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi đọc văn bản: $e', isError: true);
      }
    }
  }

  Future<void> _saveToDatabase(ConversationMessage message) async {
    try {
      final translation = TranslationModel(
        id: AppUtils.generateUniqueId(),
        originalText: message.originalText,
        translatedText: message.translatedText,
        sourceLanguage: message.sourceLanguage,
        targetLanguage: message.targetLanguage,
        createdAt: message.timestamp,
        confidence: message.confidence,
        type: TranslationType.voice,
      );

      await _databaseService.insertTranslation(translation);
    } catch (e) {
      // Ignore database errors
      debugPrint('Error saving to database: $e');
    }
  }
}
