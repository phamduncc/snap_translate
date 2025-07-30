class TranslationModel {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime createdAt;
  final double confidence;
  final String? imagePath;
  final TranslationType type;
  final bool isFavorite;

  const TranslationModel({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
    this.confidence = 1.0,
    this.imagePath,
    this.type = TranslationType.text,
    this.isFavorite = false,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      imagePath: json['imagePath'] as String?,
      type: TranslationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TranslationType.text,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'createdAt': createdAt.toIso8601String(),
      'confidence': confidence,
      'imagePath': imagePath,
      'type': type.name,
      'isFavorite': isFavorite,
    };
  }

  factory TranslationModel.fromMap(Map<String, dynamic> map) {
    return TranslationModel(
      id: map['id'] as String,
      originalText: map['original_text'] as String,
      translatedText: map['translated_text'] as String,
      sourceLanguage: map['source_language'] as String,
      targetLanguage: map['target_language'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      imagePath: map['image_path'] as String?,
      type: TranslationType.values.firstWhere(
        (e) => e.index == map['type'],
        orElse: () => TranslationType.text,
      ),
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_text': originalText,
      'translated_text': translatedText,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'created_at': createdAt.millisecondsSinceEpoch,
      'confidence': confidence,
      'image_path': imagePath,
      'type': type.index,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TranslationModel(id: $id, originalText: $originalText, translatedText: $translatedText)';
  }

  TranslationModel copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? createdAt,
    double? confidence,
    String? imagePath,
    TranslationType? type,
    bool? isFavorite,
  }) {
    return TranslationModel(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      createdAt: createdAt ?? this.createdAt,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

enum TranslationType {
  text,
  image,
  camera,
  voice,
}

extension TranslationTypeExtension on TranslationType {
  String get displayName {
    switch (this) {
      case TranslationType.text:
        return 'Văn bản';
      case TranslationType.image:
        return 'Hình ảnh';
      case TranslationType.camera:
        return 'Camera';
      case TranslationType.voice:
        return 'Giọng nói';
    }
  }

  String get icon {
    switch (this) {
      case TranslationType.text:
        return '📝';
      case TranslationType.image:
        return '🖼️';
      case TranslationType.camera:
        return '📷';
      case TranslationType.voice:
        return '🎤';
    }
  }
}
