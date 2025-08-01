import 'package:flutter/material.dart';
import 'lib/services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing Translation Service...');
  
  final translationService = TranslationService();
  await translationService.initialize();
  
  try {
    print('Testing translation from English to Vietnamese...');
    
    final result = await translationService.translateText(
      text: 'Hello, how are you?',
      sourceLanguage: 'en',
      targetLanguage: 'vi',
    );
    
    print('Original: ${result.originalText}');
    print('Translated: ${result.translatedText}');
    print('Source Language: ${result.sourceLanguage}');
    print('Target Language: ${result.targetLanguage}');
    print('Confidence: ${result.confidence}');
    print('Is Successful: ${result.isSuccessful}');
    print('Is Offline: ${result.isOffline}');
    
    if (result.error != null) {
      print('Error: ${result.error}');
    }
    
  } catch (e) {
    print('Translation failed: $e');
  }
  
  print('Test completed.');
}
