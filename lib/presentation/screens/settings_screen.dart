import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../services/settings_service.dart';
import '../../services/haptic_service.dart';
import '../../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

import '../../data/models/settings_model.dart';
import '../../data/models/language_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final HapticService _hapticService = HapticService();

  SettingsModel _settings = SettingsModel.defaultSettings();
  bool _isLoading = false;
  String _cacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _settingsService.initialize();
      final cacheSize = await _settingsService.getCacheSizeInBytes();

      setState(() {
        _settings = _settingsService.settings;
        _cacheSize = _formatBytes(cacheSize);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi tải cài đặt: $e', isError: true);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsList(),
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        _buildSectionHeader(AppLocalizations.of(context)?.general ?? 'General'),
        _buildThemeSettings(),
        _buildNotificationSettings(),

        // const SizedBox(height: 24),
        // _buildSectionHeader(AppLocalizations.of(context)?.audio ?? 'Audio'),
        // _buildAutoPlaySettings(),
        // _buildTTSSettings(),
        // _buildSoundEffectsSettings(),
        // _buildVibrationSettings(),

        // const SizedBox(height: 24),
        // _buildSectionHeader('Translation'),
        // _buildOfflineModeSettings(),
        // _buildAutoDetectSettings(),
        // _buildConfidenceScoreSettings(),

        // const SizedBox(height: 24),
        // _buildSectionHeader('Privacy'),
        // _buildHistorySettings(),
        // _buildAnalyticsSettings(),

        // const SizedBox(height: 24),
        // _buildSectionHeader('Advanced'),
        // _buildCacheSettings(),
        // _buildMaxHistorySettings(),

        const SizedBox(height: 24),
        _buildSectionHeader('System'),
        _buildAppInfoCard(),

        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return Card(
      child: Column(
        children: [
          _buildDropdownTile(
            icon: Icons.language,
            title: AppLocalizations.of(context)?.appLanguage ?? 'App Language',
            subtitle: _getAppLanguageName(_settings.appLanguage),
            value: _settings.appLanguage,
            options: const [
              {'value': 'vi', 'label': 'Tiếng Việt'},
              {'value': 'en', 'label': 'English'},
            ],
            onChanged: (value) => _updateSetting('appLanguage', value),
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            icon: Icons.language,
            title: AppLocalizations.of(context)?.defaultSourceLanguage ?? 'Default Source Language',
            subtitle: _getLanguageName(_settings.defaultSourceLanguage),
            value: _settings.defaultSourceLanguage,
            options: LanguageModel.defaultLanguages.map((lang) => {
              'value': lang.code,
              'label': lang.nativeName,
            }).toList(),
            onChanged: (value) => _updateSetting('defaultSourceLanguage', value),
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            icon: Icons.translate,
            title: AppLocalizations.of(context)?.defaultTargetLanguage ?? 'Default Target Language',
            subtitle: _getLanguageName(_settings.defaultTargetLanguage),
            value: _settings.defaultTargetLanguage,
            options: LanguageModel.defaultLanguages.map((lang) => {
              'value': lang.code,
              'label': lang.nativeName,
            }).toList(),
            onChanged: (value) => _updateSetting('defaultTargetLanguage', value),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Card(
      child: _buildDropdownTile(
        icon: Icons.palette,
        title: AppLocalizations.of(context)?.theme ?? 'Theme',
        subtitle: _getThemeName(_settings.appTheme),
        value: _settings.appTheme,
        options: [
          {'value': 'light', 'label': AppLocalizations.of(context)?.lightTheme ?? 'Light'},
          {'value': 'dark', 'label': AppLocalizations.of(context)?.darkTheme ?? 'Dark'},
          {'value': 'system', 'label': AppLocalizations.of(context)?.systemTheme ?? 'System'},
        ],
        onChanged: (value) => _updateSetting('appTheme', value),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.notifications,
        title: AppLocalizations.of(context)?.notifications ?? 'Notifications',
        subtitle: AppLocalizations.of(context)?.enableNotifications ?? 'Receive notifications from app',
        value: _settings.enableNotifications,
        onChanged: (value) => _updateSetting('enableNotifications', value),
      ),
    );
  }

  Widget _buildAutoPlaySettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.play_arrow,
        title: AppLocalizations.of(context)?.autoPlay ?? 'Auto Play',
        subtitle: AppLocalizations.of(context)?.autoPlayDescription ?? 'Play translation audio after translating',
        value: _settings.autoPlayTranslation,
        onChanged: (value) => _updateSetting('autoPlayTranslation', value),
      ),
    );
  }

  Widget _buildTTSSettings() {
    return Card(
      child: Column(
        children: [
          _buildDropdownTile(
            icon: Icons.speed,
            title: AppLocalizations.of(context)?.voiceSpeed ?? 'Voice Speed',
            subtitle: _getTTSSpeedName(_settings.ttsVoiceSpeed),
            value: _settings.ttsVoiceSpeed,
            options: const [
              {'value': 'slow', 'label': 'Slow'},
              {'value': 'normal', 'label': 'Normal'},
              {'value': 'fast', 'label': 'Fast'},
            ],
            onChanged: (value) => _updateSetting('ttsVoiceSpeed', value),
          ),
          const Divider(height: 1),
          _buildDropdownTile(
            icon: Icons.graphic_eq,
            title: AppLocalizations.of(context)?.voicePitch ?? 'Voice Pitch',
            subtitle: _getTTSPitchName(_settings.ttsVoicePitch),
            value: _settings.ttsVoicePitch,
            options: const [
              {'value': 'low', 'label': 'Low'},
              {'value': 'normal', 'label': 'Normal'},
              {'value': 'high', 'label': 'High'},
            ],
            onChanged: (value) => _updateSetting('ttsVoicePitch', value),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundEffectsSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.volume_up,
        title: AppLocalizations.of(context)?.soundEffects ?? 'Sound Effects',
        subtitle: AppLocalizations.of(context)?.soundEffectsDescription ?? 'Play sound when performing actions',
        value: _settings.enableSoundEffects,
        onChanged: (value) => _updateSetting('enableSoundEffects', value),
      ),
    );
  }

  Widget _buildVibrationSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.vibration,
        title: AppLocalizations.of(context)?.vibration ?? 'Vibration',
        subtitle: AppLocalizations.of(context)?.vibrationDescription ?? 'Vibrate when performing actions',
        value: _settings.enableVibration,
        onChanged: (value) => _updateSetting('enableVibration', value),
      ),
    );
  }

  Widget _buildOfflineModeSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.offline_bolt,
        title: 'Offline Mode',
        subtitle: 'Use offline translation when possible',
        value: _settings.isOfflineMode,
        onChanged: (value) => _updateSetting('isOfflineMode', value),
      ),
    );
  }

  Widget _buildAutoDetectSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.auto_awesome,
        title: 'Auto Language Detection',
        subtitle: 'Automatically detect source language',
        value: _settings.autoDetectLanguage,
        onChanged: (value) => _updateSetting('autoDetectLanguage', value),
      ),
    );
  }

  Widget _buildConfidenceScoreSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.analytics,
        title: 'Show Confidence Score',
        subtitle: 'Display translation confidence score',
        value: _settings.showConfidenceScore,
        onChanged: (value) => _updateSetting('showConfidenceScore', value),
      ),
    );
  }

  Widget _buildHistorySettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.history,
        title: 'Save History',
        subtitle: 'Save translations to history',
        value: _settings.saveToHistory,
        onChanged: (value) => _updateSetting('saveToHistory', value),
      ),
    );
  }

  Widget _buildAnalyticsSettings() {
    return Card(
      child: _buildSwitchTile(
        icon: Icons.analytics_outlined,
        title: 'Usage Analytics',
        subtitle: 'Send analytics data to improve app',
        value: _settings.enableAnalytics,
        onChanged: (value) => _updateSetting('enableAnalytics', value),
      ),
    );
  }

  Widget _buildCacheSettings() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.storage, color: AppColors.primaryColor),
        title: const Text('Cache Storage'),
        subtitle: Text('Used: $_cacheSize'),
        trailing: TextButton(
          onPressed: _clearCache,
          child: const Text('Xóa'),
        ),
      ),
    );
  }

  Widget _buildMaxHistorySettings() {
    return Card(
      child: _buildDropdownTile(
        icon: Icons.list,
        title: 'Max History Items',
        subtitle: '${_settings.maxHistoryItems} items',
        value: _settings.maxHistoryItems,
        options: const [
          {'value': 100, 'label': '100 mục'},
          {'value': 500, 'label': '500 mục'},
          {'value': 1000, 'label': '1000 mục'},
          {'value': 5000, 'label': '5000 mục'},
        ],
        onChanged: (value) => _updateSetting('maxHistoryItems', value),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.primaryColor),
            title: const Text('App Information'),
            subtitle: const Text('SnapTranslate v1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAppInfo,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help, color: AppColors.successColor),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showHelp,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.warningColor),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyPolicy,
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic value,
    required List<Map<String, dynamic>> options,
    required Function(dynamic) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<dynamic>(
        value: value,
        underline: const SizedBox.shrink(),
        items: options.map((option) {
          return DropdownMenuItem<dynamic>(
            value: option['value'],
            child: Text(option['label'].toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Action methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _showResetDialog();
        break;
      case 'export':
        _exportSettings();
        break;
      case 'import':
        _importSettings();
        break;
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Update setting through AppProvider
      await appProvider.updateSetting(key, value);

      // Update local state
      setState(() {
        _settings = appProvider.settings;
      });

      // Provide haptic feedback
      await _hapticService.buttonPress();

      // Show feedback for theme/language changes
      if (key == 'appTheme') {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Đã thay đổi giao diện');
        }
      } else if (key == 'appLanguage') {
        if (mounted) {
          AppUtils.showSnackBar(context, 'Đã thay đổi ngôn ngữ');
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi cập nhật cài đặt: $e', isError: true);
        await _hapticService.error();
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục cài đặt mặc định'),
        content: const Text('Bạn có chắc chắn muốn khôi phục tất cả cài đặt về mặc định?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetSettings();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    try {
      await _settingsService.resetToDefaults();
      setState(() {
        _settings = _settingsService.settings;
      });

      if (mounted) {
        AppUtils.showSnackBar(context, 'Đã khôi phục cài đặt mặc định');
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi khôi phục cài đặt: $e', isError: true);
      }
    }
  }

  void _exportSettings() {
    try {
      final settingsJson = jsonEncode(_settingsService.exportSettings());

      // Copy to clipboard
      Clipboard.setData(ClipboardData(text: settingsJson));

      // Show dialog with settings data
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xuất cài đặt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cài đặt đã được sao chép vào clipboard.'),
              const SizedBox(height: 16),
              const Text('Dữ liệu cài đặt:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  settingsJson,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      AppUtils.showSnackBar(context, 'Đã xuất cài đặt vào clipboard');
    } catch (e) {
      AppUtils.showSnackBar(context, 'Lỗi xuất cài đặt: $e', isError: true);
    }
  }

  void _importSettings() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();

        return AlertDialog(
          title: const Text('Nhập cài đặt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Dán dữ liệu cài đặt JSON vào ô bên dưới:'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Dán JSON cài đặt ở đây...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final jsonText = textController.text.trim();
                  if (jsonText.isEmpty) {
                    AppUtils.showSnackBar(context, 'Vui lòng nhập dữ liệu JSON', isError: true);
                    return;
                  }

                  final settingsData = jsonDecode(jsonText) as Map<String, dynamic>;
                  await _settingsService.importSettings(settingsData);

                  setState(() {
                    _settings = _settingsService.settings;
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    AppUtils.showSnackBar(context, 'Đã nhập cài đặt thành công');
                  }
                } catch (e) {
                  if (mounted) {
                    AppUtils.showSnackBar(context, 'Lỗi nhập cài đặt: $e', isError: true);
                  }
                }
              },
              child: const Text('Nhập'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bộ nhớ đệm'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ bộ nhớ đệm? Điều này có thể làm chậm ứng dụng trong lần sử dụng tiếp theo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _settingsService.clearCache();
      final newCacheSize = await _settingsService.getCacheSizeInBytes();
      setState(() {
        _cacheSize = _formatBytes(newCacheSize);
      });

      await _hapticService.success();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Đã xóa bộ nhớ đệm');
      }
    } catch (e) {
      await _hapticService.error();
      if (mounted) {
        AppUtils.showSnackBar(context, 'Lỗi xóa bộ nhớ đệm: $e', isError: true);
      }
    }
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin ứng dụng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SnapTranslate'),
            Text('Phiên bản: 1.0.0'),
            Text('Build: 1'),
            SizedBox(height: 16),
            Text('Ứng dụng dịch thuật đa tính năng với OCR, giọng nói và camera real-time.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trợ giúp & Hướng dẫn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection('📷 Dịch từ ảnh', [
                '• Chụp ảnh hoặc chọn từ thư viện',
                '• Ứng dụng sẽ tự động nhận dạng văn bản',
                '• Chọn ngôn ngữ nguồn và đích',
                '• Nhấn "Dịch" để xem kết quả',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('📱 Camera thời gian thực', [
                '• Hướng camera vào văn bản',
                '• Overlay dịch sẽ hiện tự động',
                '• Tap overlay để nghe phát âm',
                '• Dùng nút tạm dừng để dừng dịch',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('🎤 Dịch hội thoại', [
                '• Chọn người nói A hoặc B',
                '• Nhấn micro để bắt đầu nói',
                '• Ứng dụng sẽ tự động dịch và đọc',
                '• Xem lịch sử hội thoại bên trên',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('📚 Học từ vựng', [
                '• Xem danh sách từ vựng đã lưu',
                '• Dùng chế độ học với flashcard',
                '• Đánh dấu từ đã thuộc',
                '• Ôn tập từ cần nhớ',
              ]),
              const SizedBox(height: 16),
              _buildHelpSection('⚙️ Cài đặt', [
                '• Thay đổi ngôn ngữ mặc định',
                '• Bật/tắt tự động phát âm',
                '• Điều chỉnh tốc độ và cao độ giọng đọc',
                '• Quản lý bộ nhớ đệm',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách bảo mật'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrivacySection('📊 Thu thập dữ liệu', [
                '• Ứng dụng chỉ lưu trữ dữ liệu cục bộ trên thiết bị',
                '• Không thu thập thông tin cá nhân',
                '• Lịch sử dịch được lưu offline',
                '• Không chia sẻ dữ liệu với bên thứ ba',
              ]),
              const SizedBox(height: 16),
              _buildPrivacySection('🔒 Bảo mật dữ liệu', [
                '• Dữ liệu được mã hóa trong cơ sở dữ liệu',
                '• Không gửi dữ liệu lên server',
                '• Quyền truy cập camera/micro chỉ khi sử dụng',
                '• Có thể xóa toàn bộ dữ liệu bất kỳ lúc nào',
              ]),
              const SizedBox(height: 16),
              _buildPrivacySection('🌐 Dịch vụ bên ngoài', [
                '• Sử dụng Google Translate API (tùy chọn)',
                '• Dữ liệu dịch có thể được gửi qua internet',
                '• Có thể sử dụng chế độ offline',
                '• Tuân thủ chính sách của Google',
              ]),
              const SizedBox(height: 16),
              _buildPrivacySection('⚖️ Quyền của người dùng', [
                '• Quyền xóa toàn bộ dữ liệu',
                '• Quyền xuất dữ liệu cá nhân',
                '• Quyền từ chối thu thập dữ liệu',
                '• Quyền liên hệ hỗ trợ',
              ]),
              const SizedBox(height: 16),
              Text(
                'Cập nhật lần cuối: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  // Helper methods for display names
  String _getLanguageName(String languageCode) {
    final language = LanguageModel.defaultLanguages
        .firstWhere((lang) => lang.code == languageCode,
                   orElse: () => LanguageModel(code: languageCode, name: languageCode, nativeName: languageCode));
    return language.nativeName;
  }

  String _getAppLanguageName(String languageCode) {
    switch (languageCode) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'Tiếng Việt';
    }
  }

  String _getThemeName(String theme) {
    switch (theme) {
      case 'light':
        return 'Sáng';
      case 'dark':
        return 'Tối';
      case 'system':
        return 'Theo hệ thống';
      default:
        return 'Không xác định';
    }
  }

  String _getTTSSpeedName(String speed) {
    switch (speed) {
      case 'slow':
        return 'Chậm';
      case 'normal':
        return 'Bình thường';
      case 'fast':
        return 'Nhanh';
      default:
        return 'Không xác định';
    }
  }

  String _getTTSPitchName(String pitch) {
    switch (pitch) {
      case 'low':
        return 'Thấp';
      case 'normal':
        return 'Bình thường';
      case 'high':
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }
}
