class SettingsModel {
  final String defaultSourceLanguage;
  final String defaultTargetLanguage;
  final bool isOfflineMode;
  final bool autoPlayTranslation;
  final bool saveToHistory;
  final bool enableVibration;
  final bool enableSoundEffects;
  final String ttsVoiceSpeed;
  final String ttsVoicePitch;
  final String appTheme;
  final String appLanguage;
  final bool enableNotifications;
  final bool autoDetectLanguage;
  final bool showConfidenceScore;
  final int maxHistoryItems;
  final bool enableAnalytics;
  final String cacheSize;
  final DateTime lastUpdated;

  const SettingsModel({
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
    required this.isOfflineMode,
    required this.autoPlayTranslation,
    required this.saveToHistory,
    required this.enableVibration,
    required this.enableSoundEffects,
    required this.ttsVoiceSpeed,
    required this.ttsVoicePitch,
    required this.appTheme,
    required this.appLanguage,
    required this.enableNotifications,
    required this.autoDetectLanguage,
    required this.showConfidenceScore,
    required this.maxHistoryItems,
    required this.enableAnalytics,
    required this.cacheSize,
    required this.lastUpdated,
  });

  // Default settings
  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      defaultSourceLanguage: 'en',
      defaultTargetLanguage: 'vi',
      isOfflineMode: false,
      autoPlayTranslation: true,
      saveToHistory: true,
      enableVibration: true,
      enableSoundEffects: true,
      ttsVoiceSpeed: 'normal',
      ttsVoicePitch: 'normal',
      appTheme: 'system',
      appLanguage: 'vi',
      enableNotifications: true,
      autoDetectLanguage: false,
      showConfidenceScore: true,
      maxHistoryItems: 1000,
      enableAnalytics: false,
      cacheSize: '100MB',
      lastUpdated: DateTime.now(),
    );
  }

  // Copy with method
  SettingsModel copyWith({
    String? defaultSourceLanguage,
    String? defaultTargetLanguage,
    bool? isOfflineMode,
    bool? autoPlayTranslation,
    bool? saveToHistory,
    bool? enableVibration,
    bool? enableSoundEffects,
    String? ttsVoiceSpeed,
    String? ttsVoicePitch,
    String? appTheme,
    String? appLanguage,
    bool? enableNotifications,
    bool? autoDetectLanguage,
    bool? showConfidenceScore,
    int? maxHistoryItems,
    bool? enableAnalytics,
    String? cacheSize,
    DateTime? lastUpdated,
  }) {
    return SettingsModel(
      defaultSourceLanguage: defaultSourceLanguage ?? this.defaultSourceLanguage,
      defaultTargetLanguage: defaultTargetLanguage ?? this.defaultTargetLanguage,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      autoPlayTranslation: autoPlayTranslation ?? this.autoPlayTranslation,
      saveToHistory: saveToHistory ?? this.saveToHistory,
      enableVibration: enableVibration ?? this.enableVibration,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      ttsVoiceSpeed: ttsVoiceSpeed ?? this.ttsVoiceSpeed,
      ttsVoicePitch: ttsVoicePitch ?? this.ttsVoicePitch,
      appTheme: appTheme ?? this.appTheme,
      appLanguage: appLanguage ?? this.appLanguage,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      showConfidenceScore: showConfidenceScore ?? this.showConfidenceScore,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      cacheSize: cacheSize ?? this.cacheSize,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'defaultSourceLanguage': defaultSourceLanguage,
      'defaultTargetLanguage': defaultTargetLanguage,
      'isOfflineMode': isOfflineMode,
      'autoPlayTranslation': autoPlayTranslation,
      'saveToHistory': saveToHistory,
      'enableVibration': enableVibration,
      'enableSoundEffects': enableSoundEffects,
      'ttsVoiceSpeed': ttsVoiceSpeed,
      'ttsVoicePitch': ttsVoicePitch,
      'appTheme': appTheme,
      'appLanguage': appLanguage,
      'enableNotifications': enableNotifications,
      'autoDetectLanguage': autoDetectLanguage,
      'showConfidenceScore': showConfidenceScore,
      'maxHistoryItems': maxHistoryItems,
      'enableAnalytics': enableAnalytics,
      'cacheSize': cacheSize,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // From JSON
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      defaultSourceLanguage: json['defaultSourceLanguage'] ?? 'en',
      defaultTargetLanguage: json['defaultTargetLanguage'] ?? 'vi',
      isOfflineMode: json['isOfflineMode'] ?? false,
      autoPlayTranslation: json['autoPlayTranslation'] ?? true,
      saveToHistory: json['saveToHistory'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      enableSoundEffects: json['enableSoundEffects'] ?? true,
      ttsVoiceSpeed: json['ttsVoiceSpeed'] ?? 'normal',
      ttsVoicePitch: json['ttsVoicePitch'] ?? 'normal',
      appTheme: json['appTheme'] ?? 'system',
      appLanguage: json['appLanguage'] ?? 'vi',
      enableNotifications: json['enableNotifications'] ?? true,
      autoDetectLanguage: json['autoDetectLanguage'] ?? false,
      showConfidenceScore: json['showConfidenceScore'] ?? true,
      maxHistoryItems: json['maxHistoryItems'] ?? 1000,
      enableAnalytics: json['enableAnalytics'] ?? false,
      cacheSize: json['cacheSize'] ?? '100MB',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsModel &&
        other.defaultSourceLanguage == defaultSourceLanguage &&
        other.defaultTargetLanguage == defaultTargetLanguage &&
        other.isOfflineMode == isOfflineMode &&
        other.autoPlayTranslation == autoPlayTranslation &&
        other.saveToHistory == saveToHistory &&
        other.enableVibration == enableVibration &&
        other.enableSoundEffects == enableSoundEffects &&
        other.ttsVoiceSpeed == ttsVoiceSpeed &&
        other.ttsVoicePitch == ttsVoicePitch &&
        other.appTheme == appTheme &&
        other.appLanguage == appLanguage &&
        other.enableNotifications == enableNotifications &&
        other.autoDetectLanguage == autoDetectLanguage &&
        other.showConfidenceScore == showConfidenceScore &&
        other.maxHistoryItems == maxHistoryItems &&
        other.enableAnalytics == enableAnalytics &&
        other.cacheSize == cacheSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      defaultSourceLanguage,
      defaultTargetLanguage,
      isOfflineMode,
      autoPlayTranslation,
      saveToHistory,
      enableVibration,
      enableSoundEffects,
      ttsVoiceSpeed,
      ttsVoicePitch,
      appTheme,
      appLanguage,
      enableNotifications,
      autoDetectLanguage,
      showConfidenceScore,
      maxHistoryItems,
      enableAnalytics,
      cacheSize,
    );
  }

  @override
  String toString() {
    return 'SettingsModel(defaultSourceLanguage: $defaultSourceLanguage, defaultTargetLanguage: $defaultTargetLanguage, isOfflineMode: $isOfflineMode)';
  }
}

// Settings categories for UI organization
enum SettingsCategory {
  general,
  language,
  audio,
  privacy,
  advanced,
}

// Settings option model
class SettingsOption {
  final String key;
  final String title;
  final String subtitle;
  final int iconCodePoint;
  final SettingsCategory category;
  final SettingsOptionType type;
  final dynamic value;
  final List<dynamic>? options;
  final Function(dynamic)? onChanged;

  const SettingsOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.iconCodePoint,
    required this.category,
    required this.type,
    required this.value,
    this.options,
    this.onChanged,
  });
}

enum SettingsOptionType {
  toggle,
  dropdown,
  slider,
  navigation,
  action,
}
