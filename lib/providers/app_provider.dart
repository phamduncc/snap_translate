import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../data/models/settings_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class AppProvider extends ChangeNotifier {
  static final AppProvider _instance = AppProvider._internal();
  factory AppProvider() => _instance;
  AppProvider._internal();

  final SettingsService _settingsService = SettingsService();
  SettingsModel _settings = SettingsModel.defaultSettings();
  bool _isInitialized = false;

  // Getters
  SettingsModel get settings => _settings;
  bool get isInitialized => _isInitialized;
  
  // Theme getters
  ThemeMode get themeMode {
    switch (_settings.appTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    switch (_settings.appTheme) {
      case 'dark':
        return true;
      case 'light':
        return false;
      case 'system':
      default:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  // Locale getters
  Locale get locale {
    return Locale(_settings.appLanguage);
  }

  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _settingsService.initialize();
      _settings = _settingsService.settings;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AppProvider: $e');
    }
  }

  // Update theme
  Future<void> updateTheme(String theme) async {
    try {
      await _settingsService.updateSetting('appTheme', theme);
      _settings = _settingsService.settings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  // Update language
  Future<void> updateLanguage(String languageCode) async {
    try {
      await _settingsService.updateSetting('appLanguage', languageCode);
      _settings = _settingsService.settings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating language: $e');
    }
  }

  // Update any setting
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      await _settingsService.updateSetting(key, value);
      _settings = _settingsService.settings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating setting $key: $e');
    }
  }

  // Get light theme
  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textOnPrimaryColor,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      scaffoldBackgroundColor: AppColors.backgroundColor,
    );
  }

  // Get dark theme
  ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[800],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      scaffoldBackgroundColor: Colors.grey[900],
    );
  }
}
