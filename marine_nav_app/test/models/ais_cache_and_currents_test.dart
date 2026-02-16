import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/tide_data.dart';

void main() {
  group('AisTarget JSON serialization', () {
    test('toJson/fromJson round-trip with all fields', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.utc(2024, 6, 1, 12, 0),
        sog: 12.5,
        cog: 180.0,
        heading: 175,
        navStatus: AisNavStatus.underWayEngine,
        rateOfTurn: 2.5,
        name: 'Test Vessel',
        callSign: 'DTEST',
        imo: 9876543,
        shipType: 70,
        dimensions: const [50, 10, 8, 8],
        destination: 'SPLIT',
        draught: 5.2,
        eta: DateTime.utc(2024, 6, 2, 8, 0),
      );

      final json = target.toJson();
      final restored = AisTarget.fromJson(json);

      expect(restored.mmsi, 211234567);
      expect(restored.position.latitude, 43.5);
      expect(restored.position.longitude, 16.4);
      expect(restored.sog, 12.5);
      expect(restored.cog, 180.0);
      expect(restored.heading, 175.0);
      expect(restored.navStatus, AisNavStatus.underWayEngine);
      expect(restored.rateOfTurn, 2.5);
      expect(restored.name, 'Test Vessel');
      expect(restored.callSign, 'DTEST');
      expect(restored.imo, 9876543);
      expect(restored.shipType, 70);
      expect(restored.dimensions, [50, 10, 8, 8]);
      expect(restored.destination, 'SPLIT');
      expect(restored.draught, 5.2);
      expect(restored.eta, DateTime.utc(2024, 6, 2, 8, 0));
    });

    test('toJson/fromJson with minimal fields', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.utc(2024, 6, 1),
      );

      final json = target.toJson();
      expect(json.containsKey('sog'), false);
      expect(json.containsKey('name'), false);
      expect(json.containsKey('eta'), false);

      final restored = AisTarget.fromJson(json);
      expect(restored.mmsi, 211234567);
      expect(restored.sog, isNull);
      expect(restored.name, isNull);
      expect(restored.navStatus, AisNavStatus.unknown);
    });

    test('batch toJson for cache persistence', () {
      final targets = List.generate(
        3,
        (i) => AisTarget(
          mmsi: 200000000 + i,
          position: LatLng(latitude: 43.0 + i * 0.1, longitude: 16.0),
          lastUpdate: DateTime.now(),
          name: 'Vessel $i',
        ),
      );

      final jsonList = targets.map((t) => t.toJson()).toList();
      expect(jsonList.length, 3);

      final restored = jsonList.map((j) => AisTarget.fromJson(j)).toList();
      expect(restored.length, 3);
      expect(restored[0].name, 'Vessel 0');
      expect(restored[2].mmsi, 200000002);
    });
  });

  group('CurrentPrediction', () {
    test('parses from NOAA JSON', () {
      final json = {
        'Time': '2024-06-01 12:00',
        'Velocity_Major': '1.25',
        'meanFloodDir': '45.0',
      };

      final prediction = CurrentPrediction.fromNoaaJson(json);
      expect(prediction.time, DateTime(2024, 6, 1, 12, 0));
      expect(prediction.speedKnots, 1.25);
      expect(prediction.directionDegrees, 45.0);
    });

    test('handles negative velocity (ebb)', () {
      final json = {
        'Time': '2024-06-01 18:00',
        'Velocity_Major': '-0.85',
        'meanFloodDir': '225.0',
      };

      final prediction = CurrentPrediction.fromNoaaJson(json);
      expect(prediction.speedKnots, 0.85);
    });

    test('handles missing direction', () {
      final json = {
        'Time': '2024-06-01 12:00',
        'Velocity_Major': '1.0',
      };

      final prediction = CurrentPrediction.fromNoaaJson(json);
      expect(prediction.directionDegrees, 0.0);
    });
  });
}
