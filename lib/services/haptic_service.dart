import 'package:flutter/services.dart';
import 'settings_service.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  final SettingsService _settingsService = SettingsService();

  // Light haptic feedback
  Future<void> lightImpact() async {
    if (_settingsService.settings.enableVibration) {
      try {
        await HapticFeedback.lightImpact();
      } catch (e) {
        // Ignore haptic errors
      }
    }
  }

  // Medium haptic feedback
  Future<void> mediumImpact() async {
    if (_settingsService.settings.enableVibration) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (e) {
        // Ignore haptic errors
      }
    }
  }

  // Heavy haptic feedback
  Future<void> heavyImpact() async {
    if (_settingsService.settings.enableVibration) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (e) {
        // Ignore haptic errors
      }
    }
  }

  // Selection click
  Future<void> selectionClick() async {
    if (_settingsService.settings.enableVibration) {
      try {
        await HapticFeedback.selectionClick();
      } catch (e) {
        // Ignore haptic errors
      }
    }
  }

  // Vibrate for success
  Future<void> success() async {
    await lightImpact();
  }

  // Vibrate for error
  Future<void> error() async {
    await heavyImpact();
  }

  // Vibrate for button press
  Future<void> buttonPress() async {
    await selectionClick();
  }

  // Vibrate for translation complete
  Future<void> translationComplete() async {
    await mediumImpact();
  }

  // Vibrate for camera capture
  Future<void> cameraCapture() async {
    await lightImpact();
  }

  // Vibrate for voice recognition start
  Future<void> voiceStart() async {
    await lightImpact();
  }

  // Vibrate for voice recognition stop
  Future<void> voiceStop() async {
    await mediumImpact();
  }
}
