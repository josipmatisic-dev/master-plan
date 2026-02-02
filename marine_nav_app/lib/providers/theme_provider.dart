/// Theme Provider - Layer 1
/// 
/// Manages theme mode (dark/light/system) and provides ThemeData.
/// Depends on SettingsProvider (Layer 0).
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

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
  
  // ============ Public Getters ============
  
  /// Current theme mode
  AppThemeMode get themeMode => _themeMode;
  
  /// Get ThemeData for current theme mode
  ThemeData getTheme(Brightness systemBrightness) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      
      case AppThemeMode.dark:
      case AppThemeMode.redLight:
        return AppTheme.darkTheme;
      
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
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
  
  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    if (_prefs == null) return;
    
    try {
      final themeModeIndex = _prefs!.getInt('themeMode');
      if (themeModeIndex != null) {
        _themeMode = AppThemeMode.values[themeModeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ThemeProvider: Failed to load theme mode - $e');
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
}
