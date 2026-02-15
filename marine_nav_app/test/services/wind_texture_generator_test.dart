import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/services/wind_texture_generator.dart';

void main() {
  group('WindTextureGenerator.windU', () {
    test('returns 0 for calm wind', () {
      expect(WindTextureGenerator.windU(0, 0), 0.0);
      expect(WindTextureGenerator.windU(0, 180), 0.0);
    });

    test('north wind (from 0°) has zero u-component', () {
      final u = WindTextureGenerator.windU(10, 0);
      expect(u.abs(), lessThan(1e-10));
    });

    test('south wind (from 180°) has zero u-component', () {
      final u = WindTextureGenerator.windU(10, 180);
      expect(u.abs(), lessThan(1e-10));
    });

    test('east wind (from 90°) produces negative u (blowing west)', () {
      final u = WindTextureGenerator.windU(10, 90);
      expect(u, lessThan(0));
    });

    test('west wind (from 270°) produces positive u (blowing east)', () {
      final u = WindTextureGenerator.windU(10, 270);
      expect(u, greaterThan(0));
    });

    test('correctly converts knots to m/s', () {
      // 10 knots from west (270°) → u should be +5.14444 m/s
      final u = WindTextureGenerator.windU(10, 270);
      expect(u, closeTo(10 * 0.514444, 1e-4));
    });
  });

  group('WindTextureGenerator.windV', () {
    test('returns 0 for calm wind', () {
      expect(WindTextureGenerator.windV(0, 0), 0.0);
      expect(WindTextureGenerator.windV(0, 90), 0.0);
    });

    test('east wind (from 90°) has zero v-component', () {
      final v = WindTextureGenerator.windV(10, 90);
      expect(v.abs(), lessThan(1e-10));
    });

    test('north wind (from 0°) produces negative v (blowing south)', () {
      final v = WindTextureGenerator.windV(10, 0);
      expect(v, lessThan(0));
    });

    test('south wind (from 180°) produces positive v (blowing north)', () {
      final v = WindTextureGenerator.windV(10, 180);
      expect(v, greaterThan(0));
    });

    test('correctly converts knots to m/s', () {
      // 10 knots from south (180°) → v should be +5.14444 m/s
      final v = WindTextureGenerator.windV(10, 180);
      expect(v, closeTo(10 * 0.514444, 1e-4));
    });
  });

  group('windU/windV vector consistency', () {
    test('magnitude matches speed in m/s', () {
      const speedKnots = 20.0;
      const dir = 135.0; // SE wind
      final u = WindTextureGenerator.windU(speedKnots, dir);
      final v = WindTextureGenerator.windV(speedKnots, dir);
      final magnitude = math.sqrt(u * u + v * v);
      expect(magnitude, closeTo(speedKnots * 0.514444, 1e-4));
    });

    test('components are symmetric for cardinal directions', () {
      const speed = 15.0;
      final uEast = WindTextureGenerator.windU(speed, 90);
      final uWest = WindTextureGenerator.windU(speed, 270);
      expect(uEast, closeTo(-uWest, 1e-10));

      final vNorth = WindTextureGenerator.windV(speed, 0);
      final vSouth = WindTextureGenerator.windV(speed, 180);
      expect(vNorth, closeTo(-vSouth, 1e-10));
    });
  });

  group('WindTextureGenerator.generateWaveGeoJson', () {
    test('returns null for empty wave points', () {
      final result = WindTextureGenerator.generateWaveGeoJson([]);
      expect(result, isNull);
    });

    test('generates valid GeoJSON with single point', () {
      final points = [
        const WaveDataPoint(
          position: LatLng(latitude: 45.0, longitude: 14.0),
          heightMeters: 2.5,
          directionDegrees: 180,
          periodSeconds: 8.0,
        ),
      ];

      final result = WindTextureGenerator.generateWaveGeoJson(points);
      expect(result, isNotNull);
      expect(result!.maxHeight, 2.5);

      final json = jsonDecode(result.geoJson) as Map<String, dynamic>;
      expect(json['type'], 'FeatureCollection');

      final features = json['features'] as List;
      expect(features, hasLength(1));

      final feature = features[0] as Map<String, dynamic>;
      expect(feature['type'], 'Feature');

      final geometry = feature['geometry'] as Map<String, dynamic>;
      expect(geometry['type'], 'Point');
      expect(geometry['coordinates'], [14.0, 45.0]);

      final props = feature['properties'] as Map<String, dynamic>;
      expect(props['height'], 2.5);
      expect(props['direction'], 180);
      expect(props['period'], 8.0);
    });

    test('tracks max height across multiple points', () {
      final points = [
        const WaveDataPoint(
          position: LatLng(latitude: 45.0, longitude: 14.0),
          heightMeters: 1.0,
          directionDegrees: 90,
        ),
        const WaveDataPoint(
          position: LatLng(latitude: 45.5, longitude: 14.5),
          heightMeters: 4.2,
          directionDegrees: 180,
        ),
        const WaveDataPoint(
          position: LatLng(latitude: 46.0, longitude: 15.0),
          heightMeters: 2.8,
          directionDegrees: 270,
        ),
      ];

      final result = WindTextureGenerator.generateWaveGeoJson(points);
      expect(result!.maxHeight, 4.2);

      final json = jsonDecode(result.geoJson) as Map<String, dynamic>;
      final features = json['features'] as List;
      expect(features, hasLength(3));
    });

    test('handles null periodSeconds as 0 in properties', () {
      final points = [
        const WaveDataPoint(
          position: LatLng(latitude: 45.0, longitude: 14.0),
          heightMeters: 1.5,
          directionDegrees: 90,
        ),
      ];

      final result = WindTextureGenerator.generateWaveGeoJson(points);
      final json = jsonDecode(result!.geoJson) as Map<String, dynamic>;
      final props =
          (json['features'] as List)[0]['properties'] as Map<String, dynamic>;
      expect(props['period'], 0);
    });
  });

  group('WindTextureGenerator.generate', () {
    test('returns null for empty wind points', () async {
      final result = await WindTextureGenerator.generate(
        windPoints: [],
        south: 43.0,
        north: 46.0,
        west: 13.0,
        east: 16.0,
      );
      expect(result, isNull);
    });

    test('produces valid texture from single wind point', () async {
      final points = [
        const WindDataPoint(
          position: LatLng(latitude: 44.5, longitude: 14.5),
          speedKnots: 15,
          directionDegrees: 225,
        ),
      ];

      final result = await WindTextureGenerator.generate(
        windPoints: points,
        south: 43.0,
        north: 46.0,
        west: 13.0,
        east: 16.0,
        resolution: 4,
      );

      expect(result, isNotNull);
      expect(result!.width, 4);
      expect(result.height, 4);
      expect(result.south, 43.0);
      expect(result.north, 46.0);
      expect(result.west, 13.0);
      expect(result.east, 16.0);
      expect(result.base64Png, isNotEmpty);

      // With single point, IDW collapses to uniform → uMin≈uMax,
      // so range gets forced to +1
      expect(result.uMax, greaterThan(result.uMin));
      expect(result.vMax, greaterThan(result.vMin));
    });

    test('produces texture with correct resolution', () async {
      final points = [
        const WindDataPoint(
          position: LatLng(latitude: 44.0, longitude: 14.0),
          speedKnots: 10,
          directionDegrees: 0,
        ),
        const WindDataPoint(
          position: LatLng(latitude: 45.0, longitude: 15.0),
          speedKnots: 20,
          directionDegrees: 180,
        ),
      ];

      final result = await WindTextureGenerator.generate(
        windPoints: points,
        south: 43.0,
        north: 46.0,
        west: 13.0,
        east: 16.0,
        resolution: 8,
      );

      expect(result, isNotNull);
      expect(result!.width, 8);
      expect(result.height, 8);
    });

    test('base64Png is valid base64', () async {
      final points = [
        const WindDataPoint(
          position: LatLng(latitude: 44.5, longitude: 14.5),
          speedKnots: 10,
          directionDegrees: 90,
        ),
      ];

      final result = await WindTextureGenerator.generate(
        windPoints: points,
        south: 44.0,
        north: 45.0,
        west: 14.0,
        east: 15.0,
        resolution: 2,
      );

      expect(result, isNotNull);
      final bytes = base64Decode(result!.base64Png);
      // PNG starts with magic bytes: 137 80 78 71 (0x89 P N G)
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50); // 'P'
      expect(bytes[2], 0x4E); // 'N'
      expect(bytes[3], 0x47); // 'G'
    });

    test('opposing wind points produce varying u/v ranges', () async {
      final points = [
        const WindDataPoint(
          position: LatLng(latitude: 44.0, longitude: 14.0),
          speedKnots: 20,
          directionDegrees: 0, // from north
        ),
        const WindDataPoint(
          position: LatLng(latitude: 46.0, longitude: 16.0),
          speedKnots: 20,
          directionDegrees: 180, // from south
        ),
      ];

      final result = await WindTextureGenerator.generate(
        windPoints: points,
        south: 43.0,
        north: 47.0,
        west: 13.0,
        east: 17.0,
        resolution: 4,
      );

      expect(result, isNotNull);
      // Opposing v-components should create a real range
      expect(result!.vMax - result.vMin, greaterThan(0.1));
    });
  });

  group('WindTextureData', () {
    test('stores all provided values', () {
      const data = WindTextureData(
        base64Png: 'abc123',
        uMin: -5.0,
        uMax: 5.0,
        vMin: -3.0,
        vMax: 3.0,
        width: 64,
        height: 64,
        south: 43.0,
        north: 46.0,
        west: 13.0,
        east: 16.0,
      );

      expect(data.base64Png, 'abc123');
      expect(data.uMin, -5.0);
      expect(data.uMax, 5.0);
      expect(data.vMin, -3.0);
      expect(data.vMax, 3.0);
      expect(data.width, 64);
      expect(data.height, 64);
      expect(data.south, 43.0);
      expect(data.north, 46.0);
      expect(data.west, 13.0);
      expect(data.east, 16.0);
    });
  });

  group('WaveTextureData', () {
    test('stores all provided values', () {
      const data = WaveTextureData(
        geoJson: '{"type":"FeatureCollection","features":[]}',
        maxHeight: 3.5,
      );

      expect(data.geoJson, contains('FeatureCollection'));
      expect(data.maxHeight, 3.5);
    });
  });
}
