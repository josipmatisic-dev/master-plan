import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/nmea_data.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/services/nmea_service.dart';

/// Mock NMEA Service that prevents actual connection attempts.
class MockNMEAService extends NMEAService {}

/// Helper to create [NMEAData] with a GPS position.
NMEAData _makeNmeaData({
  required double lat,
  required double lng,
  double? speedKnots,
  double? courseTrue,
  double hdop = 1.0,
  int fixQuality = 1,
  int satellites = 8,
  DateTime? timestamp,
}) {
  final ts = timestamp ?? DateTime.now();
  return NMEAData(
    timestamp: ts,
    gpgga: GPGGAData(
      position: ll.LatLng(lat, lng),
      time: ts,
      fixQuality: fixQuality,
      satellites: satellites,
      hdop: hdop,
    ),
    gprmc: GPRMCData(
      position: ll.LatLng(lat, lng),
      time: ts,
      valid: true,
      speedKnots: speedKnots,
      trackTrue: courseTrue,
    ),
    gpvtg: courseTrue != null || speedKnots != null
        ? GPVTGData(
            trackTrue: courseTrue,
            speedKnots: speedKnots,
          )
        : null,
  );
}

void main() {
  group('BoatProvider', () {
    late SettingsProvider settingsProvider;
    late CacheProvider cacheProvider;
    late NMEAProvider nmeaProvider;
    late BoatProvider boatProvider;
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
      boatProvider = BoatProvider(nmeaProvider: nmeaProvider);
    });

    tearDown(() {
      if (!providerDisposed) {
        boatProvider.dispose();
      }
      nmeaProvider.dispose();
      cacheProvider.dispose();
    });

    // ============ Initialization ============

    test('initializes with null position', () {
      expect(boatProvider.currentPosition, isNull);
      expect(boatProvider.hasPosition, false);
    });

    test('initializes with empty track history', () {
      expect(boatProvider.trackHistory, isEmpty);
      expect(boatProvider.trackHistoryLength, 0);
    });

    test('initializes with no MOB', () {
      expect(boatProvider.mobPosition, isNull);
      expect(boatProvider.hasMob, false);
    });

    test('initializes with tracking enabled', () {
      expect(boatProvider.isTracking, true);
    });

    // ============ updateFromNMEA ============

    test('updateFromNMEA sets current position', () {
      final data = _makeNmeaData(
        lat: 59.91,
        lng: 10.75,
        speedKnots: 12.0,
        courseTrue: 85.0,
      );

      boatProvider.updateFromNMEA(data);

      expect(boatProvider.hasPosition, true);
      final pos = boatProvider.currentPosition!;
      expect(pos.latitude, 59.91);
      expect(pos.longitude, 10.75);
      expect(pos.speedKnots, 12.0);
      expect(pos.courseTrue, 85.0);
    });

    test('updateFromNMEA adds to track history', () {
      final data = _makeNmeaData(lat: 59.91, lng: 10.75);
      boatProvider.updateFromNMEA(data);

      expect(boatProvider.trackHistoryLength, 1);
      expect(boatProvider.trackHistory.first.latitude, 59.91);
    });

    test('updateFromNMEA ignores null data', () {
      boatProvider.updateFromNMEA(null);
      expect(boatProvider.hasPosition, false);
      expect(boatProvider.trackHistoryLength, 0);
    });

    test('updateFromNMEA ignores data without position', () {
      final data = NMEAData(timestamp: DateTime.now());
      boatProvider.updateFromNMEA(data);
      expect(boatProvider.hasPosition, false);
    });

    test('updateFromNMEA calculates accuracy from HDOP', () {
      final data = _makeNmeaData(lat: 59.91, lng: 10.75, hdop: 2.5);
      boatProvider.updateFromNMEA(data);

      // accuracy = hdop × 5.0 = 12.5
      expect(boatProvider.currentPosition!.accuracy, 12.5);
    });

    test('updateFromNMEA extracts fix quality and satellites', () {
      final data = _makeNmeaData(
        lat: 59.91,
        lng: 10.75,
        fixQuality: 2,
        satellites: 10,
      );
      boatProvider.updateFromNMEA(data);

      expect(boatProvider.currentPosition!.fixQuality, 2);
      expect(boatProvider.currentPosition!.satellites, 10);
    });

    test('updateFromNMEA notifies listeners', () {
      int notifyCount = 0;
      boatProvider.addListener(() => notifyCount++);

      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );

      expect(notifyCount, 1);
    });

    // ============ Tracking toggle ============

    test('setTracking disables position updates', () {
      boatProvider.setTracking(enabled: false);
      expect(boatProvider.isTracking, false);

      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      expect(boatProvider.hasPosition, false);
    });

    test('setTracking re-enables position updates', () {
      boatProvider.setTracking(enabled: false);
      boatProvider.setTracking(enabled: true);

      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      expect(boatProvider.hasPosition, true);
    });

    test('setTracking does not notify if value unchanged', () {
      int notifyCount = 0;
      boatProvider.addListener(() => notifyCount++);

      boatProvider.setTracking(enabled: true); // already true
      expect(notifyCount, 0);
    });

    // ============ ISS-018 Filtering ============

    test('accepts first position regardless of accuracy', () {
      final data = _makeNmeaData(
        lat: 59.91,
        lng: 10.75,
        hdop: 20.0, // accuracy = 100m (above threshold)
      );
      boatProvider.updateFromNMEA(data);
      expect(boatProvider.hasPosition, true);
    });

    test('rejects unrealistic speed with poor accuracy', () {
      // Set initial position
      final now = DateTime.now();
      final first = _makeNmeaData(
        lat: 59.91,
        lng: 10.75,
        timestamp: now,
      );
      boatProvider.updateFromNMEA(first);

      // Position jump: ~1 degree lat ≈ 111km in 1 second = ~111,000 m/s
      // AND accuracy > 50m → should be rejected
      final jump = _makeNmeaData(
        lat: 60.91,
        lng: 10.75,
        hdop: 20.0, // accuracy = 100m
        timestamp: now.add(const Duration(seconds: 1)),
      );
      boatProvider.updateFromNMEA(jump);

      // Should still have the first position
      expect(boatProvider.currentPosition!.latitude, 59.91);
      expect(boatProvider.trackHistoryLength, 1);
    });

    test('accepts high speed with good accuracy (valid fast vessel)', () {
      final now = DateTime.now();
      final first = _makeNmeaData(
        lat: 59.91,
        lng: 10.75,
        timestamp: now,
      );
      boatProvider.updateFromNMEA(first);

      // Same large position jump but with good accuracy
      final jump = _makeNmeaData(
        lat: 60.91,
        lng: 10.75,
        hdop: 1.0, // accuracy = 5m (good)
        timestamp: now.add(const Duration(seconds: 1)),
      );
      boatProvider.updateFromNMEA(jump);

      // Should accept because accuracy is good
      expect(boatProvider.currentPosition!.latitude, 60.91);
    });

    test('accepts poor accuracy with realistic speed', () {
      final now = DateTime.now();
      final first = _makeNmeaData(
        lat: 59.91,
        lng: 10.75,
        timestamp: now,
      );
      boatProvider.updateFromNMEA(first);

      // Small position change (realistic speed) with poor accuracy
      final next = _makeNmeaData(
        lat: 59.9101,
        lng: 10.7501,
        hdop: 20.0, // accuracy = 100m (poor)
        timestamp: now.add(const Duration(seconds: 10)),
      );
      boatProvider.updateFromNMEA(next);

      // Should accept because speed is realistic
      expect(boatProvider.currentPosition!.latitude, closeTo(59.9101, 0.001));
    });

    // ============ Track History LRU Eviction ============

    test('evicts oldest points when exceeding max', () {
      final now = DateTime.now();

      // Add maxTrackHistoryPoints + 5 positions
      for (var i = 0; i <= maxTrackHistoryPoints + 4; i++) {
        final lat = 59.0 + (i * 0.0001); // tiny increments
        boatProvider.updateFromNMEA(
          _makeNmeaData(
            lat: lat,
            lng: 10.75,
            timestamp: now.add(Duration(seconds: i)),
          ),
        );
      }

      expect(boatProvider.trackHistoryLength, maxTrackHistoryPoints);
      // First point should NOT be the original (it was evicted)
      expect(boatProvider.trackHistory.first.latitude, isNot(59.0));
    });

    // ============ MOB (Man Overboard) ============

    test('markMOB captures current position', () {
      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      boatProvider.markMOB();

      expect(boatProvider.hasMob, true);
      expect(boatProvider.mobPosition!.latitude, 59.91);
      expect(boatProvider.mobPosition!.longitude, 10.75);
    });

    test('markMOB does nothing when no position', () {
      boatProvider.markMOB();
      expect(boatProvider.hasMob, false);
    });

    test('clearMOB removes MOB marker', () {
      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      boatProvider.markMOB();
      boatProvider.clearMOB();

      expect(boatProvider.hasMob, false);
      expect(boatProvider.mobPosition, isNull);
    });

    test('clearMOB does not notify when no MOB set', () {
      int notifyCount = 0;
      boatProvider.addListener(() => notifyCount++);
      boatProvider.clearMOB();
      expect(notifyCount, 0);
    });

    test('markMOB notifies listeners', () {
      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      int notifyCount = 0;
      boatProvider.addListener(() => notifyCount++);
      boatProvider.markMOB();
      expect(notifyCount, 1);
    });

    // ============ clearTrack ============

    test('clearTrack removes all history', () {
      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      boatProvider.updateFromNMEA(
        _makeNmeaData(
          lat: 59.92,
          lng: 10.76,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
      expect(boatProvider.trackHistoryLength, 2);

      boatProvider.clearTrack();
      expect(boatProvider.trackHistoryLength, 0);
      expect(boatProvider.trackHistory, isEmpty);
    });

    test('clearTrack does not notify when already empty', () {
      int notifyCount = 0;
      boatProvider.addListener(() => notifyCount++);
      boatProvider.clearTrack();
      expect(notifyCount, 0);
    });

    test('clearTrack notifies listeners when non-empty', () {
      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );
      int notifyCount = 0;
      boatProvider.addListener(() => notifyCount++);
      boatProvider.clearTrack();
      expect(notifyCount, 1);
    });

    // ============ trackHistory unmodifiable ============

    test('trackHistory returns unmodifiable list', () {
      boatProvider.updateFromNMEA(
        _makeNmeaData(lat: 59.91, lng: 10.75),
      );

      final history = boatProvider.trackHistory;
      expect(
        () => history.add(
          BoatPosition(
            position: const LatLng(latitude: 0.0, longitude: 0.0),
            timestamp: DateTime.now(),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    // ============ Dispose ============

    test('dispose removes listener from NMEAProvider', () {
      providerDisposed = true;
      // Should not throw
      boatProvider.dispose();
    });
  });
}
