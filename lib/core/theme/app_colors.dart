import 'package:flutter/material.dart';

/// Centralized color palette for the entire application following Material Design guidelines.
/// This ensures consistency across all screens and components.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // PRIMARY & ACCENT COLORS
  // ============================================================================

  /// Primary brand color - Orange
  static const Color primary = Color(0xFFFF6F00);

  /// Text/icon color on primary backgrounds - White (alias for textOnPrimary)
  static const Color onPrimary = Colors.white;

  /// Primary color with 20% opacity
  static const Color primaryLight = Color(0x33FF6F00);

  /// Primary color with light variant
  static const Color primaryLighter = Color(0xFFFFE0CC);

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  /// Main app background - White
  static const Color background = Colors.white;

  /// Secondary background - Light gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  /// Card background - White
  static const Color cardBackground = Colors.white;

  /// Dark deprecated background (for migration)
  static const Color backgroundDark = Color(0xFF2C2C2C);
  static const Color backgroundDarkSecondary = Color(0xFF1E1E1E);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text color - Dark gray/black
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Secondary text color - Medium gray
  static const Color textSecondary = Colors.black54;

  /// Tertiary text color - Light gray
  static const Color textTertiary = Colors.black38;

  /// Text on primary color - White
  static const Color textOnPrimary = Colors.white;

  /// Hint/Label text color
  static const Color textHint = Colors.black38;

  /// Disabled text color
  static const Color textDisabled = Colors.black26;

  // ============================================================================
  // INPUT FIELD COLORS
  // ============================================================================

  /// Input field background - Light gray
  static const Color inputBackground = Color(0xFFF5F5F5);

  /// Input field border - Very light gray
  static const Color inputBorder = Colors.black12;

  /// General border color (alias for inputBorder)
  static const Color border = Colors.black12;

  /// Input field label text
  static const Color inputLabel = Colors.black87;

  /// Input field hint text
  static const Color inputHint = Colors.black38;

  /// Input field icon color
  static const Color inputIcon = Colors.black54;

  // ============================================================================
  // SELECTION & INTERACTION COLORS
  // ============================================================================

  /// Text selection cursor color
  static const Color cursorColor = Color(0xFFFF6F00);

  /// Text selection background color
  static const Color selectionColor = Color(0xFFFFE0CC);

  /// Text selection handle color
  static const Color selectionHandle = Color(0xFFFF6F00);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success/Positive color - Green
  static const Color success = Colors.green;

  /// Success color light variant
  static const Color successLight = Color(0x20008000);

  /// Error/Negative color - Red
  static const Color error = Colors.red;

  /// Error color light variant
  static const Color errorLight = Color(0x20FF0000);

  /// Warning color - Orange/Amber
  static const Color warning = Colors.orange;

  /// Info/Informational color - Blue
  static const Color info = Colors.blue;

  /// Info color light variant
  static const Color infoLight = Color(0x200000FF);

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================

  /// Pure white
  static const Color white = Colors.white;

  /// Pure black
  static const Color black = Colors.black;

  /// Black with reduced opacity
  static const Color blackOverlay = Color(0x88000000);

  /// White with reduced opacity
  static const Color whiteOverlay = Color(0x44FFFFFF);

  /// Divider/Border color
  static const Color divider = Colors.black12;

  /// Neutral grey color
  static const Color neutral = Colors.grey;

  /// Surface color for cards and elevated widgets
  static const Color surface = Colors.white;

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Dark theme - Primary background (Dark grey)
  static const Color darkBackground = Color(0xFF1A1A1A);

  /// Dark theme - Secondary background (Slightly lighter grey)
  static const Color darkBackgroundSecondary = Color(0xFF2C2C2C);

  /// Dark theme - Card background (Medium grey)
  static const Color darkCardBackground = Color(0xFF2C2C2C);

  /// Dark theme - Primary text color (Light grey/white)
  static const Color darkTextPrimary = Color(0xFFE0E0E0);

  /// Dark theme - Secondary text color (Medium grey)
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  /// Dark theme - Tertiary text color (Dimmed grey)
  static const Color darkTextTertiary = Color(0xFF808080);

  /// Dark theme - Input field background (Lighter than card)
  static const Color darkInputBackground = Color(0xFF3A3A3A);

  /// Dark theme - Input field border (Lighter grey)
  static const Color darkInputBorder = Color(0xFF4A4A4A);

  /// Dark theme - Divider color (Subtle grey)
  static const Color darkDivider = Color(0xFF3A3A3A);

  /// Dark theme - Surface color
  static const Color darkSurface = Color(0xFF2C2C2C);

  // ============================================================================
  // SHADOW & ELEVATION COLORS
  // ============================================================================

  /// Shadow color for elevation
  static const Color shadow = Color(0x1F000000);

  // ============================================================================
  // DEPRECATED COLORS (For reference during migration)
  // ============================================================================

  @Deprecated('Use AppColors.primary instead')
  static const Color orangePrimary = Color(0xFFFF6F00);

  @Deprecated('Use AppColors.backgroundDark instead')
  static const Color darkBg1 = Color(0xFF2C2C2C);

  @Deprecated('Use AppColors.backgroundDarkSecondary instead')
  static const Color darkBg2 = Color(0xFF1E1E1E);

  @Deprecated('Use AppColors.textOnPrimary instead')
  static const Color whiteText = Colors.white;

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get opacity variant of a color
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha:  opacity);
  }

  /// Get a darker variant of a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  /// Get a lighter variant of a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }
}
