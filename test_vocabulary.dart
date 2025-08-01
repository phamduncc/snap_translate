import 'package:flutter/material.dart';
import 'lib/services/vocabulary_service.dart';
import 'lib/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing Vocabulary Service...');
  
  try {
    // Initialize services
    final databaseService = DatabaseService();
    await databaseService.initialize();
    print('✅ DatabaseService initialized');
    
    final vocabularyService = VocabularyService();
    await vocabularyService.initialize();
    print('✅ VocabularyService initialized');
    
    // Test adding vocabulary
    print('\n--- Testing Add Vocabulary ---');
    final success = await vocabularyService.addToVocabulary(
      word: 'hello',
      translation: 'xin chào',
      sourceLanguage: 'en',
      targetLanguage: 'vi',
      definition: 'A greeting word',
      example: 'Hello, how are you?',
      exampleTranslation: 'Xin chào, bạn khỏe không?',
    );
    
    print('Add vocabulary result: $success');
    
    // Test checking if word exists
    print('\n--- Testing Word Existence Check ---');
    final exists = await vocabularyService.isWordInVocabulary(
      word: 'hello',
      sourceLanguage: 'en',
      targetLanguage: 'vi',
    );
    
    print('Word exists in vocabulary: $exists');
    
    // Test getting vocabulary list
    print('\n--- Testing Get Vocabulary ---');
    final vocabulary = await vocabularyService.getVocabulary(limit: 10);
    print('Vocabulary count: ${vocabulary.length}');
    
    for (final vocab in vocabulary) {
      print('- ${vocab.word} → ${vocab.translation} (${vocab.sourceLanguage} → ${vocab.targetLanguage})');
    }
    
    // Test vocabulary statistics
    print('\n--- Testing Vocabulary Statistics ---');
    final stats = await vocabularyService.getVocabularyStats();
    print('Statistics: $stats');
    
    print('\n✅ All tests completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  }
}
