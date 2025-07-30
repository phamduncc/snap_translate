import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFFBBDEFB);
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryDarkColor = Color(0xFF018786);
  static const Color secondaryLightColor = Color(0xFFA7FFEB);
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textHintColor = Color(0xFFBDBDBD);
  static const Color textOnPrimaryColor = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Camera Overlay Colors
  static const Color overlayColor = Color(0x80000000);
  static const Color scanAreaColor = Color(0xFF00FF00);
  static const Color translationOverlayColor = Color(0xE6FFFFFF);
  
  // Button Colors
  static const Color buttonPrimaryColor = primaryColor;
  static const Color buttonSecondaryColor = Color(0xFFE0E0E0);
  static const Color buttonDisabledColor = Color(0xFFBDBDBD);
  
  // Border Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color focusedBorderColor = primaryColor;
  static const Color errorBorderColor = errorColor;
  
  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color cardShadowColor = Color(0x0D000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDarkColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Language Flag Colors (for language selection)
  static const Map<String, Color> languageColors = {
    'en': Color(0xFF1f77b4),
    'vi': Color(0xFFff7f0e),
    'zh': Color(0xFF2ca02c),
    'ja': Color(0xFFd62728),
    'ko': Color(0xFF9467bd),
    'fr': Color(0xFF8c564b),
    'de': Color(0xFFe377c2),
    'es': Color(0xFF7f7f7f),
    'it': Color(0xFFbcbd22),
    'ru': Color(0xFF17becf),
  };
}
