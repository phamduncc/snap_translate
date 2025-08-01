import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('vi', ''), // Vietnamese
    Locale('en', ''), // English
    Locale('zh', ''), // Chinese
    Locale('ja', ''), // Japanese
    Locale('ko', ''), // Korean
  ];

  // Common
  String get appName => _localizedValues[locale.languageCode]?['app_name'] ?? 'SnapTranslate';
  String get ok => _localizedValues[locale.languageCode]?['ok'] ?? 'OK';
  String get cancel => _localizedValues[locale.languageCode]?['cancel'] ?? 'Hủy';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Lưu';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Xóa';
  String get edit => _localizedValues[locale.languageCode]?['edit'] ?? 'Sửa';
  String get close => _localizedValues[locale.languageCode]?['close'] ?? 'Đóng';
  String get loading => _localizedValues[locale.languageCode]?['loading'] ?? 'Đang tải...';
  String get error => _localizedValues[locale.languageCode]?['error'] ?? 'Lỗi';
  String get success => _localizedValues[locale.languageCode]?['success'] ?? 'Thành công';

  // Navigation
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Trang chủ';
  String get textTranslation => _localizedValues[locale.languageCode]?['text_translation'] ?? 'Dịch văn bản';
  String get voiceTranslation => _localizedValues[locale.languageCode]?['voice_translation'] ?? 'Dịch giọng nói';
  String get imageTranslation => _localizedValues[locale.languageCode]?['image_translation'] ?? 'Dịch từ ảnh';
  String get cameraTranslation => _localizedValues[locale.languageCode]?['camera_translation'] ?? 'Dịch từ camera';
  String get vocabulary => _localizedValues[locale.languageCode]?['vocabulary'] ?? 'Từ vựng';
  String get history => _localizedValues[locale.languageCode]?['history'] ?? 'Lịch sử';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Cài đặt';

  // Translation
  String get translate => _localizedValues[locale.languageCode]?['translate'] ?? 'Dịch';
  String get translating => _localizedValues[locale.languageCode]?['translating'] ?? 'Đang dịch...';
  String get translated => _localizedValues[locale.languageCode]?['translated'] ?? 'Đã dịch';
  String get sourceLanguage => _localizedValues[locale.languageCode]?['source_language'] ?? 'Ngôn ngữ nguồn';
  String get targetLanguage => _localizedValues[locale.languageCode]?['target_language'] ?? 'Ngôn ngữ đích';
  String get autoDetect => _localizedValues[locale.languageCode]?['auto_detect'] ?? 'Tự động phát hiện';
  String get swapLanguages => _localizedValues[locale.languageCode]?['swap_languages'] ?? 'Đổi ngôn ngữ';

  // Text Translation
  String get enterTextToTranslate => _localizedValues[locale.languageCode]?['enter_text_to_translate'] ?? 'Nhập văn bản cần dịch...';
  String get translationResult => _localizedValues[locale.languageCode]?['translation_result'] ?? 'Kết quả dịch';
  String get copyText => _localizedValues[locale.languageCode]?['copy_text'] ?? 'Sao chép';
  String get shareText => _localizedValues[locale.languageCode]?['share_text'] ?? 'Chia sẻ';
  String get speakText => _localizedValues[locale.languageCode]?['speak_text'] ?? 'Phát âm';
  String get saveToVocabulary => _localizedValues[locale.languageCode]?['save_to_vocabulary'] ?? 'Lưu từ vựng';
  String get saved => _localizedValues[locale.languageCode]?['saved'] ?? 'Đã lưu';
  String get cannotSave => _localizedValues[locale.languageCode]?['cannot_save'] ?? 'Không thể lưu';

  // Voice Translation
  String get startListening => _localizedValues[locale.languageCode]?['start_listening'] ?? 'Bắt đầu nghe';
  String get stopListening => _localizedValues[locale.languageCode]?['stop_listening'] ?? 'Dừng nghe';
  String get listening => _localizedValues[locale.languageCode]?['listening'] ?? 'Đang nghe...';
  String get speakNow => _localizedValues[locale.languageCode]?['speak_now'] ?? 'Hãy nói';
  String get tapMicToStart => _localizedValues[locale.languageCode]?['tap_mic_to_start'] ?? 'Nhấn micro để bắt đầu hội thoại';
  String get speakIntoMic => _localizedValues[locale.languageCode]?['speak_into_mic'] ?? 'Nói vào micro, ứng dụng sẽ tự động dịch';

  // Settings
  String get general => _localizedValues[locale.languageCode]?['general'] ?? 'Chung';
  String get appLanguage => _localizedValues[locale.languageCode]?['app_language'] ?? 'Ngôn ngữ ứng dụng';
  String get defaultSourceLanguage => _localizedValues[locale.languageCode]?['default_source_language'] ?? 'Ngôn ngữ mặc định (Nguồn)';
  String get defaultTargetLanguage => _localizedValues[locale.languageCode]?['default_target_language'] ?? 'Ngôn ngữ mặc định (Đích)';
  String get theme => _localizedValues[locale.languageCode]?['theme'] ?? 'Giao diện';
  String get lightTheme => _localizedValues[locale.languageCode]?['light_theme'] ?? 'Sáng';
  String get darkTheme => _localizedValues[locale.languageCode]?['dark_theme'] ?? 'Tối';
  String get systemTheme => _localizedValues[locale.languageCode]?['system_theme'] ?? 'Theo hệ thống';
  String get notifications => _localizedValues[locale.languageCode]?['notifications'] ?? 'Thông báo';
  String get enableNotifications => _localizedValues[locale.languageCode]?['enable_notifications'] ?? 'Nhận thông báo từ ứng dụng';

  // Audio
  String get audio => _localizedValues[locale.languageCode]?['audio'] ?? 'Âm thanh';
  String get autoPlay => _localizedValues[locale.languageCode]?['auto_play'] ?? 'Tự động phát âm';
  String get autoPlayDescription => _localizedValues[locale.languageCode]?['auto_play_description'] ?? 'Phát âm bản dịch sau khi dịch xong';
  String get voiceSpeed => _localizedValues[locale.languageCode]?['voice_speed'] ?? 'Tốc độ giọng';
  String get voicePitch => _localizedValues[locale.languageCode]?['voice_pitch'] ?? 'Cao độ giọng';
  String get soundEffects => _localizedValues[locale.languageCode]?['sound_effects'] ?? 'Hiệu ứng âm thanh';
  String get soundEffectsDescription => _localizedValues[locale.languageCode]?['sound_effects_description'] ?? 'Phát âm thanh khi thực hiện thao tác';
  String get vibration => _localizedValues[locale.languageCode]?['vibration'] ?? 'Rung';
  String get vibrationDescription => _localizedValues[locale.languageCode]?['vibration_description'] ?? 'Rung khi thực hiện thao tác';

  // Vocabulary
  String get myVocabulary => _localizedValues[locale.languageCode]?['my_vocabulary'] ?? 'Từ vựng của tôi';
  String get addVocabulary => _localizedValues[locale.languageCode]?['add_vocabulary'] ?? 'Thêm từ vựng';
  String get addNewVocabulary => _localizedValues[locale.languageCode]?['add_new_vocabulary'] ?? 'Thêm từ vựng mới';
  String get word => _localizedValues[locale.languageCode]?['word'] ?? 'Từ/Cụm từ';
  String get translation => _localizedValues[locale.languageCode]?['translation'] ?? 'Bản dịch';
  String get pronunciation => _localizedValues[locale.languageCode]?['pronunciation'] ?? 'Phát âm';
  String get definition => _localizedValues[locale.languageCode]?['definition'] ?? 'Định nghĩa';
  String get example => _localizedValues[locale.languageCode]?['example'] ?? 'Ví dụ';
  String get exampleTranslation => _localizedValues[locale.languageCode]?['example_translation'] ?? 'Dịch ví dụ';
  String get studyMode => _localizedValues[locale.languageCode]?['study_mode'] ?? 'Chế độ học';
  String get showAnswer => _localizedValues[locale.languageCode]?['show_answer'] ?? 'Hiện đáp án';
  String get hideAnswer => _localizedValues[locale.languageCode]?['hide_answer'] ?? 'Ẩn đáp án';
  String get next => _localizedValues[locale.languageCode]?['next'] ?? 'Sau';
  String get previous => _localizedValues[locale.languageCode]?['previous'] ?? 'Trước';

  // Messages
  String get pleaseEnterText => _localizedValues[locale.languageCode]?['please_enter_text'] ?? 'Vui lòng nhập văn bản cần dịch';
  String get pleaseEnterWordAndTranslation => _localizedValues[locale.languageCode]?['please_enter_word_and_translation'] ?? 'Vui lòng nhập đầy đủ từ và bản dịch';
  String get wordAlreadyExists => _localizedValues[locale.languageCode]?['word_already_exists'] ?? 'Từ này đã có trong từ vựng';
  String get cannotSaveWithAutoDetect => _localizedValues[locale.languageCode]?['cannot_save_with_auto_detect'] ?? 'Không thể lưu từ vựng với ngôn ngữ "Tự động phát hiện"';
  String get translationError => _localizedValues[locale.languageCode]?['translation_error'] ?? 'Lỗi dịch thuật';
  String get speechRecognitionError => _localizedValues[locale.languageCode]?['speech_recognition_error'] ?? 'Lỗi nhận dạng giọng nói';
  String get microphonePermissionDenied => _localizedValues[locale.languageCode]?['microphone_permission_denied'] ?? 'Quyền truy cập microphone bị từ chối';
  String get cameraPermissionDenied => _localizedValues[locale.languageCode]?['camera_permission_denied'] ?? 'Quyền truy cập camera bị từ chối';

  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      'app_name': 'SnapTranslate',
      'ok': 'OK',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'delete': 'Xóa',
      'edit': 'Sửa',
      'close': 'Đóng',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'home': 'Trang chủ',
      'text_translation': 'Dịch văn bản',
      'voice_translation': 'Dịch giọng nói',
      'image_translation': 'Dịch từ ảnh',
      'camera_translation': 'Dịch từ camera',
      'vocabulary': 'Từ vựng',
      'history': 'Lịch sử',
      'settings': 'Cài đặt',
      'translate': 'Dịch',
      'translating': 'Đang dịch...',
      'translated': 'Đã dịch',
      'source_language': 'Ngôn ngữ nguồn',
      'target_language': 'Ngôn ngữ đích',
      'auto_detect': 'Tự động phát hiện',
      'swap_languages': 'Đổi ngôn ngữ',
      'enter_text_to_translate': 'Nhập văn bản cần dịch...',
      'translation_result': 'Kết quả dịch',
      'copy_text': 'Sao chép',
      'share_text': 'Chia sẻ',
      'speak_text': 'Phát âm',
      'save_to_vocabulary': 'Lưu từ vựng',
      'saved': 'Đã lưu',
      'cannot_save': 'Không thể lưu',
      'start_listening': 'Bắt đầu nghe',
      'stop_listening': 'Dừng nghe',
      'listening': 'Đang nghe...',
      'speak_now': 'Hãy nói',
      'tap_mic_to_start': 'Nhấn micro để bắt đầu hội thoại',
      'speak_into_mic': 'Nói vào micro, ứng dụng sẽ tự động dịch',
      'general': 'Chung',
      'app_language': 'Ngôn ngữ ứng dụng',
      'default_source_language': 'Ngôn ngữ mặc định (Nguồn)',
      'default_target_language': 'Ngôn ngữ mặc định (Đích)',
      'theme': 'Giao diện',
      'light_theme': 'Sáng',
      'dark_theme': 'Tối',
      'system_theme': 'Theo hệ thống',
      'notifications': 'Thông báo',
      'enable_notifications': 'Nhận thông báo từ ứng dụng',
      'audio': 'Âm thanh',
      'auto_play': 'Tự động phát âm',
      'auto_play_description': 'Phát âm bản dịch sau khi dịch xong',
      'voice_speed': 'Tốc độ giọng',
      'voice_pitch': 'Cao độ giọng',
      'sound_effects': 'Hiệu ứng âm thanh',
      'sound_effects_description': 'Phát âm thanh khi thực hiện thao tác',
      'vibration': 'Rung',
      'vibration_description': 'Rung khi thực hiện thao tác',
      'my_vocabulary': 'Từ vựng của tôi',
      'add_vocabulary': 'Thêm từ vựng',
      'add_new_vocabulary': 'Thêm từ vựng mới',
      'word': 'Từ/Cụm từ',
      'translation': 'Bản dịch',
      'pronunciation': 'Phát âm',
      'definition': 'Định nghĩa',
      'example': 'Ví dụ',
      'example_translation': 'Dịch ví dụ',
      'study_mode': 'Chế độ học',
      'show_answer': 'Hiện đáp án',
      'hide_answer': 'Ẩn đáp án',
      'next': 'Sau',
      'previous': 'Trước',
      'please_enter_text': 'Vui lòng nhập văn bản cần dịch',
      'please_enter_word_and_translation': 'Vui lòng nhập đầy đủ từ và bản dịch',
      'word_already_exists': 'Từ này đã có trong từ vựng',
      'cannot_save_with_auto_detect': 'Không thể lưu từ vựng với ngôn ngữ "Tự động phát hiện"',
      'translation_error': 'Lỗi dịch thuật',
      'speech_recognition_error': 'Lỗi nhận dạng giọng nói',
      'microphone_permission_denied': 'Quyền truy cập microphone bị từ chối',
      'camera_permission_denied': 'Quyền truy cập camera bị từ chối',
    },
    'en': {
      'app_name': 'SnapTranslate',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'home': 'Home',
      'text_translation': 'Text Translation',
      'voice_translation': 'Voice Translation',
      'image_translation': 'Image Translation',
      'camera_translation': 'Camera Translation',
      'vocabulary': 'Vocabulary',
      'history': 'History',
      'settings': 'Settings',
      'translate': 'Translate',
      'translating': 'Translating...',
      'translated': 'Translated',
      'source_language': 'Source Language',
      'target_language': 'Target Language',
      'auto_detect': 'Auto Detect',
      'swap_languages': 'Swap Languages',
      'enter_text_to_translate': 'Enter text to translate...',
      'translation_result': 'Translation Result',
      'copy_text': 'Copy',
      'share_text': 'Share',
      'speak_text': 'Speak',
      'save_to_vocabulary': 'Save to Vocabulary',
      'saved': 'Saved',
      'cannot_save': 'Cannot Save',
      'start_listening': 'Start Listening',
      'stop_listening': 'Stop Listening',
      'listening': 'Listening...',
      'speak_now': 'Speak Now',
      'tap_mic_to_start': 'Tap microphone to start conversation',
      'speak_into_mic': 'Speak into microphone, app will translate automatically',
      'general': 'General',
      'app_language': 'App Language',
      'default_source_language': 'Default Source Language',
      'default_target_language': 'Default Target Language',
      'theme': 'Theme',
      'light_theme': 'Light',
      'dark_theme': 'Dark',
      'system_theme': 'System',
      'notifications': 'Notifications',
      'enable_notifications': 'Receive notifications from app',
      'audio': 'Audio',
      'auto_play': 'Auto Play',
      'auto_play_description': 'Play translation audio after translating',
      'voice_speed': 'Voice Speed',
      'voice_pitch': 'Voice Pitch',
      'sound_effects': 'Sound Effects',
      'sound_effects_description': 'Play sound when performing actions',
      'vibration': 'Vibration',
      'vibration_description': 'Vibrate when performing actions',
      'my_vocabulary': 'My Vocabulary',
      'add_vocabulary': 'Add Vocabulary',
      'add_new_vocabulary': 'Add New Vocabulary',
      'word': 'Word/Phrase',
      'translation': 'Translation',
      'pronunciation': 'Pronunciation',
      'definition': 'Definition',
      'example': 'Example',
      'example_translation': 'Example Translation',
      'study_mode': 'Study Mode',
      'show_answer': 'Show Answer',
      'hide_answer': 'Hide Answer',
      'next': 'Next',
      'previous': 'Previous',
      'please_enter_text': 'Please enter text to translate',
      'please_enter_word_and_translation': 'Please enter both word and translation',
      'word_already_exists': 'This word already exists in vocabulary',
      'cannot_save_with_auto_detect': 'Cannot save vocabulary with "Auto Detect" language',
      'translation_error': 'Translation Error',
      'speech_recognition_error': 'Speech Recognition Error',
      'microphone_permission_denied': 'Microphone permission denied',
      'camera_permission_denied': 'Camera permission denied',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
