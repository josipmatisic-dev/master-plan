/// Theme Provider - Layer 1
///
/// Manages theme mode (dark/light/system) and theme variant (Ocean Glass/Holographic).
/// Depends on SettingsProvider (Layer 0).
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/theme_variant.dart';

/// Theme mode options
enum AppThemeMode {
  /// Light theme for daytime
  light,

  /// Dark theme for night navigation (primary)
  dark,

  /// Follow system theme
  system,

  /// Red light mode for night vision preservation
  redLight,
}

/// Theme Provider - Manages app theme and appearance
///
/// Layer 1 provider. Can depend on SettingsProvider (Layer 0).
/// Persists theme preference and provides ThemeData to app.
class ThemeProvider extends ChangeNotifier {
  // ============ Private Fields ============

  SharedPreferences? _prefs;
  AppThemeMode _themeMode = AppThemeMode.dark; // Dark mode first
  ThemeVariant _themeVariant = ThemeVariant.oceanGlass; // Ocean Glass default

  // ============ Public Getters ============

  /// Current theme mode
  AppThemeMode get themeMode => _themeMode;

  /// Current theme variant
  ThemeVariant get themeVariant => _themeVariant;

  /// Get ThemeData for current theme mode and variant
  ThemeData getTheme(Brightness systemBrightness) {
    // Determine if should use dark or light theme
    final bool useDark = _shouldUseDark(systemBrightness);

    // Get theme for current variant
    return AppTheme.getThemeForVariant(useDark, _themeVariant);
  }

  /// Helper: Determine if dark theme should be used
  bool _shouldUseDark(Brightness systemBrightness) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
      case AppThemeMode.redLight:
        return true;
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark;
    }
  }

  /// Check if currently in dark mode
  bool isDark(Brightness systemBrightness) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
      case AppThemeMode.redLight:
        return true;
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark;
    }
  }

  /// Check if red light mode is active
  bool get isRedLightMode => _themeMode == AppThemeMode.redLight;

  // ============ Initialization ============

  /// Initialize and load theme preference
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemeMode();
    } catch (e) {
      debugPrint('ThemeProvider: Failed to init - $e');
      // Continue with dark mode default
    }
  }

  /// Load theme mode and variant from SharedPreferences
  Future<void> _loadThemeMode() async {
    if (_prefs == null) return;

    try {
      // Load theme mode (backward compatible with index-based storage)
      final themeModeIndex = _prefs!.getInt('themeMode');
      if (themeModeIndex != null &&
          themeModeIndex < AppThemeMode.values.length) {
        _themeMode = AppThemeMode.values[themeModeIndex];
      }

      // Load theme variant (string-based for stability)
      final themeVariantKey = _prefs!.getString('themeVariant');
      if (themeVariantKey != null) {
        _themeVariant = ThemeVariantExtension.fromPersistenceKey(
          themeVariantKey,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ThemeProvider: Failed to load theme preferences - $e');
    }
  }

  // ============ Theme Mode Management ============

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt('themeMode', mode.index);
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Enable red light mode for night vision
  Future<void> enableRedLightMode() async {
    await setThemeMode(AppThemeMode.redLight);
  }

  /// Disable red light mode (return to dark)
  Future<void> disableRedLightMode() async {
    await setThemeMode(AppThemeMode.dark);
  }

  // ============ Theme Variant Management ============

  /// Set theme variant with animated transition
  Future<void> setThemeVariant(ThemeVariant variant) async {
    if (_themeVariant == variant) return;

    _themeVariant = variant;
    await _prefs?.setString('themeVariant', variant.persistenceKey);
    notifyListeners();
  }

  /// Toggle between Ocean Glass and Holographic themes
  Future<void> toggleThemeVariant() async {
    final newVariant = _themeVariant == ThemeVariant.oceanGlass
        ? ThemeVariant.holographicCyberpunk
        : ThemeVariant.oceanGlass;
    await setThemeVariant(newVariant);
  }

  /// Check if current variant is Ocean Glass
  bool get isOceanGlass => _themeVariant == ThemeVariant.oceanGlass;

  /// Check if current variant is Holographic Cyberpunk
  bool get isHolographic => _themeVariant == ThemeVariant.holographicCyberpunk;
}
