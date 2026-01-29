# Color & Theme System Documentation

## Overview

This document describes the centralized color and theme system for the Cement Delivery Tracker application. All color references should be managed through the `AppColors` class to ensure consistency and maintainability across the application.

## Architecture

### Single Source of Truth: `AppColors` Class

Located at: `lib/core/theme/app_colors.dart`

The `AppColors` class provides a centralized palette of all colors used in the application. This follows the industry standard Material Design approach and ensures:

1. **Consistency**: All screens use the same color definitions
2. **Maintainability**: Colors can be updated in one place
3. **Accessibility**: Easy to implement theming and dark mode support in the future
4. **Documentation**: Clear intent and naming for each color

### Theme Configuration: `AppTheme` Class

Located at: `lib/core/theme/app_theme.dart`

The `AppTheme` class defines Material Design theme configurations that leverage the centralized colors from `AppColors`. Currently implements:

- **Light Theme**: Default theme with white backgrounds and dark text
- **Dark Theme**: (Available for future expansion)

## Color Categories

### Primary & Accent Colors

```dart
// Brand Orange
AppColors.primary              // #FF6F00
AppColors.primaryLight         // #FF6F00 with 20% opacity
AppColors.primaryLighter       // #FFE0CC (light orange)
```

**Usage**: Primary action buttons, selected states, icons, highlights

### Background Colors

```dart
// Main backgrounds
AppColors.background           // Colors.white (main app background)
AppColors.backgroundSecondary  // #F5F5F5 (light gray for sections)
AppColors.cardBackground       // Colors.white (card surfaces)
```

**Usage**: Screen backgrounds, card backgrounds, container backgrounds

### Text Colors

```dart
// Text hierarchy
AppColors.textPrimary          // #1A1A1A (main body text)
AppColors.textSecondary        // Colors.black54 (secondary/hint text)
AppColors.textTertiary         // Colors.black38 (disabled/hint text)
AppColors.textOnPrimary        // Colors.white (text on primary color)
AppColors.textHint             // Colors.black38 (placeholder text)
AppColors.textDisabled         // Colors.black26 (disabled text)
```

**Usage**: Text styling based on importance and context

### Input Field Colors

```dart
// Form inputs
AppColors.inputBackground      // #F5F5F5 (input field fill)
AppColors.inputBorder          // Colors.black12 (input border)
AppColors.inputLabel           // Colors.black87 (label text)
AppColors.inputHint            // Colors.black38 (placeholder)
AppColors.inputIcon            // Colors.black54 (input icons)
```

**Usage**: TextFormField, TextField, input decorations

### Selection & Interaction Colors

```dart
// Text selection
AppColors.cursorColor          // #FF6F00 (cursor)
AppColors.selectionColor       // #FFE0CC (selected text background)
AppColors.selectionHandle      // #FF6F00 (selection handles)
```

**Usage**: Text selection styling

### Semantic Colors

```dart
// Status indicators
AppColors.success              // Colors.green
AppColors.successLight         // Green with 20% opacity
AppColors.error                // Colors.red
AppColors.errorLight           // Red with 20% opacity
AppColors.warning              // Colors.orange
AppColors.info                 // Colors.blue
AppColors.infoLight            // Blue with 20% opacity
```

**Usage**: Status badges, alerts, confirmations

### Neutral Colors

```dart
// Base colors
AppColors.white                // Colors.white
AppColors.black                // Colors.black
AppColors.blackOverlay         // Black with 53% opacity
AppColors.whiteOverlay         // White with 27% opacity
AppColors.divider              // Colors.black12 (border/divider)
AppColors.surface              // Colors.white (surface color)
```

**Usage**: Overlays, dividers, borders

## Usage Examples

### Screen Background

```dart
Scaffold(
  backgroundColor: AppColors.background,
  body: Column(
    children: [...]
  ),
)
```

### Cards

```dart
Card(
  color: AppColors.cardBackground,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Card Content',
      style: TextStyle(color: AppColors.textPrimary),
    ),
  ),
)
```

### Input Fields

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    labelStyle: TextStyle(color: AppColors.inputLabel),
    filled: true,
    fillColor: AppColors.inputBackground,
  ),
)
```

### Buttons

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
  ),
  onPressed: () {},
  child: Text('Save'),
)
```

### Status Indicators

```dart
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: AppColors.successLight,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'Success',
    style: TextStyle(color: AppColors.success),
  ),
)
```

### Bottom Navigation Bar

```dart
BottomNavigationBar(
  backgroundColor: AppColors.background,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  items: [...]
)
```

### AppBar

```dart
AppBar(
  backgroundColor: AppColors.backgroundSecondary,
  titleTextStyle: TextStyle(color: AppColors.textPrimary),
  elevation: 0,
)
```

## Utility Methods

The `AppColors` class provides helper methods for color manipulation:

### `withOpacity(Color, double)`

Add opacity to a color:

```dart
Container(
  color: AppColors.withOpacity(AppColors.primary, 0.5),
)
```

### `darken(Color, double)`

Create a darker variant:

```dart
Container(
  color: AppColors.darken(AppColors.primary, 0.1),
)
```

### `lighten(Color, double)`

Create a lighter variant:

```dart
Container(
  color: AppColors.lighten(AppColors.primary, 0.1),
)
```

## Deprecation Notice

The following hardcoded colors have been deprecated and should be replaced with `AppColors`:

| Old Color           | New Color                           | Type            |
| ------------------- | ----------------------------------- | --------------- |
| `Color(0xFFFF6F00)` | `AppColors.primary`                 | Constant        |
| `Color(0xFF2C2C2C)` | `AppColors.backgroundDark`          | Constant        |
| `Color(0xFF1E1E1E)` | `AppColors.backgroundDarkSecondary` | Constant        |
| `Colors.white`      | `AppColors.textOnPrimary`           | Text on primary |
| `Colors.white`      | `AppColors.white`                   | Pure white      |

## Migration Guide

When working on existing code that uses hardcoded colors:

### Before

```dart
Container(
  color: const Color(0xFFFF6F00),
  child: Text(
    'Button',
    style: TextStyle(color: Colors.white),
  ),
)
```

### After

```dart
Container(
  color: AppColors.primary,
  child: Text(
    'Button',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)
```

## Best Practices

1. **Always use `AppColors`** instead of hardcoded color values
2. **Import `AppColors`** at the top of files that use colors:
   ```dart
   import 'package:cementdeliverytracker/core/theme/app_colors.dart';
   ```
3. **Use semantic color names** when possible (e.g., `AppColors.primary` instead of arbitrary color values)
4. **Maintain contrast ratios** for accessibility (minimum 4.5:1 for text)
5. **Group related colors** using Material Design principles
6. **Document custom color logic** if using opacity or manipulation

## Adding New Colors

If a new color is needed:

1. **Determine the category**: Is it a background, text, semantic, or accent color?
2. **Add to `AppColors` class** with a clear, descriptive name
3. **Update this documentation**
4. **Use the new constant** throughout the codebase

Example:

```dart
// In app_colors.dart
static const Color accentBlue = Color(0xFF0066CC);

// In your code
Container(
  color: AppColors.accentBlue,
)
```

## Testing Colors

To verify color consistency across the application:

1. Check that all screens use `AppColors` instead of hardcoded values
2. Use Flutter's color picker to verify HEX values match documentation
3. Test contrast ratios for accessibility compliance
4. Preview on light and dark backgrounds

## Related Documentation

- Material Design Color System: https://material.io/design/color/
- WCAG Contrast Requirements: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
- Flutter Material Theme: https://api.flutter.dev/flutter/material/ThemeData-class.html
