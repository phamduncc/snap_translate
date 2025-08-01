import 'dart:math' as math;
import '../data/models/quiz_model.dart';
import '../data/models/vocabulary_model.dart';
import 'database_service.dart';
import 'vocabulary_service.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final VocabularyService _vocabularyService = VocabularyService();
  final math.Random _random = math.Random();

  // Generate quiz questions from vocabulary
  Future<List<QuizQuestion>> generateQuizQuestions({
    required QuizMode mode,
    required QuizDifficulty difficulty,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    try {
      // Get vocabulary items
      final vocabularyItems = await _vocabularyService.getVocabulary(limit: 1000);
      
      if (vocabularyItems.isEmpty) {
        throw Exception('No vocabulary items found. Please add some vocabulary first.');
      }

      // Filter by language if specified
      List<VocabularyModel> filteredItems = vocabularyItems;
      if (sourceLanguage != null && targetLanguage != null) {
        filteredItems = vocabularyItems.where((item) =>
          item.sourceLanguage == sourceLanguage && 
          item.targetLanguage == targetLanguage
        ).toList();
      }

      if (filteredItems.isEmpty) {
        throw Exception('No vocabulary items found for the selected language pair.');
      }

      // Determine number of questions based on difficulty
      final questionCount = _getQuestionCount(difficulty);
      final actualCount = math.min(questionCount, filteredItems.length);

      // Shuffle and take required number of items
      filteredItems.shuffle(_random);
      final selectedItems = filteredItems.take(actualCount).toList();

      // Generate questions based on mode
      final questions = <QuizQuestion>[];
      for (final item in selectedItems) {
        final questionTypes = _getQuestionTypes(mode);
        final questionType = questionTypes[_random.nextInt(questionTypes.length)];
        
        final question = await _generateQuestion(item, questionType, difficulty, filteredItems);
        if (question != null) {
          questions.add(question);
        }
      }

      return questions;
    } catch (e) {
      throw Exception('Failed to generate quiz questions: $e');
    }
  }

  // Generate a single question
  Future<QuizQuestion?> _generateQuestion(
    VocabularyModel vocabulary,
    QuizType type,
    QuizDifficulty difficulty,
    List<VocabularyModel> allVocabulary,
  ) async {
    try {
      switch (type) {
        case QuizType.translation:
          return _generateTranslationQuestion(vocabulary, difficulty);
        
        case QuizType.reverseTranslation:
          return _generateReverseTranslationQuestion(vocabulary, difficulty);
        
        case QuizType.multipleChoice:
          return _generateMultipleChoiceQuestion(vocabulary, difficulty, allVocabulary);
        
        case QuizType.fillInBlank:
          return _generateFillInBlankQuestion(vocabulary, difficulty);
        
        case QuizType.listening:
          return _generateListeningQuestion(vocabulary, difficulty, allVocabulary);
        
        case QuizType.pronunciation:
          return _generatePronunciationQuestion(vocabulary, difficulty);
      }
    } catch (e) {
      return null;
    }
  }

  QuizQuestion _generateTranslationQuestion(VocabularyModel vocabulary, QuizDifficulty difficulty) {
    return QuizQuestion(
      id: _generateQuestionId(),
      question: 'Translate: "${vocabulary.word}"',
      correctAnswer: vocabulary.translation,
      options: [vocabulary.translation], // For open-ended questions
      hint: difficulty == QuizDifficulty.easy ? vocabulary.definition : null,
      sourceLanguage: vocabulary.sourceLanguage,
      targetLanguage: vocabulary.targetLanguage,
      vocabularyId: vocabulary.id,
      type: QuizType.translation,
    );
  }

  QuizQuestion _generateReverseTranslationQuestion(VocabularyModel vocabulary, QuizDifficulty difficulty) {
    return QuizQuestion(
      id: _generateQuestionId(),
      question: 'Translate: "${vocabulary.translation}"',
      correctAnswer: vocabulary.word,
      options: [vocabulary.word], // For open-ended questions
      hint: difficulty == QuizDifficulty.easy ? vocabulary.definition : null,
      sourceLanguage: vocabulary.targetLanguage,
      targetLanguage: vocabulary.sourceLanguage,
      vocabularyId: vocabulary.id,
      type: QuizType.reverseTranslation,
    );
  }

  QuizQuestion _generateMultipleChoiceQuestion(
    VocabularyModel vocabulary,
    QuizDifficulty difficulty,
    List<VocabularyModel> allVocabulary,
  ) {
    final optionCount = difficulty == QuizDifficulty.hard || difficulty == QuizDifficulty.expert ? 3 : 4;
    final wrongOptions = allVocabulary
        .where((item) => item.id != vocabulary.id && item.targetLanguage == vocabulary.targetLanguage)
        .map((item) => item.translation)
        .toList();
    
    wrongOptions.shuffle(_random);
    final selectedWrongOptions = wrongOptions.take(optionCount - 1).toList();
    
    final allOptions = [vocabulary.translation, ...selectedWrongOptions];
    allOptions.shuffle(_random);

    return QuizQuestion(
      id: _generateQuestionId(),
      question: 'What is the translation of "${vocabulary.word}"?',
      correctAnswer: vocabulary.translation,
      options: allOptions,
      hint: difficulty == QuizDifficulty.easy ? vocabulary.definition : null,
      sourceLanguage: vocabulary.sourceLanguage,
      targetLanguage: vocabulary.targetLanguage,
      vocabularyId: vocabulary.id,
      type: QuizType.multipleChoice,
    );
  }

  QuizQuestion _generateFillInBlankQuestion(VocabularyModel vocabulary, QuizDifficulty difficulty) {
    String question;
    String correctAnswer;

    if (vocabulary.example != null && vocabulary.example!.isNotEmpty) {
      // Use example sentence
      final example = vocabulary.example!;
      final wordToHide = vocabulary.word;
      question = example.replaceAll(wordToHide, '______');
      correctAnswer = wordToHide;
    } else {
      // Create a simple fill-in-blank
      question = 'Complete: The ${vocabulary.targetLanguage} word for "${vocabulary.word}" is ______';
      correctAnswer = vocabulary.translation;
    }

    return QuizQuestion(
      id: _generateQuestionId(),
      question: question,
      correctAnswer: correctAnswer,
      options: [correctAnswer], // For open-ended questions
      hint: difficulty == QuizDifficulty.easy ? vocabulary.definition : null,
      sourceLanguage: vocabulary.sourceLanguage,
      targetLanguage: vocabulary.targetLanguage,
      vocabularyId: vocabulary.id,
      type: QuizType.fillInBlank,
    );
  }

  QuizQuestion _generateListeningQuestion(
    VocabularyModel vocabulary,
    QuizDifficulty difficulty,
    List<VocabularyModel> allVocabulary,
  ) {
    final optionCount = difficulty == QuizDifficulty.hard || difficulty == QuizDifficulty.expert ? 3 : 4;
    final wrongOptions = allVocabulary
        .where((item) => item.id != vocabulary.id && item.sourceLanguage == vocabulary.sourceLanguage)
        .map((item) => item.word)
        .toList();
    
    wrongOptions.shuffle(_random);
    final selectedWrongOptions = wrongOptions.take(optionCount - 1).toList();
    
    final allOptions = [vocabulary.word, ...selectedWrongOptions];
    allOptions.shuffle(_random);

    return QuizQuestion(
      id: _generateQuestionId(),
      question: 'Listen and select the correct word (Audio: "${vocabulary.word}")',
      correctAnswer: vocabulary.word,
      options: allOptions,
      hint: difficulty == QuizDifficulty.easy ? vocabulary.pronunciation : null,
      sourceLanguage: vocabulary.sourceLanguage,
      targetLanguage: vocabulary.targetLanguage,
      vocabularyId: vocabulary.id,
      type: QuizType.listening,
    );
  }

  QuizQuestion _generatePronunciationQuestion(VocabularyModel vocabulary, QuizDifficulty difficulty) {
    return QuizQuestion(
      id: _generateQuestionId(),
      question: 'Pronounce the word: "${vocabulary.word}"',
      correctAnswer: vocabulary.word,
      options: [vocabulary.word], // For pronunciation questions
      hint: difficulty == QuizDifficulty.easy ? vocabulary.pronunciation : null,
      sourceLanguage: vocabulary.sourceLanguage,
      targetLanguage: vocabulary.targetLanguage,
      vocabularyId: vocabulary.id,
      type: QuizType.pronunciation,
    );
  }

  // Helper methods
  int _getQuestionCount(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 10;
      case QuizDifficulty.medium:
        return 15;
      case QuizDifficulty.hard:
        return 20;
      case QuizDifficulty.expert:
        return 25;
    }
  }

  List<QuizType> _getQuestionTypes(QuizMode mode) {
    switch (mode) {
      case QuizMode.mixed:
        return [
          QuizType.translation,
          QuizType.reverseTranslation,
          QuizType.multipleChoice,
          QuizType.fillInBlank,
        ];
      case QuizMode.translationOnly:
        return [QuizType.translation, QuizType.reverseTranslation];
      case QuizMode.multipleChoiceOnly:
        return [QuizType.multipleChoice];
      case QuizMode.listeningOnly:
        return [QuizType.listening];
      case QuizMode.custom:
        return [QuizType.translation, QuizType.multipleChoice];
    }
  }

  String _generateQuestionId() {
    return 'quiz_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  // Create quiz session
  Future<QuizSession> createQuizSession({
    required QuizMode mode,
    required QuizDifficulty difficulty,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final questions = await generateQuizQuestions(
      mode: mode,
      difficulty: difficulty,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    final session = QuizSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      questions: questions,
      results: [],
      startTime: DateTime.now(),
      mode: mode,
      difficulty: difficulty,
      totalQuestions: questions.length,
      correctAnswers: 0,
      totalTimeSpent: 0,
      accuracy: 0.0,
    );

    return session;
  }

  // Submit answer and update session
  QuizSession submitAnswer(
    QuizSession session,
    String questionId,
    String userAnswer,
    int timeSpent,
  ) {
    final question = session.questions.firstWhere((q) => q.id == questionId);
    final isCorrect = _checkAnswer(question, userAnswer);

    final result = QuizResult(
      questionId: questionId,
      userAnswer: userAnswer,
      correctAnswer: question.correctAnswer,
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      answeredAt: DateTime.now(),
    );

    final updatedResults = [...session.results, result];
    final correctAnswers = updatedResults.where((r) => r.isCorrect).length;
    final totalTimeSpent = updatedResults.fold<int>(0, (sum, r) => sum + r.timeSpent);
    final accuracy = correctAnswers / updatedResults.length;

    return QuizSession(
      id: session.id,
      questions: session.questions,
      results: updatedResults,
      startTime: session.startTime,
      endTime: updatedResults.length == session.totalQuestions ? DateTime.now() : null,
      mode: session.mode,
      difficulty: session.difficulty,
      totalQuestions: session.totalQuestions,
      correctAnswers: correctAnswers,
      totalTimeSpent: totalTimeSpent,
      accuracy: accuracy,
    );
  }

  bool _checkAnswer(QuizQuestion question, String userAnswer) {
    final correctAnswer = question.correctAnswer.toLowerCase().trim();
    final userAnswerLower = userAnswer.toLowerCase().trim();
    
    // For multiple choice, exact match
    if (question.type == QuizType.multipleChoice) {
      return correctAnswer == userAnswerLower;
    }
    
    // For translation, allow some flexibility
    return correctAnswer == userAnswerLower || 
           correctAnswer.contains(userAnswerLower) ||
           userAnswerLower.contains(correctAnswer);
  }

  // Save quiz session to database
  Future<void> saveQuizSession(QuizSession session) async {
    try {
      await _databaseService.insertQuizSession(session);
    } catch (e) {
      throw Exception('Failed to save quiz session: $e');
    }
  }

  // Get quiz statistics
  Future<QuizStats> getQuizStats() async {
    try {
      return await _databaseService.getQuizStats();
    } catch (e) {
      return QuizStats.empty();
    }
  }

  // Get recent quiz sessions
  Future<List<QuizSession>> getRecentQuizSessions({int limit = 10}) async {
    try {
      return await _databaseService.getQuizSessions(limit: limit);
    } catch (e) {
      return [];
    }
  }
}
