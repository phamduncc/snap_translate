import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';


class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  late final SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  // Initialize speech service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _speechToText = SpeechToText();
      
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        throw SpeechException('Microphone permission denied');
      }

      // Initialize speech to text
      final available = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );

      if (!available) {
        throw SpeechException('Speech recognition not available');
      }

      _isInitialized = true;
    } catch (e) {
      throw SpeechException('Failed to initialize speech service: $e');
    }
  }

  // Start listening
  Future<void> startListening({
    required String languageCode,
    required Function(String text, double confidence) onResult,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _confidence = result.confidence;
          onResult(_lastWords, _confidence);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _mapLanguageCodeToLocale(languageCode),
        onSoundLevelChange: null,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      _isListening = true;
    } catch (e) {
      if (onError != null) {
        onError('Failed to start listening: $e');
      }
      throw SpeechException('Failed to start listening: $e');
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      throw SpeechException('Failed to stop listening: $e');
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
    } catch (e) {
      throw SpeechException('Failed to cancel listening: $e');
    }
  }

  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _speechToText.locales();
    } catch (e) {
      return [];
    }
  }

  // Check if language is supported
  Future<bool> isLanguageSupported(String languageCode) async {
    final locales = await getAvailableLocales();
    final targetLocale = _mapLanguageCodeToLocale(languageCode);
    return locales.any((locale) => locale.localeId.startsWith(targetLocale.split('_')[0]));
  }

  // Map language code to locale
  String _mapLanguageCodeToLocale(String languageCode) {
    const localeMap = {
      'en': 'en_US',
      'vi': 'vi_VN',
      'zh': 'zh_CN',
      'ja': 'ja_JP',
      'ko': 'ko_KR',
      'fr': 'fr_FR',
      'de': 'de_DE',
      'es': 'es_ES',
      'it': 'it_IT',
      'ru': 'ru_RU',
      'th': 'th_TH',
      'ar': 'ar_SA',
      'hi': 'hi_IN',
    };

    return localeMap[languageCode] ?? 'en_US';
  }

  // Error handler
  void _onError(dynamic error) {
    _isListening = false;
  }

  // Status handler
  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  // Get current sound level
  double get soundLevel => _speechToText.lastSoundLevel;

  // Check if speech recognition is available
  bool get isAvailable => _isInitialized && _speechToText.isAvailable;

  // Check if currently listening
  bool get isListening => _isListening;

  // Get last recognized words
  String get lastWords => _lastWords;

  // Get last confidence
  double get confidence => _confidence;

  // Check if has permission
  Future<bool> get hasPermission async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_isListening) {
      await stopListening();
    }
    _isInitialized = false;
  }
}

// Speech Exception
class SpeechException implements Exception {
  final String message;
  const SpeechException(this.message);
  
  @override
  String toString() => 'SpeechException: $message';
}

// Speech Result model
class SpeechResult {
  final String text;
  final double confidence;
  final String languageCode;
  final DateTime timestamp;

  const SpeechResult({
    required this.text,
    required this.confidence,
    required this.languageCode,
    required this.timestamp,
  });

  bool get isHighConfidence => confidence > 0.7;
  bool get hasText => text.trim().isNotEmpty;
}
