import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/language_model.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  late final GoogleTranslator _googleTranslator;
  late final Dio _dio;
  late final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _isOfflineMode = false;

  // Initialize the translation service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _googleTranslator = GoogleTranslator();
      _dio = Dio();
      _prefs = await SharedPreferences.getInstance();
      _isOfflineMode = _prefs.getBool(AppConstants.isOfflineModeEnabled) ?? false;
      _isInitialized = true;
    } catch (e) {
      throw TranslationException('Failed to initialize translation service: $e');
    }
  }

  // Translate text
  Future<TranslationResult> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool forceOnline = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      throw TranslationException('Text cannot be empty');
    }

    if (sourceLanguage == targetLanguage && sourceLanguage != 'auto') {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        confidence: 1.0,
        isOffline: false,
      );
    }

    try {
      // Try offline translation first if enabled and not forced online
      if (_isOfflineMode && !forceOnline && _isOfflineSupported(sourceLanguage, targetLanguage)) {
        return await _translateOffline(text, sourceLanguage, targetLanguage);
      }

      // Fallback to online translation
      return await _translateOnline(text, sourceLanguage, targetLanguage);
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw TranslationException('Translation failed: $e');
    }
  }

  // Online translation using Google Translate
  Future<TranslationResult> _translateOnline(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      final translation = await _googleTranslator.translate(
        text,
        from: sourceLanguage == 'auto' ? 'auto' : sourceLanguage,
        to: targetLanguage,
      );

      return TranslationResult(
        originalText: text,
        translatedText: translation.text,
        sourceLanguage: translation.sourceLanguage.code,
        targetLanguage: targetLanguage,
        confidence: 0.9, // Google Translate typically has high confidence
        isOffline: false,
      );
    } catch (e) {
      throw TranslationException('Online translation failed: $e');
    }
  }

  // Offline translation (simplified implementation)
  Future<TranslationResult> _translateOffline(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      // This is a simplified offline translation
      // In a real app, you would use offline models like TensorFlow Lite
      final offlineTranslations = await _getOfflineTranslations();
      
      final key = '${sourceLanguage}_${targetLanguage}_${text.toLowerCase()}';
      final translatedText = offlineTranslations[key] ?? text;

      return TranslationResult(
        originalText: text,
        translatedText: translatedText,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        confidence: translatedText != text ? 0.8 : 0.1,
        isOffline: true,
      );
    } catch (e) {
      throw TranslationException('Offline translation failed: $e');
    }
  }

  // Get offline translations from local storage
  Future<Map<String, String>> _getOfflineTranslations() async {
    final translationsJson = _prefs.getString('offline_translations') ?? '{}';
    final translations = Map<String, String>.from(jsonDecode(translationsJson));
    
    // Add some basic translations for demo
    translations.addAll({
      'en_vi_hello': 'xin chào',
      'en_vi_goodbye': 'tạm biệt',
      'en_vi_thank you': 'cảm ơn',
      'en_vi_please': 'xin lỗi',
      'en_vi_yes': 'có',
      'en_vi_no': 'không',
      'vi_en_xin chào': 'hello',
      'vi_en_tạm biệt': 'goodbye',
      'vi_en_cảm ơn': 'thank you',
      'vi_en_xin lỗi': 'please',
      'vi_en_có': 'yes',
      'vi_en_không': 'no',
    });
    
    return translations;
  }

  // Save offline translation
  Future<void> saveOfflineTranslation({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final translations = await _getOfflineTranslations();
    final key = '${sourceLanguage}_${targetLanguage}_${originalText.toLowerCase()}';
    translations[key] = translatedText;
    
    await _prefs.setString('offline_translations', jsonEncode(translations));
  }

  // Detect language
  Future<String> detectLanguage(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final translation = await _googleTranslator.translate(text, from: 'auto', to: 'en');
      return translation.sourceLanguage.code;
    } catch (e) {
      throw TranslationException('Language detection failed: $e');
    }
  }

  // Batch translate multiple texts
  Future<List<TranslationResult>> batchTranslate({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final results = <TranslationResult>[];
    
    for (final text in texts) {
      try {
        final result = await translateText(
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );
        results.add(result);
      } catch (e) {
        results.add(TranslationResult(
          originalText: text,
          translatedText: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          confidence: 0.0,
          isOffline: false,
          error: e.toString(),
        ));
      }
    }
    
    return results;
  }

  // Check if offline translation is supported for language pair
  bool _isOfflineSupported(String sourceLanguage, String targetLanguage) {
    final supportedPairs = [
      'en_vi', 'vi_en',
      'en_zh', 'zh_en',
      'en_ja', 'ja_en',
    ];
    
    return supportedPairs.contains('${sourceLanguage}_$targetLanguage');
  }

  // Get available languages
  List<LanguageModel> getAvailableLanguages() {
    return LanguageModel.defaultLanguages;
  }

  // Set offline mode
  Future<void> setOfflineMode(bool enabled) async {
    _isOfflineMode = enabled;
    await _prefs.setBool(AppConstants.isOfflineModeEnabled, enabled);
  }

  // Get offline mode status
  bool get isOfflineMode => _isOfflineMode;

  // Check if service is available
  bool get isAvailable => _isInitialized;

  // Dispose resources
  void dispose() {
    _dio.close();
    _isInitialized = false;
  }
}

// Translation Result model
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final double confidence;
  final bool isOffline;
  final String? error;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.confidence,
    required this.isOffline,
    this.error,
  });

  bool get isSuccessful => error == null && translatedText.isNotEmpty;
  bool get isHighConfidence => confidence > 0.7;
}

// Translation Exception
class TranslationException implements Exception {
  final String message;
  const TranslationException(this.message);
  
  @override
  String toString() => 'TranslationException: $message';
}
