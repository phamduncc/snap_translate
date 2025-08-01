import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../data/models/translation_model.dart';
import '../data/models/vocabulary_model.dart';
import '../data/models/language_model.dart';
import '../data/models/quiz_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  bool _isInitialized = false;

  // Get database instance
  Future<Database> get database async {
    if (!_isInitialized || _database == null) {
      await initialize();
    }
    return _database!;
  }

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

    // Quiz Sessions Table
    await db.execute('''
      CREATE TABLE quiz_sessions (
        id TEXT PRIMARY KEY,
        questions TEXT NOT NULL,
        results TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        mode TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        total_time_spent INTEGER NOT NULL,
        accuracy REAL NOT NULL
      )
    ''');

    // Quiz Stats Table
    await db.execute('''
      CREATE TABLE quiz_stats (
        id INTEGER PRIMARY KEY,
        total_quizzes INTEGER NOT NULL DEFAULT 0,
        total_questions INTEGER NOT NULL DEFAULT 0,
        correct_answers INTEGER NOT NULL DEFAULT 0,
        average_accuracy REAL NOT NULL DEFAULT 0.0,
        total_time_spent INTEGER NOT NULL DEFAULT 0,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        language_pair_stats TEXT NOT NULL DEFAULT '{}',
        difficulty_stats TEXT NOT NULL DEFAULT '{}',
        last_quiz_date TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_translation_created_at ON ${AppConstants.translationHistoryTable}(created_at DESC)');
    await db.execute('CREATE INDEX idx_translation_languages ON ${AppConstants.translationHistoryTable}(source_language, target_language)');
    await db.execute('CREATE INDEX idx_vocabulary_created_at ON ${AppConstants.vocabularyTable}(created_at DESC)');
    await db.execute('CREATE INDEX idx_vocabulary_languages ON ${AppConstants.vocabularyTable}(source_language, target_language)');
    await db.execute('CREATE INDEX idx_vocabulary_review ON ${AppConstants.vocabularyTable}(last_reviewed, is_mastered)');
    await db.execute('CREATE INDEX idx_quiz_sessions_start_time ON quiz_sessions(start_time DESC)');

    // Insert default languages
    await _insertDefaultLanguages(db);
  }

  // Upgrade database
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add quiz tables for version 2
      await _createQuizTables(db);
    }
  }

  // Create quiz tables
  Future<void> _createQuizTables(Database db) async {
    // Quiz Sessions Table
    await db.execute('''
      CREATE TABLE quiz_sessions (
        id TEXT PRIMARY KEY,
        questions TEXT NOT NULL,
        results TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        mode TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        total_time_spent INTEGER NOT NULL,
        accuracy REAL NOT NULL
      )
    ''');

    // Quiz Stats Table
    await db.execute('''
      CREATE TABLE quiz_stats (
        id INTEGER PRIMARY KEY,
        total_quizzes INTEGER NOT NULL DEFAULT 0,
        total_questions INTEGER NOT NULL DEFAULT 0,
        correct_answers INTEGER NOT NULL DEFAULT 0,
        average_accuracy REAL NOT NULL DEFAULT 0.0,
        total_time_spent INTEGER NOT NULL DEFAULT 0,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        language_pair_stats TEXT NOT NULL DEFAULT '{}',
        difficulty_stats TEXT NOT NULL DEFAULT '{}',
        last_quiz_date TEXT
      )
    ''');

    // Create index for quiz sessions
    await db.execute('CREATE INDEX idx_quiz_sessions_start_time ON quiz_sessions(start_time DESC)');
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

  // Quiz Methods
  Future<void> insertQuizSession(QuizSession session) async {
    final db = await database;
    await db.insert('quiz_sessions', {
      'id': session.id,
      'questions': jsonEncode(session.questions.map((q) => q.toJson()).toList()),
      'results': jsonEncode(session.results.map((r) => r.toJson()).toList()),
      'start_time': session.startTime.toIso8601String(),
      'end_time': session.endTime?.toIso8601String(),
      'mode': session.mode.toString().split('.').last,
      'difficulty': session.difficulty.toString().split('.').last,
      'total_questions': session.totalQuestions,
      'correct_answers': session.correctAnswers,
      'total_time_spent': session.totalTimeSpent,
      'accuracy': session.accuracy,
    });

    // Update quiz stats
    await _updateQuizStats(session);
  }

  Future<List<QuizSession>> getQuizSessions({int limit = 10}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'quiz_sessions',
        orderBy: 'start_time DESC',
        limit: limit,
      );

      return maps.map((map) {
        final questions = (jsonDecode(map['questions']) as List)
            .map((q) => QuizQuestion.fromJson(q))
            .toList();
        final results = (jsonDecode(map['results']) as List)
            .map((r) => QuizResult.fromJson(r))
            .toList();

        return QuizSession(
          id: map['id'],
          questions: questions,
          results: results,
          startTime: DateTime.parse(map['start_time']),
          endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
          mode: QuizMode.values.firstWhere(
            (e) => e.toString() == 'QuizMode.${map['mode']}',
            orElse: () => QuizMode.mixed,
          ),
          difficulty: QuizDifficulty.values.firstWhere(
            (e) => e.toString() == 'QuizDifficulty.${map['difficulty']}',
            orElse: () => QuizDifficulty.medium,
          ),
          totalQuestions: map['total_questions'],
          correctAnswers: map['correct_answers'],
          totalTimeSpent: map['total_time_spent'],
          accuracy: map['accuracy'],
        );
      }).toList();
    } catch (e) {
      // If table doesn't exist, return empty list
      return [];
    }
  }

  Future<QuizStats> getQuizStats() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('quiz_stats', limit: 1);

      if (maps.isEmpty) {
        // Initialize empty stats with id = 1
        final emptyStats = QuizStats.empty().toJson();
        emptyStats['id'] = 1;
        await db.insert('quiz_stats', emptyStats);
        return QuizStats.empty();
      }

      final map = maps.first;
      return QuizStats(
        totalQuizzes: map['total_quizzes'],
        totalQuestions: map['total_questions'],
        correctAnswers: map['correct_answers'],
        averageAccuracy: map['average_accuracy'],
        totalTimeSpent: map['total_time_spent'],
        currentStreak: map['current_streak'],
        longestStreak: map['longest_streak'],
        languagePairStats: Map<String, int>.from(jsonDecode(map['language_pair_stats'])),
        difficultyStats: Map<QuizDifficulty, int>.from(
          (jsonDecode(map['difficulty_stats']) as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              QuizDifficulty.values.firstWhere(
                (e) => e.toString() == 'QuizDifficulty.$key',
                orElse: () => QuizDifficulty.medium,
              ),
              value as int,
            ),
          ),
        ),
        lastQuizDate: map['last_quiz_date'] != null
            ? DateTime.parse(map['last_quiz_date'])
            : null,
      );
    } catch (e) {
      // If table doesn't exist, return empty stats
      return QuizStats.empty();
    }
  }

  Future<void> _updateQuizStats(QuizSession session) async {
    if (!session.isCompleted) return;

    final db = await database;
    final currentStats = await getQuizStats();

    // Calculate new streak
    final now = DateTime.now();
    final lastQuizDate = currentStats.lastQuizDate;
    int newCurrentStreak = currentStats.currentStreak;

    if (lastQuizDate == null) {
      newCurrentStreak = 1;
    } else {
      final daysDifference = now.difference(lastQuizDate).inDays;
      if (daysDifference == 1) {
        newCurrentStreak = currentStats.currentStreak + 1;
      } else if (daysDifference > 1) {
        newCurrentStreak = 1;
      } else {
        newCurrentStreak = currentStats.currentStreak;
      }
    }

    // Update language pair stats
    final languagePair = '${session.questions.first.sourceLanguage}-${session.questions.first.targetLanguage}';
    final updatedLanguagePairStats = Map<String, int>.from(currentStats.languagePairStats);
    updatedLanguagePairStats[languagePair] = (updatedLanguagePairStats[languagePair] ?? 0) + 1;

    // Update difficulty stats
    final updatedDifficultyStats = Map<QuizDifficulty, int>.from(currentStats.difficultyStats);
    updatedDifficultyStats[session.difficulty] = (updatedDifficultyStats[session.difficulty] ?? 0) + 1;

    // Calculate new averages
    final newTotalQuizzes = currentStats.totalQuizzes + 1;
    final newTotalQuestions = currentStats.totalQuestions + session.totalQuestions;
    final newCorrectAnswers = currentStats.correctAnswers + session.correctAnswers;
    final newAverageAccuracy = newCorrectAnswers / newTotalQuestions;
    final newTotalTimeSpent = currentStats.totalTimeSpent + session.totalTimeSpent;
    final newLongestStreak = math.max(currentStats.longestStreak, newCurrentStreak);

    final updatedStats = QuizStats(
      totalQuizzes: newTotalQuizzes,
      totalQuestions: newTotalQuestions,
      correctAnswers: newCorrectAnswers,
      averageAccuracy: newAverageAccuracy,
      totalTimeSpent: newTotalTimeSpent,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      languagePairStats: updatedLanguagePairStats,
      difficultyStats: updatedDifficultyStats,
      lastQuizDate: now,
    );

    await db.update('quiz_stats', updatedStats.toJson(), where: 'id = ?', whereArgs: [1]);
  }

  // Reset database (for development/testing)
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }

    // Delete database file
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    // Reinitialize
    await initialize();
  }

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
