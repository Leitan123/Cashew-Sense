import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_themeKey) ?? false; // Light mode by default
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    if (_isDark == dark) return;
    _isDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, dark);
    notifyListeners();
  }
}
