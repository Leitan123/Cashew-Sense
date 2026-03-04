import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../data/app_translations.dart';

class LocalizationService extends ChangeNotifier {
  static const String _langKey = 'selected_language';
  
  String _currentLanguage = 'en'; // default English
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_langKey) ?? 'en';
  }

  Future<void> changeLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    
    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
    
    notifyListeners();
  }
}

extension LocalizationExt on String {
  String tr(BuildContext context) {
    if (context.mounted == false) return this;
    try {
      final lang = Provider.of<LocalizationService>(context, listen: true).currentLanguage;
      return appTranslations[lang]?[this] ?? this;
    } catch (_) {
      return this;
    }
  }
}
