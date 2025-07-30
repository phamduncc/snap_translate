class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final bool isSupported;
  final bool isOfflineSupported;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isSupported = true,
    this.isOfflineSupported = false,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['nativeName'] as String,
      isSupported: json['isSupported'] as bool? ?? true,
      isOfflineSupported: json['isOfflineSupported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nativeName': nativeName,
      'isSupported': isSupported,
      'isOfflineSupported': isOfflineSupported,
    };
  }

  factory LanguageModel.fromMap(Map<String, dynamic> map) {
    return LanguageModel(
      code: map['code'] as String,
      name: map['name'] as String,
      nativeName: map['native_name'] as String,
      isSupported: (map['is_supported'] as int) == 1,
      isOfflineSupported: (map['is_offline_supported'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'native_name': nativeName,
      'is_supported': isSupported ? 1 : 0,
      'is_offline_supported': isOfflineSupported ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'LanguageModel(code: $code, name: $name, nativeName: $nativeName)';
  }

  LanguageModel copyWith({
    String? code,
    String? name,
    String? nativeName,
    bool? isSupported,
    bool? isOfflineSupported,
  }) {
    return LanguageModel(
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      isSupported: isSupported ?? this.isSupported,
      isOfflineSupported: isOfflineSupported ?? this.isOfflineSupported,
    );
  }

  // Predefined languages
  static const List<LanguageModel> defaultLanguages = [
    LanguageModel(
      code: 'auto',
      name: 'Auto Detect',
      nativeName: 'Tự động phát hiện',
    ),
    LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      isOfflineSupported: true,
    ),
    LanguageModel(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      isOfflineSupported: true,
    ),
    LanguageModel(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      isOfflineSupported: true,
    ),
    LanguageModel(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      isOfflineSupported: true,
    ),
    LanguageModel(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
    ),
    LanguageModel(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
    ),
    LanguageModel(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
    ),
    LanguageModel(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
    ),
    LanguageModel(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
    ),
    LanguageModel(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
    ),
    LanguageModel(
      code: 'th',
      name: 'Thai',
      nativeName: 'ไทย',
    ),
    LanguageModel(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
    ),
    LanguageModel(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
    ),
  ];
}
