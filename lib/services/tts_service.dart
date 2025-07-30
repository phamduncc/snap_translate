import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late final FlutterTts _flutterTts;
  late final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;

  // Initialize TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();
      _prefs = await SharedPreferences.getInstance();
      
      // Load saved settings
      _speechRate = _prefs.getDouble(AppConstants.ttsVoiceSpeed) ?? 0.5;
      
      // Configure TTS
      await _configureTTS();
      
      // Set up event handlers
      _setupEventHandlers();
      
      _isInitialized = true;
    } catch (e) {
      throw TTSException('Failed to initialize TTS service: $e');
    }
  }

  // Configure TTS settings
  Future<void> _configureTTS() async {
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    
    // Set default language
    await _flutterTts.setLanguage('en-US');
  }

  // Set up event handlers
  void _setupEventHandlers() {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
  }

  // Speak text
  Future<void> speak(String text, {String? languageCode}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      throw TTSException('Text cannot be empty');
    }

    try {
      // Stop current speech if speaking
      if (_isSpeaking) {
        await stop();
      }

      // Set language if provided
      if (languageCode != null) {
        await setLanguage(languageCode);
      }

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      throw TTSException('Failed to speak text: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      throw TTSException('Failed to stop speaking: $e');
    }
  }

  // Pause speaking
  Future<void> pause() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.pause();
    } catch (e) {
      throw TTSException('Failed to pause speaking: $e');
    }
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) return;

    try {
      final ttsLanguage = _mapLanguageCodeToTTS(languageCode);
      await _flutterTts.setLanguage(ttsLanguage);
    } catch (e) {
      throw TTSException('Failed to set language: $e');
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;

    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
      await _prefs.setDouble(AppConstants.ttsVoiceSpeed, _speechRate);
    } catch (e) {
      throw TTSException('Failed to set speech rate: $e');
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;

    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
    } catch (e) {
      throw TTSException('Failed to set volume: $e');
    }
  }

  // Set pitch
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) return;

    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      throw TTSException('Failed to set pitch: $e');
    }
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final languages = await _flutterTts.getLanguages;
      return languages?.cast<String>() ?? [];
    } catch (e) {
      return [];
    }
  }

  // Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final voices = await _flutterTts.getVoices;
      return voices?.cast<Map<String, String>>() ?? [];
    } catch (e) {
      return [];
    }
  }

  // Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      throw TTSException('Failed to set voice: $e');
    }
  }

  // Check if language is supported
  Future<bool> isLanguageSupported(String languageCode) async {
    final availableLanguages = await getAvailableLanguages();
    final ttsLanguage = _mapLanguageCodeToTTS(languageCode);
    return availableLanguages.any((lang) => lang.startsWith(ttsLanguage.split('-')[0]));
  }

  // Map language code to TTS format
  String _mapLanguageCodeToTTS(String languageCode) {
    const languageMap = {
      'en': 'en-US',
      'vi': 'vi-VN',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'es': 'es-ES',
      'it': 'it-IT',
      'ru': 'ru-RU',
      'th': 'th-TH',
      'ar': 'ar-SA',
      'hi': 'hi-IN',
    };

    return languageMap[languageCode] ?? 'en-US';
  }

  // Get current settings
  TTSSettings get currentSettings => TTSSettings(
    speechRate: _speechRate,
    volume: _volume,
    pitch: _pitch,
  );

  // Check if TTS is available
  bool get isAvailable => _isInitialized;

  // Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  // Get speech rate
  double get speechRate => _speechRate;

  // Get volume
  double get volume => _volume;

  // Get pitch
  double get pitch => _pitch;

  // Dispose TTS resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await stop();
      _isInitialized = false;
    }
  }
}

// TTS Settings model
class TTSSettings {
  final double speechRate;
  final double volume;
  final double pitch;

  const TTSSettings({
    required this.speechRate,
    required this.volume,
    required this.pitch,
  });

  TTSSettings copyWith({
    double? speechRate,
    double? volume,
    double? pitch,
  }) {
    return TTSSettings(
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speechRate': speechRate,
      'volume': volume,
      'pitch': pitch,
    };
  }

  factory TTSSettings.fromJson(Map<String, dynamic> json) {
    return TTSSettings(
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

// TTS Exception
class TTSException implements Exception {
  final String message;
  const TTSException(this.message);
  
  @override
  String toString() => 'TTSException: $message';
}
