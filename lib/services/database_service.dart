import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../data/models/translation_model.dart';
import '../data/models/vocabulary_model.dart';
import '../data/models/language_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  bool _isInitialized = false;

  // Initialize database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.databaseName);
      
      _database = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
      
      _isInitialized = true;
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    // Translation History Table
    await db.execute('''
      CREATE TABLE ${AppConstants.translationHistoryTable} (
        id TEXT PRIMARY KEY,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        confidence REAL DEFAULT 1.0,
        image_path TEXT,
        type INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Vocabulary Table
    await db.execute('''
      CREATE TABLE ${AppConstants.vocabularyTable} (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        translation TEXT NOT NULL,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        pronunciation TEXT,
        definition TEXT,
        example TEXT,
        example_translation TEXT,
        image_path TEXT,
        created_at INTEGER NOT NULL,
        last_reviewed INTEGER,
        review_count INTEGER DEFAULT 0,
        difficulty REAL DEFAULT 0.5,
        is_mastered INTEGER DEFAULT 0,
        tags TEXT DEFAULT ''
      )
    ''');

    // Languages Table
    await db.execute('''
      CREATE TABLE ${AppConstants.languagesTable} (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        native_name TEXT NOT NULL,
        is_supported INTEGER DEFAULT 1,
        is_offline_supported INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_translation_created_at ON ${AppConstants.translationHistoryTable}(created_at DESC)');
    await db.execute('CREATE INDEX idx_translation_languages ON ${AppConstants.translationHistoryTable}(source_language, target_language)');
    await db.execute('CREATE INDEX idx_vocabulary_created_at ON ${AppConstants.vocabularyTable}(created_at DESC)');
    await db.execute('CREATE INDEX idx_vocabulary_languages ON ${AppConstants.vocabularyTable}(source_language, target_language)');
    await db.execute('CREATE INDEX idx_vocabulary_review ON ${AppConstants.vocabularyTable}(last_reviewed, is_mastered)');

    // Insert default languages
    await _insertDefaultLanguages(db);
  }

  // Upgrade database
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Insert default languages
  Future<void> _insertDefaultLanguages(Database db) async {
    for (final language in LanguageModel.defaultLanguages) {
      await db.insert(
        AppConstants.languagesTable,
        language.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Translation History Operations
  Future<void> insertTranslation(TranslationModel translation) async {
    await _ensureInitialized();
    
    try {
      await _database!.insert(
        AppConstants.translationHistoryTable,
        translation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert translation: $e');
    }
  }

  Future<List<TranslationModel>> getTranslationHistory({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    await _ensureInitialized();
    
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause += 'original_text LIKE ? OR translated_text LIKE ?';
        whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
      }

      if (sourceLanguage != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'source_language = ?';
        whereArgs.add(sourceLanguage);
      }

      if (targetLanguage != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'target_language = ?';
        whereArgs.add(targetLanguage);
      }

      final List<Map<String, dynamic>> maps = await _database!.query(
        AppConstants.translationHistoryTable,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => TranslationModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get translation history: $e');
    }
  }

  Future<void> deleteTranslation(String id) async {
    await _ensureInitialized();
    
    try {
      await _database!.delete(
        AppConstants.translationHistoryTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete translation: $e');
    }
  }

  Future<void> updateTranslationFavorite(String id, bool isFavorite) async {
    await _ensureInitialized();

    try {
      await _database!.update(
        AppConstants.translationHistoryTable,
        {'is_favorite': isFavorite ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update translation favorite: $e');
    }
  }

  Future<List<TranslationModel>> getFavoriteTranslations() async {
    await _ensureInitialized();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        AppConstants.translationHistoryTable,
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => TranslationModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get favorite translations: $e');
    }
  }

  // Vocabulary Operations
  Future<void> insertVocabulary(VocabularyModel vocabulary) async {
    await _ensureInitialized();
    
    try {
      await _database!.insert(
        AppConstants.vocabularyTable,
        vocabulary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert vocabulary: $e');
    }
  }

  Future<List<VocabularyModel>> getVocabulary({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? sourceLanguage,
    String? targetLanguage,
    bool? isMastered,
    bool? isDueForReview,
  }) async {
    await _ensureInitialized();
    
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause += 'word LIKE ? OR translation LIKE ?';
        whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
      }

      if (sourceLanguage != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'source_language = ?';
        whereArgs.add(sourceLanguage);
      }

      if (targetLanguage != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'target_language = ?';
        whereArgs.add(targetLanguage);
      }

      if (isMastered != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'is_mastered = ?';
        whereArgs.add(isMastered ? 1 : 0);
      }

      final List<Map<String, dynamic>> maps = await _database!.query(
        AppConstants.vocabularyTable,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      List<VocabularyModel> vocabulary = maps.map((map) => VocabularyModel.fromMap(map)).toList();

      // Filter for due review if requested
      if (isDueForReview == true) {
        vocabulary = vocabulary.where((v) => v.isDueForReview).toList();
      }

      return vocabulary;
    } catch (e) {
      throw DatabaseException('Failed to get vocabulary: $e');
    }
  }

  Future<void> updateVocabulary(VocabularyModel vocabulary) async {
    await _ensureInitialized();
    
    try {
      await _database!.update(
        AppConstants.vocabularyTable,
        vocabulary.toMap(),
        where: 'id = ?',
        whereArgs: [vocabulary.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update vocabulary: $e');
    }
  }

  Future<void> deleteVocabulary(String id) async {
    await _ensureInitialized();
    
    try {
      await _database!.delete(
        AppConstants.vocabularyTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete vocabulary: $e');
    }
  }

  // Language Operations
  Future<List<LanguageModel>> getLanguages() async {
    await _ensureInitialized();
    
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        AppConstants.languagesTable,
        orderBy: 'name ASC',
      );

      return maps.map((map) => LanguageModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get languages: $e');
    }
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    await _ensureInitialized();
    
    try {
      final translationCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM ${AppConstants.translationHistoryTable}')
      ) ?? 0;

      final vocabularyCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM ${AppConstants.vocabularyTable}')
      ) ?? 0;

      final masteredCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM ${AppConstants.vocabularyTable} WHERE is_mastered = 1')
      ) ?? 0;

      return {
        'translations': translationCount,
        'vocabulary': vocabularyCount,
        'mastered': masteredCount,
      };
    } catch (e) {
      throw DatabaseException('Failed to get statistics: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    
    try {
      await _database!.delete(AppConstants.translationHistoryTable);
      await _database!.delete(AppConstants.vocabularyTable);
    } catch (e) {
      throw DatabaseException('Failed to clear data: $e');
    }
  }

  // Ensure database is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Check if database is available
  bool get isAvailable => _isInitialized && _database != null;

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }
}

// Database Exception
class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}
