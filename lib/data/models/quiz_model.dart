import 'dart:convert';

class QuizQuestion {
  final String id;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String? hint;
  final String sourceLanguage;
  final String targetLanguage;
  final String vocabularyId;
  final QuizType type;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    required this.options,
    this.hint,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.vocabularyId,
    required this.type,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      correctAnswer: json['correctAnswer'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      hint: json['hint'],
      sourceLanguage: json['sourceLanguage'] ?? '',
      targetLanguage: json['targetLanguage'] ?? '',
      vocabularyId: json['vocabularyId'] ?? '',
      type: QuizType.values.firstWhere(
        (e) => e.toString() == 'QuizType.${json['type']}',
        orElse: () => QuizType.translation,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'correctAnswer': correctAnswer,
      'options': options,
      'hint': hint,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'vocabularyId': vocabularyId,
      'type': type.toString().split('.').last,
    };
  }
}

class QuizResult {
  final String questionId;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int timeSpent; // in seconds
  final DateTime answeredAt;

  QuizResult({
    required this.questionId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeSpent,
    required this.answeredAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      questionId: json['questionId'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      correctAnswer: json['correctAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      timeSpent: json['timeSpent'] ?? 0,
      answeredAt: DateTime.parse(json['answeredAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}

class QuizSession {
  final String id;
  final List<QuizQuestion> questions;
  final List<QuizResult> results;
  final DateTime startTime;
  final DateTime? endTime;
  final QuizMode mode;
  final QuizDifficulty difficulty;
  final int totalQuestions;
  final int correctAnswers;
  final int totalTimeSpent;
  final double accuracy;

  QuizSession({
    required this.id,
    required this.questions,
    required this.results,
    required this.startTime,
    this.endTime,
    required this.mode,
    required this.difficulty,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalTimeSpent,
    required this.accuracy,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(q))
          .toList() ?? [],
      results: (json['results'] as List<dynamic>?)
          ?.map((r) => QuizResult.fromJson(r))
          .toList() ?? [],
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      mode: QuizMode.values.firstWhere(
        (e) => e.toString() == 'QuizMode.${json['mode']}',
        orElse: () => QuizMode.mixed,
      ),
      difficulty: QuizDifficulty.values.firstWhere(
        (e) => e.toString() == 'QuizDifficulty.${json['difficulty']}',
        orElse: () => QuizDifficulty.medium,
      ),
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questions': questions.map((q) => q.toJson()).toList(),
      'results': results.map((r) => r.toJson()).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'mode': mode.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'totalTimeSpent': totalTimeSpent,
      'accuracy': accuracy,
    };
  }

  bool get isCompleted => endTime != null;
  
  int get remainingQuestions => totalQuestions - results.length;
  
  double get progress => results.length / totalQuestions;
  
  String get formattedAccuracy => '${(accuracy * 100).toStringAsFixed(1)}%';
  
  String get formattedTime {
    final minutes = totalTimeSpent ~/ 60;
    final seconds = totalTimeSpent % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

enum QuizType {
  translation,      // Dịch từ nguồn sang đích
  reverseTranslation, // Dịch từ đích về nguồn
  multipleChoice,   // Trắc nghiệm
  fillInBlank,      // Điền vào chỗ trống
  listening,        // Nghe và chọn đáp án
  pronunciation,    // Phát âm
}

enum QuizMode {
  mixed,           // Trộn tất cả loại câu hỏi
  translationOnly, // Chỉ dịch thuật
  multipleChoiceOnly, // Chỉ trắc nghiệm
  listeningOnly,   // Chỉ nghe
  custom,          // Tùy chỉnh
}

enum QuizDifficulty {
  easy,    // 10 câu, 4 lựa chọn, có gợi ý
  medium,  // 15 câu, 4 lựa chọn, ít gợi ý
  hard,    // 20 câu, 3 lựa chọn, không gợi ý
  expert,  // 25 câu, 3 lựa chọn, thời gian giới hạn
}

class QuizStats {
  final int totalQuizzes;
  final int totalQuestions;
  final int correctAnswers;
  final double averageAccuracy;
  final int totalTimeSpent;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> languagePairStats;
  final Map<QuizDifficulty, int> difficultyStats;
  final DateTime? lastQuizDate;

  QuizStats({
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageAccuracy,
    required this.totalTimeSpent,
    required this.currentStreak,
    required this.longestStreak,
    required this.languagePairStats,
    required this.difficultyStats,
    this.lastQuizDate,
  });

  factory QuizStats.empty() {
    return QuizStats(
      totalQuizzes: 0,
      totalQuestions: 0,
      correctAnswers: 0,
      averageAccuracy: 0.0,
      totalTimeSpent: 0,
      currentStreak: 0,
      longestStreak: 0,
      languagePairStats: {},
      difficultyStats: {},
      lastQuizDate: null,
    );
  }

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      totalQuizzes: json['totalQuizzes'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      languagePairStats: Map<String, int>.from(json['languagePairStats'] ?? {}),
      difficultyStats: Map<QuizDifficulty, int>.from(
        (json['difficultyStats'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            QuizDifficulty.values.firstWhere(
              (e) => e.toString() == 'QuizDifficulty.$key',
              orElse: () => QuizDifficulty.medium,
            ),
            value as int,
          ),
        ),
      ),
      lastQuizDate: json['lastQuizDate'] != null 
          ? DateTime.parse(json['lastQuizDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_quizzes': totalQuizzes,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'average_accuracy': averageAccuracy,
      'total_time_spent': totalTimeSpent,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'language_pair_stats': jsonEncode(languagePairStats),
      'difficulty_stats': jsonEncode(difficultyStats.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      )),
      'last_quiz_date': lastQuizDate?.toIso8601String(),
    };
  }

  String get formattedAverageAccuracy => '${(averageAccuracy * 100).toStringAsFixed(1)}%';
  
  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
