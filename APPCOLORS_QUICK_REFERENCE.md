# AppColors Quick Reference Guide

## Import Statement

```dart
import 'package:cementdeliverytracker/core/theme/app_colors.dart';
```

## Most Used Colors

### Backgrounds

| Use Case                | Color                           | Code    |
| ----------------------- | ------------------------------- | ------- |
| Main App Background     | `AppColors.background`          | White   |
| Section/Card Background | `AppColors.backgroundSecondary` | #F5F5F5 |
| Card Surface            | `AppColors.cardBackground`      | White   |

### Text

| Use Case           | Color                     | Code      |
| ------------------ | ------------------------- | --------- |
| Primary Text       | `AppColors.textPrimary`   | #1A1A1A   |
| Secondary Text     | `AppColors.textSecondary` | Black 54% |
| Hint/Disabled Text | `AppColors.textTertiary`  | Black 38% |
| Text on Primary    | `AppColors.textOnPrimary` | White     |

### Interactive

| Use Case         | Color                     | Code                |
| ---------------- | ------------------------- | ------------------- |
| Primary Action   | `AppColors.primary`       | #FF6F00 (Orange)    |
| Primary Light BG | `AppColors.primaryLight`  | #FF6F00 20% opacity |
| Selected Item    | `AppColors.primary`       | Orange              |
| Unselected Item  | `AppColors.textSecondary` | Black 54%           |

### Status

| Use Case | Color               | Code   |
| -------- | ------------------- | ------ |
| Success  | `AppColors.success` | Green  |
| Error    | `AppColors.error`   | Red    |
| Warning  | `AppColors.warning` | Orange |
| Info     | `AppColors.info`    | Blue   |

## Common Widget Patterns

### Scaffold

```dart
Scaffold(
  backgroundColor: AppColors.background,
)
```

### AppBar

```dart
AppBar(
  backgroundColor: AppColors.backgroundSecondary,
  titleTextStyle: TextStyle(color: AppColors.textPrimary),
)
```

### Card

```dart
Card(
  color: AppColors.cardBackground,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Content',
      style: TextStyle(color: AppColors.textPrimary),
    ),
  ),
)
```

### Button

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
  ),
  onPressed: () {},
  child: Text('Action'),
)
```

### Text Input

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Field Label',
    filled: true,
    fillColor: AppColors.inputBackground,
  ),
)
```

### Bottom Navigation

```dart
BottomNavigationBar(
  backgroundColor: AppColors.background,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  items: [...],
)
```

### Status Badge

```dart
Container(
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

### Icon with Background

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.primaryLight,
    shape: BoxShape.circle,
  ),
  child: Icon(
    Icons.check,
    color: AppColors.primary,
  ),
)
```

## Utility Methods

### Add Opacity

```dart
// 50% opacity
AppColors.withOpacity(AppColors.primary, 0.5)
```

### Darken Color

```dart
// 10% darker
AppColors.darken(AppColors.primary, 0.1)
```

### Lighten Color

```dart
// 10% lighter
AppColors.lighten(AppColors.primary, 0.1)
```

## Color Palette Overview

```
PRIMARY COLORS
├── AppColors.primary (#FF6F00) - Orange
├── AppColors.primaryLight (20% opacity)
└── AppColors.primaryLighter (#FFE0CC) - Light Orange

BACKGROUNDS
├── AppColors.background - White
├── AppColors.backgroundSecondary (#F5F5F5) - Light Gray
└── AppColors.cardBackground - White

TEXT HIERARCHY
├── AppColors.textPrimary (#1A1A1A) - Main
├── AppColors.textSecondary (Black 54%) - Secondary
├── AppColors.textTertiary (Black 38%) - Tertiary
└── AppColors.textOnPrimary (White) - On Primary

INPUT FIELDS
├── AppColors.inputBackground (#F5F5F5)
├── AppColors.inputLabel (Black 87%)
├── AppColors.inputHint (Black 38%)
└── AppColors.inputIcon (Black 54%)

SELECTION
├── AppColors.cursorColor (#FF6F00)
├── AppColors.selectionColor (#FFE0CC)
└── AppColors.selectionHandle (#FF6F00)

SEMANTIC
├── AppColors.success (Green)
├── AppColors.error (Red)
├── AppColors.warning (Orange)
└── AppColors.info (Blue)

NEUTRAL
├── AppColors.white
├── AppColors.black
├── AppColors.divider (Black 12%)
└── AppColors.surface (White)
```

## Don'ts ❌

- ❌ Don't use hardcoded colors: `Color(0xFFFF6F00)`
- ❌ Don't use generic Colors: `Colors.white`, `Colors.black`
- ❌ Don't repeat colors: `TextStyle(color: const Color(...))`
- ❌ Don't mix color systems: Some screens using AppColors, others using hardcoded

## Do's ✅

- ✅ Always import AppColors
- ✅ Use semantic color names
- ✅ Reuse constants across files
- ✅ Update COLOR_SYSTEM.md when adding new colors
- ✅ Test contrast ratios for accessibility
- ✅ Use utility methods for variations

## Converting Hardcoded Colors

### Orange Accent

```dart
// OLD ❌
Color(0xFFFF6F00)

// NEW ✅
AppColors.primary
```

### White Text

```dart
// OLD ❌
Colors.white

// NEW ✅
AppColors.textOnPrimary
AppColors.white (if pure white needed)
```

### Dark Backgrounds

```dart
// OLD ❌
Color(0xFF2C2C2C)
Color(0xFF1E1E1E)

// NEW ✅
AppColors.background
AppColors.backgroundSecondary
```

### Light Gray

```dart
// OLD ❌
Color(0xFFF5F5F5)

// NEW ✅
AppColors.backgroundSecondary
AppColors.inputBackground
```

## Support & Questions

Refer to `COLOR_SYSTEM.md` for:

- Detailed architecture
- Complete usage examples
- Migration guide
- Best practices
- Adding new colors

Contact: [Architecture Team]
