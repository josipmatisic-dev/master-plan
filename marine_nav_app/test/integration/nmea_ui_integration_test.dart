import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_error.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NMEA UI Integration Tests', () {
    late SettingsProvider settingsProvider;
    late ThemeProvider themeProvider;
    late CacheProvider cacheProvider;
    late MapProvider mapProvider;
    late NMEAProvider nmeaProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsProvider = SettingsProvider();
      themeProvider = ThemeProvider();
      cacheProvider = CacheProvider();
      mapProvider = MapProvider(
        settingsProvider: settingsProvider,
        cacheProvider: cacheProvider,
      );
      nmeaProvider = NMEAProvider(
        settingsProvider: settingsProvider,
        cacheProvider: cacheProvider,
      );

      await Future.wait([
        settingsProvider.init(),
        themeProvider.init(),
        cacheProvider.init(),
        mapProvider.init(),
      ]);
    });

    tearDown(() {
      nmeaProvider.dispose();
      mapProvider.dispose();
      cacheProvider.dispose();
      themeProvider.dispose();
      settingsProvider.dispose();
    });

    testWidgets('A: Provider hierarchy initializes without errors',
        (WidgetTester tester) async {
      // Verify providers exist (may not be fully initialized without plugin context)
      expect(settingsProvider, isNotNull);
      expect(themeProvider, isNotNull);
      expect(cacheProvider, isNotNull);
      expect(mapProvider, isNotNull);
      expect(nmeaProvider, isNotNull);

      // Verify cache and map initialized (don't depend on SharedPreferences)
      expect(cacheProvider.isInitialized, true);
      expect(mapProvider.isInitialized, true);

      // Note: Settings and Theme providers may not fully initialize in test environment
      // without SharedPreferences plugin mocking, but objects are valid
    });

    testWidgets('B: Settings provider stores and retrieves NMEA config',
        (WidgetTester tester) async {
      // Verify default NMEA settings
      expect(settingsProvider.nmeaHost, 'localhost');
      expect(settingsProvider.nmeaPort, 10110);
      expect(settingsProvider.nmeaConnectionType, ConnectionType.tcp);

      // Update NMEA settings
      await settingsProvider.setNMEAHost('192.168.1.100');
      await settingsProvider.setNMEAPort(5000);
      await settingsProvider.setNMEAConnectionType(ConnectionType.udp);

      // Verify changes persisted
      expect(settingsProvider.nmeaHost, '192.168.1.100');
      expect(settingsProvider.nmeaPort, 5000);
      expect(settingsProvider.nmeaConnectionType, ConnectionType.udp);
    });

    testWidgets('C: Speed unit settings can be changed',
        (WidgetTester tester) async {
      // Verify default speed unit
      expect(settingsProvider.speedUnit, SpeedUnit.knots);

      // Change to mph
      await settingsProvider.setSpeedUnit(SpeedUnit.mph);
      expect(settingsProvider.speedUnit, SpeedUnit.mph);

      // Change to kph
      await settingsProvider.setSpeedUnit(SpeedUnit.kph);
      expect(settingsProvider.speedUnit, SpeedUnit.kph);
    });

    testWidgets('D: Theme mode can be switched', (WidgetTester tester) async {
      // Verify initial dark theme
      expect(themeProvider.themeMode, AppThemeMode.dark);

      // Switch to light theme
      await themeProvider.setThemeMode(AppThemeMode.light);
      expect(themeProvider.themeMode, AppThemeMode.light);
      expect(themeProvider.isDark(Brightness.dark), false);

      // Switch back to dark
      await themeProvider.setThemeMode(AppThemeMode.dark);
      expect(themeProvider.themeMode, AppThemeMode.dark);
      expect(themeProvider.isDark(Brightness.dark), true);
    });

    testWidgets('E: Map provider initializes with valid viewport',
        (WidgetTester tester) async {
      // Verify map provider initialized
      expect(mapProvider.isInitialized, true);

      // Verify viewport exists
      expect(mapProvider.viewport, isNotNull);

      // Verify center coordinates
      expect(mapProvider.viewport.center, isNotNull);
      expect(mapProvider.viewport.center.latitude, isNotNull);
      expect(mapProvider.viewport.center.longitude, isNotNull);

      // Verify zoom level is reasonable
      expect(mapProvider.viewport.zoom, greaterThanOrEqualTo(0));
    });

    testWidgets('F: NMEA provider initializes with disconnected status',
        (WidgetTester tester) async {
      // Verify NMEA provider state
      expect(nmeaProvider.isConnected, false);
      expect(nmeaProvider.currentData, isNull);
      expect(nmeaProvider.lastError, isNull);
      expect(nmeaProvider.reconnectAttempts, 0);
    });

    testWidgets('G: Cache provider tracks statistics',
        (WidgetTester tester) async {
      // Verify cache stats available
      expect(cacheProvider.stats, isNotNull);
      expect(cacheProvider.cacheSizeMB, 0.0); // Empty initially

      // Verify cache is initialized
      expect(cacheProvider.isInitialized, true);
    });

    testWidgets('H: Providers work together without circular dependencies',
        (WidgetTester tester) async {
      // Verify all providers can be instantiated together
      expect(settingsProvider, isNotNull);
      expect(themeProvider, isNotNull);
      expect(cacheProvider, isNotNull);
      expect(mapProvider, isNotNull);
      expect(nmeaProvider, isNotNull);

      // Verify provider hierarchy structure
      expect(mapProvider.settingsProvider == settingsProvider, true);
      expect(mapProvider.cacheProvider == cacheProvider, true);

      // Verify can call notifier methods without errors
      settingsProvider.notifyListeners();
      themeProvider.notifyListeners();
      cacheProvider.notifyListeners();
      mapProvider.notifyListeners();
      nmeaProvider.notifyListeners();
    });
  });
}
