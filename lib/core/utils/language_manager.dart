import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  static LanguageManager get instance => _instance;
  
  LanguageManager._internal();

  Locale _currentLocale = const Locale('ar'); // اللغة الافتراضية العربية
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'العربية';
    }
  }

  List<Locale> get supportedLocales => const [
    Locale('ar'),
    Locale('en'), 
    Locale('fr'),
  ];

  List<Map<String, String>> get supportedLanguages => const [
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'Français'},
  ];

  Future<void> initializeLanguage() async {
    final code = await DatabaseHelper.instance.getMetadata('language_code') ?? 'ar';
    _currentLocale = Locale(code);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLocale.languageCode) return;
    
    _currentLocale = Locale(languageCode);
    await DatabaseHelper.instance.setMetadata('language_code', languageCode);
    notifyListeners();
  }
}
