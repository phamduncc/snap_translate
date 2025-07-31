import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/settings_model.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _settingsKey = 'app_settings';
  SharedPreferences? _prefs;
  SettingsModel? _currentSettings;

  // Initialize settings service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadSettings();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs?.getString(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = SettingsModel.fromJson(settingsMap);
      } else {
        _currentSettings = SettingsModel.defaultSettings();
        await _saveSettings();
      }
    } catch (e) {
      // If loading fails, use default settings
      _currentSettings = SettingsModel.defaultSettings();
      await _saveSettings();
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    if (_currentSettings != null && _prefs != null) {
      final settingsJson = jsonEncode(_currentSettings!.toJson());
      await _prefs!.setString(_settingsKey, settingsJson);
    }
  }

  // Get current settings
  SettingsModel get settings {
    return _currentSettings ?? SettingsModel.defaultSettings();
  }

  // Update settings
  Future<void> updateSettings(SettingsModel newSettings) async {
    _currentSettings = newSettings.copyWith(lastUpdated: DateTime.now());
    await _saveSettings();
  }

  // Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    if (_currentSettings == null) return;

    SettingsModel updatedSettings;
    
    switch (key) {
      case 'defaultSourceLanguage':
        updatedSettings = _currentSettings!.copyWith(defaultSourceLanguage: value);
        break;
      case 'defaultTargetLanguage':
        updatedSettings = _currentSettings!.copyWith(defaultTargetLanguage: value);
        break;
      case 'isOfflineMode':
        updatedSettings = _currentSettings!.copyWith(isOfflineMode: value);
        break;
      case 'autoPlayTranslation':
        updatedSettings = _currentSettings!.copyWith(autoPlayTranslation: value);
        break;
      case 'saveToHistory':
        updatedSettings = _currentSettings!.copyWith(saveToHistory: value);
        break;
      case 'enableVibration':
        updatedSettings = _currentSettings!.copyWith(enableVibration: value);
        break;
      case 'enableSoundEffects':
        updatedSettings = _currentSettings!.copyWith(enableSoundEffects: value);
        break;
      case 'ttsVoiceSpeed':
        updatedSettings = _currentSettings!.copyWith(ttsVoiceSpeed: value);
        break;
      case 'ttsVoicePitch':
        updatedSettings = _currentSettings!.copyWith(ttsVoicePitch: value);
        break;
      case 'appTheme':
        updatedSettings = _currentSettings!.copyWith(appTheme: value);
        break;
      case 'appLanguage':
        updatedSettings = _currentSettings!.copyWith(appLanguage: value);
        break;
      case 'enableNotifications':
        updatedSettings = _currentSettings!.copyWith(enableNotifications: value);
        break;
      case 'autoDetectLanguage':
        updatedSettings = _currentSettings!.copyWith(autoDetectLanguage: value);
        break;
      case 'showConfidenceScore':
        updatedSettings = _currentSettings!.copyWith(showConfidenceScore: value);
        break;
      case 'maxHistoryItems':
        updatedSettings = _currentSettings!.copyWith(maxHistoryItems: value);
        break;
      case 'enableAnalytics':
        updatedSettings = _currentSettings!.copyWith(enableAnalytics: value);
        break;
      case 'cacheSize':
        updatedSettings = _currentSettings!.copyWith(cacheSize: value);
        break;
      default:
        return; // Unknown setting key
    }

    await updateSettings(updatedSettings);
  }

  // Reset to default settings
  Future<void> resetToDefaults() async {
    _currentSettings = SettingsModel.defaultSettings();
    await _saveSettings();
  }

  // Clear all settings
  Future<void> clearSettings() async {
    await _prefs?.remove(_settingsKey);
    _currentSettings = null;
  }

  // Get cache size in bytes
  Future<int> getCacheSizeInBytes() async {
    // This would calculate actual cache size
    // For now, return a mock value
    return 104857600; // 100MB
  }

  // Clear cache
  Future<void> clearCache() async {
    // This would clear actual cache
    // For now, just update the setting
    await updateSetting('cacheSize', '0MB');
  }

  // Export settings
  Map<String, dynamic> exportSettings() {
    return settings.toJson();
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final importedSettings = SettingsModel.fromJson(settingsData);
      await updateSettings(importedSettings);
    } catch (e) {
      throw Exception('Invalid settings data: $e');
    }
  }

  // Get setting value by key
  dynamic getSettingValue(String key) {
    final currentSettings = settings;
    
    switch (key) {
      case 'defaultSourceLanguage':
        return currentSettings.defaultSourceLanguage;
      case 'defaultTargetLanguage':
        return currentSettings.defaultTargetLanguage;
      case 'isOfflineMode':
        return currentSettings.isOfflineMode;
      case 'autoPlayTranslation':
        return currentSettings.autoPlayTranslation;
      case 'saveToHistory':
        return currentSettings.saveToHistory;
      case 'enableVibration':
        return currentSettings.enableVibration;
      case 'enableSoundEffects':
        return currentSettings.enableSoundEffects;
      case 'ttsVoiceSpeed':
        return currentSettings.ttsVoiceSpeed;
      case 'ttsVoicePitch':
        return currentSettings.ttsVoicePitch;
      case 'appTheme':
        return currentSettings.appTheme;
      case 'appLanguage':
        return currentSettings.appLanguage;
      case 'enableNotifications':
        return currentSettings.enableNotifications;
      case 'autoDetectLanguage':
        return currentSettings.autoDetectLanguage;
      case 'showConfidenceScore':
        return currentSettings.showConfidenceScore;
      case 'maxHistoryItems':
        return currentSettings.maxHistoryItems;
      case 'enableAnalytics':
        return currentSettings.enableAnalytics;
      case 'cacheSize':
        return currentSettings.cacheSize;
      default:
        return null;
    }
  }

  // Check if setting exists
  bool hasSetting(String key) {
    return getSettingValue(key) != null;
  }

  // Get settings by category
  Map<String, dynamic> getSettingsByCategory(SettingsCategory category) {
    final allSettings = settings.toJson();
    final categorySettings = <String, dynamic>{};

    switch (category) {
      case SettingsCategory.general:
        categorySettings['appTheme'] = allSettings['appTheme'];
        categorySettings['appLanguage'] = allSettings['appLanguage'];
        categorySettings['enableNotifications'] = allSettings['enableNotifications'];
        break;
      case SettingsCategory.language:
        categorySettings['defaultSourceLanguage'] = allSettings['defaultSourceLanguage'];
        categorySettings['defaultTargetLanguage'] = allSettings['defaultTargetLanguage'];
        categorySettings['autoDetectLanguage'] = allSettings['autoDetectLanguage'];
        break;
      case SettingsCategory.audio:
        categorySettings['autoPlayTranslation'] = allSettings['autoPlayTranslation'];
        categorySettings['ttsVoiceSpeed'] = allSettings['ttsVoiceSpeed'];
        categorySettings['ttsVoicePitch'] = allSettings['ttsVoicePitch'];
        categorySettings['enableSoundEffects'] = allSettings['enableSoundEffects'];
        break;
      case SettingsCategory.privacy:
        categorySettings['saveToHistory'] = allSettings['saveToHistory'];
        categorySettings['enableAnalytics'] = allSettings['enableAnalytics'];
        break;
      case SettingsCategory.advanced:
        categorySettings['isOfflineMode'] = allSettings['isOfflineMode'];
        categorySettings['showConfidenceScore'] = allSettings['showConfidenceScore'];
        categorySettings['maxHistoryItems'] = allSettings['maxHistoryItems'];
        categorySettings['cacheSize'] = allSettings['cacheSize'];
        break;
    }

    return categorySettings;
  }
}
