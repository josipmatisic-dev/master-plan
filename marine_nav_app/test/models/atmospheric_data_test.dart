import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/atmospheric_data.dart';
import 'package:marine_nav_app/models/lat_lng.dart';

void main() {
  const pos = LatLng(latitude: 43.5, longitude: 16.4);

  group('AtmosphericDataPoint', () {
    test('construction with required fields', () {
      final p = AtmosphericDataPoint(
        position: pos,
        precipitationMmH: 2.5,
        cloudCoverPercent: 60,
      );
      expect(p.precipitationMmH, 2.5);
      expect(p.cloudCoverPercent, 60);
      expect(p.visibilityMeters, isNull);
      expect(p.pressureHpa, isNull);
    });

    test('construction with all optional fields', () {
      final p = AtmosphericDataPoint(
        position: pos,
        precipitationMmH: 0.0,
        cloudCoverPercent: 10,
        visibilityMeters: 15000,
        pressureHpa: 1013.25,
        temperatureCelsius: 22.5,
        apparentTempCelsius: 20.1,
        humidityPercent: 65,
      );
      expect(p.visibilityMeters, 15000);
      expect(p.pressureHpa, 1013.25);
      expect(p.temperatureCelsius, 22.5);
      expect(p.apparentTempCelsius, 20.1);
      expect(p.humidityPercent, 65);
    });

    group('isRaining', () {
      test('false when precip <= 0.1', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0.1,
          cloudCoverPercent: 50,
        );
        expect(p.isRaining, isFalse);
      });

      test('true when precip > 0.1', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0.2,
          cloudCoverPercent: 50,
        );
        expect(p.isRaining, isTrue);
      });
    });

    group('isFoggy', () {
      test('false when visibility null', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
        );
        expect(p.isFoggy, isFalse);
      });

      test('false when visibility >= 1000', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 1000,
        );
        expect(p.isFoggy, isFalse);
      });

      test('true when visibility < 1000', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 800,
        );
        expect(p.isFoggy, isTrue);
      });
    });

    group('isLowVisibility', () {
      test('true when visibility < 5000', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 4000,
        );
        expect(p.isLowVisibility, isTrue);
      });

      test('false when visibility >= 5000', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 5000,
        );
        expect(p.isLowVisibility, isFalse);
      });
    });

    group('isOvercast', () {
      test('true when cloud > 80', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 81,
        );
        expect(p.isOvercast, isTrue);
      });

      test('false when cloud <= 80', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 80,
        );
        expect(p.isOvercast, isFalse);
      });
    });

    group('rainIntensity', () {
      test('returns 0.0 for no rain', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0.05,
          cloudCoverPercent: 50,
        );
        expect(p.rainIntensity, 0.0);
      });

      test('returns 0.2 for light rain', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0.5,
          cloudCoverPercent: 50,
        );
        expect(p.rainIntensity, 0.2);
      });

      test('returns 0.5 for moderate rain', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 3.0,
          cloudCoverPercent: 50,
        );
        expect(p.rainIntensity, 0.5);
      });

      test('returns 0.8 for heavy rain', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 8.0,
          cloudCoverPercent: 50,
        );
        expect(p.rainIntensity, 0.8);
      });

      test('returns 1.0 for extreme rain', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 15.0,
          cloudCoverPercent: 50,
        );
        expect(p.rainIntensity, 1.0);
      });
    });

    group('fogDensity', () {
      test('returns 0.0 for null visibility', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
        );
        expect(p.fogDensity, 0.0);
      });

      test('returns 0.0 for >= 10000m', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 10000,
        );
        expect(p.fogDensity, 0.0);
      });

      test('returns 0.1 for 5000-9999m', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 7000,
        );
        expect(p.fogDensity, 0.1);
      });

      test('returns 0.3 for 2000-4999m', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 3000,
        );
        expect(p.fogDensity, 0.3);
      });

      test('returns 0.5 for 1000-1999m', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 1500,
        );
        expect(p.fogDensity, 0.5);
      });

      test('returns 0.7 for 500-999m', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 700,
        );
        expect(p.fogDensity, 0.7);
      });

      test('returns 0.9 for < 500m', () {
        final p = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0,
          cloudCoverPercent: 50,
          visibilityMeters: 200,
        );
        expect(p.fogDensity, 0.9);
      });
    });

    group('JSON serialization', () {
      test('round-trips with all fields', () {
        final original = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 3.5,
          cloudCoverPercent: 75,
          visibilityMeters: 8000,
          pressureHpa: 1013.25,
          temperatureCelsius: 22.5,
          apparentTempCelsius: 20.1,
          humidityPercent: 65,
        );
        final json = original.toJson();
        final restored = AtmosphericDataPoint.fromJson(json);
        expect(restored.precipitationMmH, original.precipitationMmH);
        expect(restored.cloudCoverPercent, original.cloudCoverPercent);
        expect(restored.visibilityMeters, original.visibilityMeters);
        expect(restored.pressureHpa, original.pressureHpa);
        expect(restored.temperatureCelsius, original.temperatureCelsius);
        expect(restored.apparentTempCelsius, original.apparentTempCelsius);
        expect(restored.humidityPercent, original.humidityPercent);
        expect(restored.position, original.position);
      });

      test('round-trips with only required fields', () {
        final original = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 0.0,
          cloudCoverPercent: 10,
        );
        final json = original.toJson();
        final restored = AtmosphericDataPoint.fromJson(json);
        expect(restored.precipitationMmH, 0.0);
        expect(restored.visibilityMeters, isNull);
      });
    });

    group('equality', () {
      test('equal when same position and precipitation', () {
        final a = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 1.0,
          cloudCoverPercent: 50,
        );
        final b = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 1.0,
          cloudCoverPercent: 90,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when different position', () {
        final a = AtmosphericDataPoint(
          position: pos,
          precipitationMmH: 1.0,
          cloudCoverPercent: 50,
        );
        final b = AtmosphericDataPoint(
          position: const LatLng(latitude: 44, longitude: 17),
          precipitationMmH: 1.0,
          cloudCoverPercent: 50,
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}
