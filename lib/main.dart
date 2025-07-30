import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'services/database_service.dart';
import 'services/ocr_service.dart';
import 'services/translation_service.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await _initializeServices();

  runApp(const SnapTranslateApp());
}

Future<void> _initializeServices() async {
  try {
    await DatabaseService().initialize();
    await OCRService().initialize();
    await TranslationService().initialize();
    await TTSService().initialize();
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

class SnapTranslateApp extends StatelessWidget {
  const SnapTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      home: const HomeScreen(),
    );
  }
}


