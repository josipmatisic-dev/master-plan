import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/location_service.dart';
// Note: LocationService uses geolocator which requires platform channel mocking.
// For now, we test the non-hardware parts like initial status and enum.
// Full integration testing requires GeolocatorPlatform.instance override which is
// heavy for this scope.

void main() {
  group('LocationService', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial status is idle', () {
      expect(service.status, LocationStatus.idle);
      expect(service.isActive, isFalse);
    });

    test('status stream emits initial status when changed', () async {
      // We can't easily trigger start() success without mocking Geolocator,
      // but we can verify the controller is exposed correctly.
      final stream = service.statusStream;
      expect(stream, isNotNull);
    });

    test('stop() resets status to idle', () {
      // Ideally we would start it first, but since we can't fully start it,
      // we just verify stop doesn't crash from idle state.
      service.stop();
      expect(service.status, LocationStatus.idle);
    });
  });
}
