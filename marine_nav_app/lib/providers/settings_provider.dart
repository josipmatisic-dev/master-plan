/// Settings Provider - Layer 0. Manages user preferences and app settings.
/// No dependencies on other providers (bottom of hierarchy).
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart' as env;
import '../models/nmea_error.dart' show ConnectionType;

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

/// Unit types for depth measurement
enum DepthUnit {
  /// Meters
  meters,

  /// Feet
  feet,

  /// Fathoms
  fathoms,
}

/// Settings Provider - Manages user preferences
///
/// Layer 0 provider with no dependencies.
/// Persists settings to SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  SpeedUnit _speedUnit = SpeedUnit.knots;
  DistanceUnit _distanceUnit = DistanceUnit.nauticalMiles;
  DepthUnit _depthUnit = DepthUnit.meters;
  String _language = 'en';
  int _mapRefreshRate = 5000;
  bool _showCompass = true;
  bool _showDataOrbs = true;
  bool _showSpeedArc = true;
  bool _showWaveAnimation = true;
  String _nmeaHost = 'localhost';
  int _nmeaPort = 10110;
  ConnectionType _nmeaConnectionType = ConnectionType.tcp;
  bool _autoConnectNMEA = false;
  String _mapTilerApiKey = '';
  String _aisStreamApiKey = '';

  // ============ Getters ============

  SpeedUnit get speedUnit => _speedUnit;
  DistanceUnit get distanceUnit => _distanceUnit;
  DepthUnit get depthUnit => _depthUnit;
  bool get showCompass => _showCompass;
  bool get showDataOrbs => _showDataOrbs;
  bool get showSpeedArc => _showSpeedArc;
  bool get showWaveAnimation => _showWaveAnimation;
  String get language => _language;
  int get mapRefreshRate => _mapRefreshRate;
  String get nmeaHost => _nmeaHost;
  int get nmeaPort => _nmeaPort;
  ConnectionType get nmeaConnectionType => _nmeaConnectionType;
  bool get autoConnectNMEA => _autoConnectNMEA;
  String get mapTilerApiKey => _mapTilerApiKey;
  bool get hasMapTilerApiKey => _mapTilerApiKey.isNotEmpty;
  String get aisStreamApiKey => _aisStreamApiKey;
  bool get hasAisStreamApiKey => _aisStreamApiKey.isNotEmpty;
  bool get isInitialized => _prefs != null;

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

      final depthUnitIndex = _prefs!.getInt('depthUnit');
      if (depthUnitIndex != null) {
        _depthUnit = DepthUnit.values[depthUnitIndex];
      }

      _showCompass = _prefs!.getBool('display_showCompass') ?? true;
      _showDataOrbs = _prefs!.getBool('display_showDataOrbs') ?? true;
      _showSpeedArc = _prefs!.getBool('display_showSpeedArc') ?? true;
      _showWaveAnimation = _prefs!.getBool('display_showWaveAnimation') ?? true;

      _language = _prefs!.getString('language') ?? 'en';
      _mapRefreshRate = _prefs!.getInt('mapRefreshRate') ?? 5000;

      // NMEA settings
      _nmeaHost = _prefs!.getString('nmeaHost') ?? 'localhost';
      _nmeaPort = _prefs!.getInt('nmeaPort') ?? 10110;

      final nmeaConnectionTypeIndex = _prefs!.getInt('nmeaConnectionType');
      if (nmeaConnectionTypeIndex != null) {
        _nmeaConnectionType = ConnectionType.values[nmeaConnectionTypeIndex];
      }

      _autoConnectNMEA = _prefs!.getBool('autoConnectNMEA') ?? false;

      // Map settings
      _mapTilerApiKey = _prefs!.getString('mapTilerApiKey') ?? '';

      // Auto-load API key from env config if not yet persisted
      if (_mapTilerApiKey.isEmpty && env.mapTilerApiKey.isNotEmpty) {
        _mapTilerApiKey = env.mapTilerApiKey;
        await _prefs!.setString('mapTilerApiKey', _mapTilerApiKey);
      }

      // AIS settings
      _aisStreamApiKey = _prefs!.getString('aisStreamApiKey') ?? '';
      if (_aisStreamApiKey.isEmpty && env.aisStreamApiKey.isNotEmpty) {
        _aisStreamApiKey = env.aisStreamApiKey;
        await _prefs!.setString('aisStreamApiKey', _aisStreamApiKey);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('SettingsProvider: Failed to load settings - $e');
    }
  }

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

  /// Update depth unit preference
  Future<void> setDepthUnit(DepthUnit unit) async {
    _depthUnit = unit;
    await _prefs?.setInt('depthUnit', unit.index);
    notifyListeners();
  }

  /// Update show compass preference
  Future<void> setShowCompass(bool value) async {
    _showCompass = value;
    await _prefs?.setBool('display_showCompass', value);
    notifyListeners();
  }

  /// Update show data orbs preference
  Future<void> setShowDataOrbs(bool value) async {
    _showDataOrbs = value;
    await _prefs?.setBool('display_showDataOrbs', value);
    notifyListeners();
  }

  /// Update show speed arc preference
  Future<void> setShowSpeedArc(bool value) async {
    _showSpeedArc = value;
    await _prefs?.setBool('display_showSpeedArc', value);
    notifyListeners();
  }

  /// Update show wave animation preference
  Future<void> setShowWaveAnimation(bool value) async {
    _showWaveAnimation = value;
    await _prefs?.setBool('display_showWaveAnimation', value);
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

  /// Update NMEA host address
  Future<void> setNMEAHost(String host) async {
    _nmeaHost = host;
    await _prefs?.setString('nmeaHost', host);
    notifyListeners();
  }

  /// Update NMEA port number
  Future<void> setNMEAPort(int port) async {
    if (port < 1 || port > 65535) {
      throw ArgumentError('Port must be between 1 and 65535');
    }
    _nmeaPort = port;
    await _prefs?.setInt('nmeaPort', port);
    notifyListeners();
  }

  /// Update NMEA connection type
  Future<void> setNMEAConnectionType(ConnectionType type) async {
    _nmeaConnectionType = type;
    await _prefs?.setInt('nmeaConnectionType', type.index);
    notifyListeners();
  }

  /// Update auto-connect NMEA preference
  Future<void> setAutoConnectNMEA(bool autoConnect) async {
    _autoConnectNMEA = autoConnect;
    await _prefs?.setBool('autoConnectNMEA', autoConnect);
    notifyListeners();
  }

  /// Update MapTiler API key
  Future<void> setMapTilerApiKey(String key) async {
    _mapTilerApiKey = key;
    await _prefs?.setString('mapTilerApiKey', key);
    notifyListeners();
  }

  /// Update AISStream.io API key
  Future<void> setAisStreamApiKey(String key) async {
    _aisStreamApiKey = key;
    await _prefs?.setString('aisStreamApiKey', key);
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _speedUnit = SpeedUnit.knots;
    _distanceUnit = DistanceUnit.nauticalMiles;
    _depthUnit = DepthUnit.meters;
    _language = 'en';
    _mapRefreshRate = 5000;
    _nmeaHost = 'localhost';
    _nmeaPort = 10110;
    _nmeaConnectionType = ConnectionType.tcp;
    _autoConnectNMEA = false;
    _mapTilerApiKey = '';
    _aisStreamApiKey = '';
    _showCompass = _showDataOrbs = _showSpeedArc = _showWaveAnimation = true;
    await _prefs?.clear();
    notifyListeners();
  }
}
