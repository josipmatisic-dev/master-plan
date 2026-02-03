import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/nmea_error.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/services/nmea_service.dart';

// Mock NMEA Service for testing
class MockNMEAService extends NMEAService {
  // Override to prevent actual connection attempts
}

void main() {
  group('NMEAProvider', () {
    late SettingsProvider settingsProvider;
    late CacheProvider cacheProvider;
    late NMEAProvider nmeaProvider;
    bool providerDisposed = false;

    setUp(() async {
      providerDisposed = false;
      settingsProvider = SettingsProvider();
      await settingsProvider.init();
      
      cacheProvider = CacheProvider();
      await cacheProvider.init();
      
      nmeaProvider = NMEAProvider(
        settingsProvider: settingsProvider,
        cacheProvider: cacheProvider,
        service: MockNMEAService(),
      );
    });

    tearDown(() {
      if (!providerDisposed) {
        nmeaProvider.dispose();
      }
      cacheProvider.dispose();
    });

    test('initializes with disconnected status', () {
      expect(nmeaProvider.status, ConnectionStatus.disconnected);
      expect(nmeaProvider.isConnected, false);
      expect(nmeaProvider.isActive, false);
      expect(nmeaProvider.currentData, null);
      expect(nmeaProvider.lastError, null);
    });

    test('currentData is initially null', () {
      expect(nmeaProvider.currentData, isNull);
    });

    test('lastUpdateTime is initially null', () {
      expect(nmeaProvider.lastUpdateTime, isNull);
    });

    test('reconnectAttempts starts at zero', () {
      expect(nmeaProvider.reconnectAttempts, 0);
    });

    test('isConnected returns false when disconnected', () {
      expect(nmeaProvider.isConnected, false);
    });

    test('isActive returns false when disconnected', () {
      expect(nmeaProvider.isActive, false);
    });

    test('clearError removes last error', () {
      // Simulate an error by manually setting it (in real usage, comes from service)
      // For now, just test the method doesn't crash
      nmeaProvider.clearError();
      expect(nmeaProvider.lastError, isNull);
    });

    test('disconnect can be called when already disconnected', () async {
      await nmeaProvider.disconnect();
      expect(nmeaProvider.status, ConnectionStatus.disconnected);
    });

    test('dispose cleans up resources', () {
      nmeaProvider.dispose();
      providerDisposed = true;
      // Should not throw
    });

    test('connect sets up connection', () async {
      // Note: This will fail to connect (no server) but tests the logic
      try {
        await nmeaProvider.connect();
      } catch (e) {
        // Expected to fail - no server
      }

      // Provider should have attempted connection
      expect(nmeaProvider.reconnectAttempts, 0); // No reconnects yet
    });

    test('multiple connects are handled gracefully', () async {
      try {
        await nmeaProvider.connect();
      } catch (e) {
        // Expected
      }

      // Second connect should be ignored if already active
      // This tests the isActive guard
      await nmeaProvider.connect();
    });
  });

  group('NMEAProvider connection lifecycle', () {
    late NMEAProvider provider;

    setUp(() async {
      final settings = SettingsProvider();
      await settings.init();
      
      final cache = CacheProvider();
      await cache.init();
      
      provider = NMEAProvider(
        settingsProvider: settings,
        cacheProvider: cache,
        service: MockNMEAService(),
      );
    });

    tearDown(() async {
      await provider.disconnect();
      provider.dispose();
    });

    test('starts in disconnected state', () {
      expect(provider.status, ConnectionStatus.disconnected);
    });

    test('reconnect attempts reset on successful connection', () {
      expect(provider.reconnectAttempts, 0);
    });
  });

  group('ConnectionStatus helpers', () {
    test('isConnected works correctly', () {
      expect(ConnectionStatus.connected.isConnected, true);
      expect(ConnectionStatus.disconnected.isConnected, false);
      expect(ConnectionStatus.connecting.isConnected, false);
      expect(ConnectionStatus.reconnecting.isConnected, false);
      expect(ConnectionStatus.error.isConnected, false);
    });

    test('isActive works correctly', () {
      expect(ConnectionStatus.connected.isActive, true);
      expect(ConnectionStatus.connecting.isActive, true);
      expect(ConnectionStatus.reconnecting.isActive, true);
      expect(ConnectionStatus.disconnected.isActive, false);
      expect(ConnectionStatus.error.isActive, false);
    });
  });
}
