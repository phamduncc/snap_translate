import '../data/models/vocabulary_model.dart';
import '../core/utils/app_utils.dart';
import 'database_service.dart';

class VocabularyService {
  static final VocabularyService _instance = VocabularyService._internal();
  factory VocabularyService() => _instance;
  VocabularyService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Initialize service
  Future<void> initialize() async {
    try {
      await _databaseService.initialize();
      print('DEBUG: VocabularyService initialized successfully');
    } catch (e) {
      print('ERROR: Failed to initialize VocabularyService: $e');
    }
  }

  // Add word to vocabulary
  Future<bool> addToVocabulary({
    required String word,
    required String translation,
    required String sourceLanguage,
    required String targetLanguage,
    String? pronunciation,
    String? definition,
    String? example,
    String? exampleTranslation,
    List<String> tags = const [],
  }) async {
    try {
      print('DEBUG: Adding to vocabulary - word: $word, translation: $translation');
      print('DEBUG: Languages - source: $sourceLanguage, target: $targetLanguage');

      // Validate language codes - don't allow 'auto' for vocabulary
      if (sourceLanguage == 'auto' || targetLanguage == 'auto') {
        print('ERROR: Cannot save vocabulary with "auto" language code');
        return false;
      }

      // Check if word already exists
      final existing = await _databaseService.getVocabulary(
        searchQuery: word,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        limit: 1,
      );

      print('DEBUG: Existing vocabulary check - found: ${existing.length} items');

      if (existing.isNotEmpty) {
        print('DEBUG: Word already exists in vocabulary');
        return false;
      }

      final vocabulary = VocabularyModel(
        id: AppUtils.generateUniqueId(),
        word: word.trim(),
        translation: translation.trim(),
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        pronunciation: pronunciation?.trim(),
        definition: definition?.trim(),
        example: example?.trim(),
        exampleTranslation: exampleTranslation?.trim(),
        createdAt: DateTime.now(),
        tags: tags,
      );

      print('DEBUG: Created vocabulary model - id: ${vocabulary.id}');

      await _databaseService.insertVocabulary(vocabulary);
      print('DEBUG: Successfully inserted vocabulary into database');
      return true;
    } catch (e) {
      print('ERROR: Failed to add vocabulary: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Check if word exists in vocabulary
  Future<bool> isWordInVocabulary({
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final existing = await _databaseService.getVocabulary(
        searchQuery: word,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        limit: 1,
      );
      return existing.isNotEmpty;
    } catch (e) {
      print('Error checking vocabulary: $e');
      return false;
    }
  }

  // Get vocabulary list
  Future<List<VocabularyModel>> getVocabulary({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? sourceLanguage,
    String? targetLanguage,
    bool? isMastered,
    bool? isDueForReview,
  }) async {
    try {
      return await _databaseService.getVocabulary(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        isMastered: isMastered,
        isDueForReview: isDueForReview,
      );
    } catch (e) {
      print('Error getting vocabulary: $e');
      return [];
    }
  }

  // Remove word from vocabulary
  Future<bool> removeFromVocabulary(String id) async {
    try {
      await _databaseService.deleteVocabulary(id);
      return true;
    } catch (e) {
      print('Error removing from vocabulary: $e');
      return false;
    }
  }

  // Update vocabulary item
  Future<bool> updateVocabulary(VocabularyModel vocabulary) async {
    try {
      await _databaseService.updateVocabulary(vocabulary);
      return true;
    } catch (e) {
      print('Error updating vocabulary: $e');
      return false;
    }
  }

  // Get vocabulary statistics
  Future<Map<String, int>> getVocabularyStats() async {
    try {
      final allVocab = await _databaseService.getVocabulary(limit: 10000);
      final mastered = allVocab.where((v) => v.isMastered).length;
      final dueForReview = allVocab.where((v) => v.isDueForReview).length;
      
      return {
        'total': allVocab.length,
        'mastered': mastered,
        'learning': allVocab.length - mastered,
        'dueForReview': dueForReview,
      };
    } catch (e) {
      print('Error getting vocabulary stats: $e');
      return {
        'total': 0,
        'mastered': 0,
        'learning': 0,
        'dueForReview': 0,
      };
    }
  }

  // Extract words from text for vocabulary suggestions
  List<String> extractWords(String text) {
    // Simple word extraction - can be enhanced with NLP
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet()
        .toList();
    
    return words;
  }

  // Get word suggestions from translation
  List<Map<String, String>> getWordSuggestions({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final originalWords = extractWords(originalText);
    final translatedWords = extractWords(translatedText);
    
    final suggestions = <Map<String, String>>[];
    
    // Simple word pairing - in real app, would use alignment algorithms
    for (int i = 0; i < originalWords.length && i < translatedWords.length; i++) {
      suggestions.add({
        'word': originalWords[i],
        'translation': translatedWords[i],
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      });
    }
    
    return suggestions;
  }
}
