import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/home_screen.dart';
import 'core/constants/app_constants.dart';
import 'services/database_service.dart';
import 'services/ocr_service.dart';
import 'services/translation_service.dart';
import 'services/tts_service.dart';
import 'providers/app_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await _initializeServices();

  // Initialize app provider
  final appProvider = AppProvider();
  await appProvider.initialize();

  runApp(SnapTranslateApp(appProvider: appProvider));
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
  final AppProvider appProvider;

  const SnapTranslateApp({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appProvider,
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: provider.lightTheme,
            darkTheme: provider.darkTheme,
            locale: provider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}


