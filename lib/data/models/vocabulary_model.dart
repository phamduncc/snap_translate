class VocabularyModel {
  final String id;
  final String word;
  final String translation;
  final String sourceLanguage;
  final String targetLanguage;
  final String? pronunciation;
  final String? definition;
  final String? example;
  final String? exampleTranslation;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? lastReviewed;
  final int reviewCount;
  final double difficulty;
  final bool isMastered;
  final List<String> tags;

  const VocabularyModel({
    required this.id,
    required this.word,
    required this.translation,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.pronunciation,
    this.definition,
    this.example,
    this.exampleTranslation,
    this.imagePath,
    required this.createdAt,
    this.lastReviewed,
    this.reviewCount = 0,
    this.difficulty = 0.5,
    this.isMastered = false,
    this.tags = const [],
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      pronunciation: json['pronunciation'] as String?,
      definition: json['definition'] as String?,
      example: json['example'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastReviewed: json['lastReviewed'] != null 
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      isMastered: json['isMastered'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'pronunciation': pronunciation,
      'definition': definition,
      'example': example,
      'exampleTranslation': exampleTranslation,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'reviewCount': reviewCount,
      'difficulty': difficulty,
      'isMastered': isMastered,
      'tags': tags,
    };
  }

  factory VocabularyModel.fromMap(Map<String, dynamic> map) {
    return VocabularyModel(
      id: map['id'] as String,
      word: map['word'] as String,
      translation: map['translation'] as String,
      sourceLanguage: map['source_language'] as String,
      targetLanguage: map['target_language'] as String,
      pronunciation: map['pronunciation'] as String?,
      definition: map['definition'] as String?,
      example: map['example'] as String?,
      exampleTranslation: map['example_translation'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastReviewed: map['last_reviewed'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reviewed'] as int)
          : null,
      reviewCount: map['review_count'] as int? ?? 0,
      difficulty: (map['difficulty'] as num?)?.toDouble() ?? 0.5,
      isMastered: (map['is_mastered'] as int) == 1,
      tags: (map['tags'] as String?)?.split(',') ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'pronunciation': pronunciation,
      'definition': definition,
      'example': example,
      'example_translation': exampleTranslation,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_reviewed': lastReviewed?.millisecondsSinceEpoch,
      'review_count': reviewCount,
      'difficulty': difficulty,
      'is_mastered': isMastered ? 1 : 0,
      'tags': tags.join(','),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VocabularyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VocabularyModel(id: $id, word: $word, translation: $translation)';
  }

  VocabularyModel copyWith({
    String? id,
    String? word,
    String? translation,
    String? sourceLanguage,
    String? targetLanguage,
    String? pronunciation,
    String? definition,
    String? example,
    String? exampleTranslation,
    String? imagePath,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    double? difficulty,
    bool? isMastered,
    List<String>? tags,
  }) {
    return VocabularyModel(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      pronunciation: pronunciation ?? this.pronunciation,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      difficulty: difficulty ?? this.difficulty,
      isMastered: isMastered ?? this.isMastered,
      tags: tags ?? this.tags,
    );
  }

  // Helper methods for spaced repetition
  bool get isDueForReview {
    if (lastReviewed == null) return true;
    
    final daysSinceReview = DateTime.now().difference(lastReviewed!).inDays;
    final intervalDays = _calculateInterval();
    
    return daysSinceReview >= intervalDays;
  }

  int _calculateInterval() {
    if (reviewCount == 0) return 1;
    if (reviewCount == 1) return 3;
    if (reviewCount == 2) return 7;
    
    // Exponential backoff based on difficulty
    final baseInterval = 14;
    final difficultyMultiplier = 1 + (1 - difficulty);
    return (baseInterval * difficultyMultiplier * (reviewCount - 2)).round();
  }

  VocabularyModel markAsReviewed({required bool wasCorrect}) {
    final newDifficulty = wasCorrect 
        ? (difficulty * 0.9).clamp(0.0, 1.0)
        : (difficulty * 1.1).clamp(0.0, 1.0);
    
    return copyWith(
      lastReviewed: DateTime.now(),
      reviewCount: reviewCount + 1,
      difficulty: newDifficulty,
      isMastered: newDifficulty < 0.2 && reviewCount >= 5,
    );
  }
}
