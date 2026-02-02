/// Settings Provider - Layer 0
/// 
/// Manages user preferences and app settings.
/// No dependencies on other providers (bottom of hierarchy).
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit types for speed measurement
enum SpeedUnit {
  /// Knots (nautical miles per hour)
  knots,
  
  /// Kilometers per hour
  kph,
  
  /// Miles per hour
  mph,
}

/// Unit types for distance measurement
enum DistanceUnit {
  /// Nautical miles
  nauticalMiles,
  
  /// Kilometers
  kilometers,
  
  /// Miles
  miles,
}

/// Settings Provider - Manages user preferences
/// 
/// Layer 0 provider with no dependencies.
/// Persists settings to SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  // ============ Private Fields ============
  
  SharedPreferences? _prefs;
  SpeedUnit _speedUnit = SpeedUnit.knots;
  DistanceUnit _distanceUnit = DistanceUnit.nauticalMiles;
  String _language = 'en';
  int _mapRefreshRate = 5000; // milliseconds
  
  // ============ Public Getters ============
  
  /// Current speed unit preference
  SpeedUnit get speedUnit => _speedUnit;
  
  /// Current distance unit preference
  DistanceUnit get distanceUnit => _distanceUnit;
  
  /// Current language code
  String get language => _language;
  
  /// Map refresh rate in milliseconds
  int get mapRefreshRate => _mapRefreshRate;
  
  /// Check if settings are initialized
  bool get isInitialized => _prefs != null;
  
  // ============ Initialization ============
  
  /// Initialize and load settings from storage
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
    } catch (e) {
      debugPrint('SettingsProvider: Failed to init - $e');
      // Continue with defaults
    }
  }
  
  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    try {
      final speedUnitIndex = _prefs!.getInt('speedUnit');
      if (speedUnitIndex != null) {
        _speedUnit = SpeedUnit.values[speedUnitIndex];
      }
      
      final distanceUnitIndex = _prefs!.getInt('distanceUnit');
      if (distanceUnitIndex != null) {
        _distanceUnit = DistanceUnit.values[distanceUnitIndex];
      }
      
      _language = _prefs!.getString('language') ?? 'en';
      _mapRefreshRate = _prefs!.getInt('mapRefreshRate') ?? 5000;
      
      notifyListeners();
    } catch (e) {
      debugPrint('SettingsProvider: Failed to load settings - $e');
    }
  }
  
  // ============ Setters ============
  
  /// Update speed unit preference
  Future<void> setSpeedUnit(SpeedUnit unit) async {
    _speedUnit = unit;
    await _prefs?.setInt('speedUnit', unit.index);
    notifyListeners();
  }
  
  /// Update distance unit preference
  Future<void> setDistanceUnit(DistanceUnit unit) async {
    _distanceUnit = unit;
    await _prefs?.setInt('distanceUnit', unit.index);
    notifyListeners();
  }
  
  /// Update language preference
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs?.setString('language', lang);
    notifyListeners();
  }
  
  /// Update map refresh rate
  Future<void> setMapRefreshRate(int milliseconds) async {
    _mapRefreshRate = milliseconds;
    await _prefs?.setInt('mapRefreshRate', milliseconds);
    notifyListeners();
  }
  
  // ============ Utility Methods ============
  
  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _speedUnit = SpeedUnit.knots;
    _distanceUnit = DistanceUnit.nauticalMiles;
    _language = 'en';
    _mapRefreshRate = 5000;
    
    await _prefs?.clear();
    notifyListeners();
  }
}
