class AppConstants {
  // App Info
  static const String appName = 'SnapTranslate';
  static const String appVersion = '1.0.0';
  
  // API Keys (should be moved to environment variables in production)
  static const String googleTranslateApiKey = 'YOUR_GOOGLE_TRANSLATE_API_KEY';
  
  // Database
  static const String databaseName = 'snap_translate.db';
  static const int databaseVersion = 2;
  
  // Table Names
  static const String translationHistoryTable = 'translation_history';
  static const String vocabularyTable = 'vocabulary';
  static const String languagesTable = 'languages';
  
  // Shared Preferences Keys
  static const String selectedSourceLanguage = 'selected_source_language';
  static const String selectedTargetLanguage = 'selected_target_language';
  static const String isOfflineModeEnabled = 'is_offline_mode_enabled';
  static const String ttsVoiceSpeed = 'tts_voice_speed';
  static const String isFirstLaunch = 'is_first_launch';
  
  // Default Languages
  static const String defaultSourceLanguage = 'en';
  static const String defaultTargetLanguage = 'vi';
  
  // Camera Settings
  static const double cameraAspectRatio = 16 / 9;
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 768;
  
  // OCR Settings
  static const double ocrConfidenceThreshold = 0.7;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  
  // Text Sizes
  static const double titleTextSize = 24.0;
  static const double subtitleTextSize = 18.0;
  static const double bodyTextSize = 16.0;
  static const double captionTextSize = 14.0;
  
  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'auto': 'Tự động phát hiện',
    'en': 'English',
    'vi': 'Tiếng Việt',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'it': 'Italiano',
    'ru': 'Русский',
    'th': 'ไทย',
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };
  
  // Error Messages
  static const String networkError = 'Lỗi kết nối mạng';
  static const String ocrError = 'Không thể nhận dạng văn bản';
  static const String translationError = 'Lỗi dịch thuật';
  static const String cameraError = 'Lỗi camera';
  static const String permissionError = 'Không có quyền truy cập';
  static const String unknownError = 'Lỗi không xác định';
}
