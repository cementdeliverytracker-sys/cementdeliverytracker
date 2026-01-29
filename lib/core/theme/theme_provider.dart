import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages theme switching and persistence across app sessions.
/// Supports three modes: system, light, and dark.
/// All widgets will automatically rebuild when theme changes via Consumer<ThemeProvider>.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _useSystemKey = 'use_system_theme';

  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystem = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get useSystemTheme => _useSystem;

  /// Load saved theme preference from local storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useSystem = prefs.getBool(_useSystemKey) ?? true;

      if (_useSystem) {
        _themeMode = ThemeMode.system;
      } else {
        final isDark = prefs.getBool(_themeKey) ?? false;
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
      notifyListeners();
    } catch (e) {
      // If loading fails, keep default system theme
      _themeMode = ThemeMode.system;
      _useSystem = true;
    }
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    _useSystem = false;
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useSystemKey, false);
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Set a specific theme mode (light, dark, or system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    _useSystem = mode == ThemeMode.system;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useSystemKey, _useSystem);
      if (mode != ThemeMode.system) {
        await prefs.setBool(_themeKey, mode == ThemeMode.dark);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Use system theme preference
  Future<void> useSystemThemeMode() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Force light theme
  Future<void> useLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Force dark theme
  Future<void> useDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
}
