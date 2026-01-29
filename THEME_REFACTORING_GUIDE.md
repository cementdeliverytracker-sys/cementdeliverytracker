# Theme Refactoring Guide

## Architecture Overview

The app now uses a modern Material 3 theme architecture:

1. **AppColors** - Centralized color definitions for semantic meaning
2. **AppTheme** - Converts AppColors into ThemeData with ColorScheme and TextTheme
3. **ThemeProvider** - Manages theme switching and persistence
4. **Theme.of(context)** - Used in widgets to access theme colors dynamically

## Migration Pattern

### ❌ Old Pattern (Static AppColors)

```dart
Text(
  'Hello',
  style: TextStyle(color: AppColors.textPrimary),
)
Container(
  color: AppColors.cardBackground,
  child: Text('Content'),
)
```

### ✅ New Pattern (Theme-aware)

```dart
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyMedium,
)
Container(
  color: Theme.of(context).cardColor,
  child: Text('Content'),
)
```

## Key Replacements

### Text Styles

- `AppColors.textPrimary` → `Theme.of(context).textTheme.bodyMedium` or `bodyLarge`
- `AppColors.textSecondary` → `Theme.of(context).textTheme.bodySmall`
- `AppColors.textTertiary` → Use colorScheme.onSurface with opacity
- `AppColors.darkTextPrimary` → Handled automatically by TextTheme
- `AppColors.textOnPrimary` → `Theme.of(context).textTheme.labelLarge`

### Backgrounds & Colors

- `AppColors.background` → `Theme.of(context).scaffoldBackgroundColor`
- `AppColors.cardBackground` → `Theme.of(context).cardColor`
- `AppColors.darkCardBackground` → Handled by cardColor in dark theme
- `AppColors.backgroundSecondary` → `Theme.of(context).colorScheme.surface`
- `AppColors.divider` → `Theme.of(context).dividerColor`

### Input Fields

- Backgrounds handled by InputDecorationTheme
- No need to manually set fillColor or labelStyle
- Use standard TextField/TextFormField

### Buttons

- All button styles handled by ThemeData
- No custom AppColors needed for button colors

## Implementation Steps

1. Use Theme.of(context) wherever possible
2. Remove hardcoded AppColors from widget builds
3. Test light and dark themes after each file
4. For custom colors, use ColorScheme extension properties
5. Keep AppColors only for semantic app-specific colors (primary, success, error, etc.)

## Testing Theme Switching

```dart
// In settings or any screen:
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: themeProvider.toggleTheme,
          child: Text('Toggle Theme'),
        ),
        Text('Current Mode: ${themeProvider.themeMode}'),
      ],
    );
  },
)
```

All widgets will automatically rebuild when theme changes via Consumer/Provider.
