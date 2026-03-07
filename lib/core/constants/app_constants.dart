import 'package:flutter/material.dart';

class AppConstants {
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'ko', 'icon': '🇰🇷'},
    {'code': 'en', 'icon': '🇺🇸'},
    {'code': 'es', 'icon': '🇪🇸'},
    {'code': 'fr', 'icon': '🇫🇷'},
    {'code': 'ja', 'icon': '🇯🇵'},
    {'code': 'zh', 'icon': '🇨🇳'},
  ];

  static const List<Locale> supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('zh'),
  ];
}
