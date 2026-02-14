/// Boat Provider Tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub location service that does nothing (no platform calls).
class StubLocationService extends LocationService {
  @override
  Future<void> start() async {
    // No-op in tests — avoids Geolocator platform calls
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsProvider settingsProvider;
  late CacheProvider cacheProvider;
  late MapProvider mapProvider;
  late NMEAProvider nmeaProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settingsProvider = SettingsProvider();
    await settingsProvider.init();
    cacheProvider = CacheProvider();
    await cacheProvider.init();
    mapProvider = MapProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    await mapProvider.init();
    nmeaProvider = NMEAProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
  });

  group('BoatPosition model', () {
    test('equality based on position and timestamp', () {
      final t = DateTime(2025, 1, 1);
      final a = BoatPosition(
        position: const LatLng(43.5, 16.4),
        timestamp: t,
        speedKnots: 5.0,
      );
      final b = BoatPosition(
        position: const LatLng(43.5, 16.4),
        timestamp: t,
        speedKnots: 10.0, // different speed, same identity
      );
      expect(a, equals(b));
    });

    test('toString includes coords and speed', () {
      final pos = BoatPosition(
        position: const LatLng(43.51234, 16.43210),
        timestamp: DateTime(2025),
        speedKnots: 7.3,
      );
      expect(pos.toString(), contains('43.51234'));
      expect(pos.toString(), contains('7.3kn'));
    });
  });

  group('TrackPoint', () {
    test('fromPosition creates compact point', () {
      final pos = BoatPosition(
        position: const LatLng(43.5, 16.4),
        timestamp: DateTime(2025, 6, 1),
        speedKnots: 5.0,
      );
      final tp = TrackPoint.fromPosition(pos);
      expect(tp.lat, 43.5);
      expect(tp.lng, 16.4);
      expect(tp.speedKnots, 5.0);
    });

    test('fromPosition uses zero speed when null', () {
      final pos = BoatPosition(
        position: const LatLng(0, 0),
        timestamp: DateTime(2025),
      );
      final tp = TrackPoint.fromPosition(pos);
      expect(tp.speedKnots, 0);
    });
  });

  group('BoatProvider', () {
    late BoatProvider boatProvider;

    setUp(() {
      boatProvider = BoatProvider(
        nmeaProvider: nmeaProvider,
        mapProvider: mapProvider,
        locationService: StubLocationService(),
      );
    });

    tearDown(() {
      boatProvider.dispose();
    });

    test('initializes with no position', () {
      expect(boatProvider.currentPosition, isNull);
      expect(boatProvider.source, PositionSource.none);
      expect(boatProvider.trackPointCount, 0);
    });

    test('defaults to followBoat true and showTrack true', () {
      expect(boatProvider.followBoat, isTrue);
      expect(boatProvider.showTrack, isTrue);
    });

    test('toggles followBoat', () {
      boatProvider.followBoat = false;
      expect(boatProvider.followBoat, isFalse);
      boatProvider.followBoat = true;
      expect(boatProvider.followBoat, isTrue);
    });

    test('toggles showTrack', () {
      boatProvider.showTrack = false;
      expect(boatProvider.showTrack, isFalse);
    });

    test('clearTrack empties history', () {
      boatProvider.clearTrack();
      expect(boatProvider.trackPointCount, 0);
    });

    test('trackHistory returns unmodifiable list', () {
      final history = boatProvider.trackHistory;
      expect(history, isA<List<TrackPoint>>());
      expect(() => (history as List).add(null), throwsA(anything));
    });

    test('does not duplicate followBoat notification', () {
      int count = 0;
      boatProvider.addListener(() => count++);
      boatProvider.followBoat = true; // already true
      expect(count, 0);
    });

    test('dispose does not throw when called once', () {
      final bp = BoatProvider(
        nmeaProvider: nmeaProvider,
        mapProvider: mapProvider,
        locationService: StubLocationService(),
      );
      expect(() => bp.dispose(), returnsNormally);
    });
  });

  group('BoatProvider ISS-018 filtering', () {
    test('maxRealisticSpeedMs is 50 m/s (~97 knots)', () {
      expect(BoatProvider.maxRealisticSpeedMs, 50.0);
    });

    test('maxAccuracyMeters is 50m', () {
      expect(BoatProvider.maxAccuracyMeters, 50.0);
    });

    test('maxTrackPoints is 1000', () {
      expect(BoatProvider.maxTrackPoints, 1000);
    });
  });
}
