import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF6F00),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1C1C1C),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6F00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
