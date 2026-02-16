import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/trip_log.dart';
import 'package:marine_nav_app/services/trip_log_service.dart';

void main() {
  group('TripWaypoint', () {
    test('creates from BoatPosition', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.utc(2025, 1, 15, 10, 30),
        speedKnots: 6.5,
        courseTrue: 180.0,
      );

      final wp = TripWaypoint.fromPosition(pos);
      expect(wp.lat, 43.5);
      expect(wp.lng, 16.4);
      expect(wp.speedKnots, 6.5);
      expect(wp.cogDegrees, 180.0);
      expect(wp.timestamp, '2025-01-15T10:30:00.000Z');
    });

    test('serializes to/from JSON', () {
      const wp = TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 6.5,
        timestamp: '2025-01-15T10:30:00.000Z',
        cogDegrees: 180.0,
      );

      final json = wp.toJson();
      final restored = TripWaypoint.fromJson(json);
      expect(restored.lat, wp.lat);
      expect(restored.lng, wp.lng);
      expect(restored.speedKnots, wp.speedKnots);
      expect(restored.cogDegrees, wp.cogDegrees);
      expect(restored.timestamp, wp.timestamp);
    });
  });

  group('TripLog', () {
    test('computes avgSpeedKnots and maxSpeedKnots', () {
      final trip = TripLog(
        id: '1',
        name: 'Test',
        startTime: DateTime.utc(2025, 1, 15, 10),
        waypoints: const [
          TripWaypoint(
            lat: 43.5,
            lng: 16.4,
            speedKnots: 5.0,
            timestamp: '2025-01-15T10:00:00Z',
          ),
          TripWaypoint(
            lat: 43.6,
            lng: 16.5,
            speedKnots: 10.0,
            timestamp: '2025-01-15T10:30:00Z',
          ),
          TripWaypoint(
            lat: 43.7,
            lng: 16.6,
            speedKnots: 6.0,
            timestamp: '2025-01-15T11:00:00Z',
          ),
        ],
      );

      expect(trip.avgSpeedKnots, 7.0);
      expect(trip.maxSpeedKnots, 10.0);
    });

    test('isRecording when endTime is null', () {
      final trip = TripLog(
        id: '1',
        name: 'Active',
        startTime: DateTime.now(),
        waypoints: const [],
      );
      expect(trip.isRecording, isTrue);
    });

    test('not recording when endTime is set', () {
      final trip = TripLog(
        id: '1',
        name: 'Done',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        waypoints: const [],
      );
      expect(trip.isRecording, isFalse);
    });

    test('serializes to/from JSON', () {
      final trip = TripLog(
        id: '42',
        name: 'Croatia Sail',
        startTime: DateTime.utc(2025, 6, 1, 8),
        endTime: DateTime.utc(2025, 6, 1, 16),
        distanceNm: 25.3,
        waypoints: const [
          TripWaypoint(
            lat: 43.5,
            lng: 16.4,
            speedKnots: 5.0,
            timestamp: '2025-06-01T08:00:00Z',
          ),
        ],
      );

      final json = trip.toJson();
      final restored = TripLog.fromJson(json);
      expect(restored.id, '42');
      expect(restored.name, 'Croatia Sail');
      expect(restored.distanceNm, 25.3);
      expect(restored.waypoints.length, 1);
      expect(restored.endTime, isNotNull);
    });
  });

  group('TripLogService', () {
    late TripLogService service;

    setUp(() {
      service = TripLogService();
    });

    test('starts and stops a trip', () async {
      expect(service.isRecording, isFalse);

      service.startTrip(name: 'Test Trip');
      expect(service.isRecording, isTrue);
      expect(service.activeTrip!.name, 'Test Trip');

      final completed = await service.stopTrip();
      expect(service.isRecording, isFalse);
      expect(completed, isNotNull);
      expect(completed!.name, 'Test Trip');
      expect(completed.endTime, isNotNull);
      expect(service.savedTrips.length, 1);
    });

    test('prevents starting a second trip', () {
      service.startTrip(name: 'First');
      service.startTrip(name: 'Second');
      expect(service.activeTrip!.name, 'First');
    });

    test('addWaypoint filters close points', () {
      service.startTrip();

      // First waypoint always accepted
      service.addWaypoint(BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      ));
      expect(service.activeTrip!.waypoints.length, 1);

      // Too close — should be filtered
      service.addWaypoint(BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      ));
      expect(service.activeTrip!.waypoints.length, 1);

      // Far enough — should be accepted
      service.addWaypoint(BoatPosition(
        position: const LatLng(latitude: 43.501, longitude: 16.401),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      ));
      expect(service.activeTrip!.waypoints.length, 2);
    });

    test('accumulates distance', () {
      service.startTrip();

      service.addWaypoint(BoatPosition(
        position: const LatLng(latitude: 43.0, longitude: 16.0),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      ));
      service.addWaypoint(BoatPosition(
        position: const LatLng(latitude: 43.1, longitude: 16.0),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      ));

      // ~11.1 km ≈ 6 nm
      expect(service.activeTrip!.distanceNm, greaterThan(5.0));
      expect(service.activeTrip!.distanceNm, lessThan(7.0));
    });

    test('notifies listeners on start/stop/waypoint', () async {
      int notifications = 0;
      service.addListener(() => notifications++);

      service.startTrip();
      expect(notifications, 1);

      service.addWaypoint(BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      ));
      expect(notifications, 2);

      await service.stopTrip();
      expect(notifications, 3);
    });

    test('deleteTrip removes from saved list', () async {
      service.startTrip(name: 'To Delete');
      final trip = await service.stopTrip();

      expect(service.savedTrips.length, 1);
      await service.deleteTrip(trip!.id);
      expect(service.savedTrips.length, 0);
    });
  });

  group('GPX/KML Export', () {
    late TripLogService service;
    late TripLog trip;

    setUp(() {
      service = TripLogService();
      trip = TripLog(
        id: '1',
        name: 'Export Test',
        startTime: DateTime.utc(2025, 6, 1, 8),
        endTime: DateTime.utc(2025, 6, 1, 10),
        waypoints: const [
          TripWaypoint(
            lat: 43.5,
            lng: 16.4,
            speedKnots: 5.0,
            timestamp: '2025-06-01T08:00:00Z',
          ),
          TripWaypoint(
            lat: 43.6,
            lng: 16.5,
            speedKnots: 7.0,
            timestamp: '2025-06-01T09:00:00Z',
          ),
        ],
      );
    });

    test('exports valid GPX', () {
      final gpx = service.exportGpx(trip);
      expect(gpx, contains('<?xml version="1.0"'));
      expect(gpx, contains('<gpx'));
      expect(gpx, contains('<trk>'));
      expect(gpx, contains('<name>Export Test</name>'));
      expect(gpx, contains('lat="43.5"'));
      expect(gpx, contains('lon="16.4"'));
      expect(gpx, contains('<speed>5.0</speed>'));
    });

    test('exports valid KML', () {
      final kml = service.exportKml(trip);
      expect(kml, contains('<?xml version="1.0"'));
      expect(kml, contains('<kml'));
      expect(kml, contains('<name>Export Test</name>'));
      expect(kml, contains('16.4,43.5,0'));
      expect(kml, contains('16.5,43.6,0'));
    });

    test('GPX escapes XML characters', () {
      final tripWithSpecial = TripLog(
        id: '2',
        name: 'Trip <A> & B',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      final gpx = service.exportGpx(tripWithSpecial);
      expect(gpx, contains('Trip &lt;A&gt; &amp; B'));
    });

    test('KML escapes XML characters', () {
      final tripWithSpecial = TripLog(
        id: '3',
        name: 'Route <C> & D',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      final kml = service.exportKml(tripWithSpecial);
      expect(kml, contains('Route &lt;C&gt; &amp; D'));
    });

    test('GPX includes time elements for each waypoint', () {
      final gpx = service.exportGpx(trip);
      expect(gpx, contains('<time>2025-06-01T08:00:00Z</time>'));
      expect(gpx, contains('<time>2025-06-01T09:00:00Z</time>'));
    });

    test('GPX empty trip produces valid structure', () {
      final emptyTrip = TripLog(
        id: '4',
        name: 'Empty',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      final gpx = service.exportGpx(emptyTrip);
      expect(gpx, contains('<trkseg>'));
      expect(gpx, contains('</trkseg>'));
      expect(gpx, isNot(contains('<trkpt')));
    });

    test('KML empty trip produces valid structure', () {
      final emptyTrip = TripLog(
        id: '5',
        name: 'Empty',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      final kml = service.exportKml(emptyTrip);
      expect(kml, contains('<coordinates>'));
      expect(kml, contains('</coordinates>'));
    });

    test('KML coordinates are lng,lat,0 format', () {
      final kml = service.exportKml(trip);
      // KML uses lng,lat,altitude — verify order
      final lines = kml.split('\n');
      final coordLines =
          lines.where((l) => l.trim().contains(RegExp(r'^\d'))).toList();
      expect(coordLines.first.trim(), '16.4,43.5,0');
    });

    test('GPX has correct namespace', () {
      final gpx = service.exportGpx(trip);
      expect(gpx, contains('xmlns="http://www.topografix.com/GPX/1/1"'));
      expect(gpx, contains('version="1.1"'));
      expect(gpx, contains('creator="SailStream"'));
    });

    test('KML has correct namespace', () {
      final kml = service.exportKml(trip);
      expect(kml, contains('xmlns="http://www.opengis.net/kml/2.2"'));
    });
  });

  group('TripLog model', () {
    test('duration computes correctly for completed trip', () {
      final trip = TripLog(
        id: '1',
        name: 'Test',
        startTime: DateTime.utc(2025, 1, 1, 8),
        endTime: DateTime.utc(2025, 1, 1, 10, 30),
        waypoints: const [],
      );
      expect(trip.duration, const Duration(hours: 2, minutes: 30));
    });

    test('avgSpeedKnots returns 0 for empty trip', () {
      final trip = TripLog(
        id: '1',
        name: 'Test',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      expect(trip.avgSpeedKnots, 0);
    });

    test('maxSpeedKnots returns 0 for empty trip', () {
      final trip = TripLog(
        id: '1',
        name: 'Test',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      expect(trip.maxSpeedKnots, 0);
    });

    test('copyWith preserves unmodified fields', () {
      final trip = TripLog(
        id: '1',
        name: 'Original',
        startTime: DateTime.utc(2025, 1, 1),
        waypoints: const [],
        distanceNm: 10,
      );
      final copy = trip.copyWith(name: 'Renamed');
      expect(copy.id, '1');
      expect(copy.name, 'Renamed');
      expect(copy.distanceNm, 10);
      expect(copy.startTime, trip.startTime);
    });

    test('distanceNm defaults to 0', () {
      final trip = TripLog(
        id: '1',
        name: 'Test',
        startTime: DateTime.utc(2025),
        waypoints: const [],
      );
      expect(trip.distanceNm, 0);
    });

    test('TripWaypoint JSON round-trip with COG', () {
      const wp = TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 6.5,
        timestamp: '2025-01-15T10:30:00Z',
        cogDegrees: 270.0,
      );
      final json = wp.toJson();
      expect(json['cogDegrees'], 270.0);
      final restored = TripWaypoint.fromJson(json);
      expect(restored.cogDegrees, 270.0);
    });

    test('TripWaypoint JSON round-trip without COG', () {
      const wp = TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 6.5,
        timestamp: '2025-01-15T10:30:00Z',
      );
      final json = wp.toJson();
      expect(json.containsKey('cogDegrees'), isFalse);
      final restored = TripWaypoint.fromJson(json);
      expect(restored.cogDegrees, isNull);
    });
  });
}
