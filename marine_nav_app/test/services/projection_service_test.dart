/// Projection Service Tests
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart';
import 'package:marine_nav_app/services/projection_service.dart';

void main() {
  group('ProjectionService', () {
    test('round trips screen to lat/lng', () {
      const viewport = Viewport(
        center: LatLng(latitude: 0, longitude: 0),
        zoom: 3,
        size: Size(400, 300),
        rotation: 0,
      );
      const point = LatLng(latitude: 12.5, longitude: -45.2);

      final screen = ProjectionService.latLngToScreen(point, viewport);
      final result = ProjectionService.screenToLatLng(screen, viewport);

      expect((result.latitude - point.latitude).abs(), lessThan(1e-6));
      expect((result.longitude - point.longitude).abs(), lessThan(1e-6));
    });

    test('accounts for rotation', () {
      const viewport = Viewport(
        center: LatLng(latitude: 0, longitude: 0),
        zoom: 2,
        size: Size(500, 400),
        rotation: 0.5,
      );
      const point = LatLng(latitude: 5, longitude: 15);

      final screen = ProjectionService.latLngToScreen(point, viewport);
      final result = ProjectionService.screenToLatLng(screen, viewport);

      expect((result.latitude - point.latitude).abs(), lessThan(1e-6));
      expect((result.longitude - point.longitude).abs(), lessThan(1e-6));
    });
  });
}
