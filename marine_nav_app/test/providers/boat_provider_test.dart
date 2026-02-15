/// Boat Provider Tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
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
    test('constructs with required fields and defaults', () {
      final t = DateTime(2025, 1, 1);
      const pos = LatLng(latitude: 43.5, longitude: 16.4);
      final bp = BoatPosition(position: pos, timestamp: t);

      expect(bp.latitude, 43.5);
      expect(bp.longitude, 16.4);
      expect(bp.speedKnots, isNull);
      expect(bp.courseTrue, isNull);
      expect(bp.heading, isNull);
      expect(bp.accuracy, 0.0);
      expect(bp.fixQuality, 0);
      expect(bp.satellites, 0);
      expect(bp.altitudeMeters, isNull);
    });

    test('isValid reflects fixQuality', () {
      final valid = BoatPosition(
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime(2025),
        fixQuality: 1,
      );
      final invalid = BoatPosition(
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime(2025),
      );
      expect(valid.isValid, isTrue);
      expect(invalid.isValid, isFalse);
    });

    test('isAccurate reflects accuracy threshold', () {
      final accurate = BoatPosition(
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime(2025),
        accuracy: 50.0,
      );
      final inaccurate = BoatPosition(
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime(2025),
        accuracy: 50.1,
      );
      expect(accurate.isAccurate, isTrue);
      expect(inaccurate.isAccurate, isFalse);
    });

    test('bestHeading prefers courseTrue over heading', () {
      final bp = BoatPosition(
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime(2025),
        courseTrue: 90.0,
        heading: 85.0,
      );
      expect(bp.bestHeading, 90.0);

      final headingOnly = BoatPosition(
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime(2025),
        heading: 85.0,
      );
      expect(headingOnly.bestHeading, 85.0);
    });

    test('copyWith preserves unchanged fields', () {
      final original = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime(2025),
        speedKnots: 10.0,
        courseTrue: 45.0,
      );
      final copied = original.copyWith(speedKnots: 15.0);
      expect(copied.speedKnots, 15.0);
      expect(copied.courseTrue, 45.0);
      expect(copied.latitude, 43.5);
    });

    test('equality compares all fields', () {
      final t = DateTime(2025, 1, 1);
      final a = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: t,
        speedKnots: 5.0,
        courseTrue: 90.0,
      );
      final b = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: t,
        speedKnots: 5.0,
        courseTrue: 90.0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes coords and speed', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.51234, longitude: 16.43210),
        timestamp: DateTime(2025),
        speedKnots: 7.3,
        courseTrue: 85.0,
      );
      final str = pos.toString();
      expect(str, contains('43.51234'));
      expect(str, contains('7.3'));
      expect(str, contains('85.0'));
    });
  });

  group('TrackPoint', () {
    test('fromPosition creates compact point', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
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
        position: const LatLng(latitude: 0, longitude: 0),
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

  group('ISS-018 constants', () {
    test('maxRealisticSpeedMps is 50 m/s (~97 knots)', () {
      expect(maxRealisticSpeedMps, 50.0);
    });

    test('maxAccuracyThresholdMeters is 50m', () {
      expect(maxAccuracyThresholdMeters, 50.0);
    });

    test('maxTrackHistoryPoints is 1000', () {
      expect(maxTrackHistoryPoints, 1000);
    });
  });
}
