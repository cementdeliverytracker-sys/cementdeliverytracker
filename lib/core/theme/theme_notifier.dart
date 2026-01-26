import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkTheme = true;
  static const String _themeKey = 'isDarkTheme';

  bool get isDarkTheme => _isDarkTheme;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners(); // Update UI immediately

    // Save to preferences in background
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkTheme);
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkTheme == isDark) return; // No change needed

    _isDarkTheme = isDark;
    notifyListeners(); // Update UI immediately

    // Save to preferences in background
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkTheme);
  }
}
