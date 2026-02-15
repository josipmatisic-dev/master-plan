import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';

void main() {
  group('LatLng', () {
    test('constructor assigns properties correctly', () {
      const point = LatLng(latitude: 45.5, longitude: 14.2);
      expect(point.latitude, 45.5);
      expect(point.longitude, 14.2);
    });

    test('copyWith creates new instance with updated properties', () {
      const original = LatLng(latitude: 45.5, longitude: 14.2);
      final copyLat = original.copyWith(latitude: 46.0);
      final copyLng = original.copyWith(longitude: 15.0);
      final copyBoth = original.copyWith(latitude: 46.0, longitude: 15.0);
      final copyNone = original.copyWith();

      expect(copyLat.latitude, 46.0);
      expect(copyLat.longitude, 14.2);

      expect(copyLng.latitude, 45.5);
      expect(copyLng.longitude, 15.0);

      expect(copyBoth.latitude, 46.0);
      expect(copyBoth.longitude, 15.0);

      expect(copyNone.latitude, 45.5);
      expect(copyNone.longitude, 14.2);
      expect(copyNone, original);
    });

    test('equality and hashCode works correctly', () {
      const point1 = LatLng(latitude: 45.5, longitude: 14.2);
      const point2 = LatLng(latitude: 45.5, longitude: 14.2);
      const point3 = LatLng(latitude: 46.0, longitude: 14.2);

      expect(point1, equals(point2));
      expect(point1.hashCode, equals(point2.hashCode));
      expect(point1, isNot(equals(point3)));
    });

    test('toString produces readable output', () {
      const point = LatLng(latitude: 45.5, longitude: 14.2);
      expect(point.toString(), contains('45.5'));
      expect(point.toString(), contains('14.2'));
    });
  });
}
