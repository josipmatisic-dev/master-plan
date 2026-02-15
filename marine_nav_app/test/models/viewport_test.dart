/// Viewport model tests.
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart';

void main() {
  group('Viewport', () {
    test('copyWith returns updated viewport', () {
      const vp = Viewport(
        center: LatLng(latitude: 10.0, longitude: 20.0),
        zoom: 5.0,
        size: Size(400, 300),
        rotation: 0.0,
      );

      final updated = vp.copyWith(zoom: 8.0);

      expect(updated.zoom, 8.0);
      expect(updated.center, vp.center);
      expect(updated.size, vp.size);
    });

    test('bounds returns center when size is empty', () {
      const vp = Viewport(
        center: LatLng(latitude: 45.0, longitude: 10.0),
        zoom: 5.0,
        size: Size.zero,
        rotation: 0.0,
      );

      final b = vp.bounds;

      expect(b.south, 45.0);
      expect(b.north, 45.0);
      expect(b.west, 10.0);
      expect(b.east, 10.0);
    });

    test('bounds computes valid SNWE for non-empty viewport', () {
      const vp = Viewport(
        center: LatLng(latitude: 45.0, longitude: 10.0),
        zoom: 5.0,
        size: Size(400, 300),
        rotation: 0.0,
      );

      final b = vp.bounds;

      // South < center < North
      expect(b.south, lessThan(45.0));
      expect(b.north, greaterThan(45.0));
      // West < center < East
      expect(b.west, lessThan(10.0));
      expect(b.east, greaterThan(10.0));
    });

    test('bounds are symmetric around center at zoom 5', () {
      const vp = Viewport(
        center: LatLng(latitude: 0.0, longitude: 0.0),
        zoom: 5.0,
        size: Size(400, 400),
        rotation: 0.0,
      );

      final b = vp.bounds;

      // At equator, bounds should be roughly symmetric
      expect(b.south, closeTo(-b.north, 0.01));
      expect(b.west, closeTo(-b.east, 0.01));
    });

    test('higher zoom produces smaller bounds', () {
      const vpLow = Viewport(
        center: LatLng(latitude: 45.0, longitude: 10.0),
        zoom: 3.0,
        size: Size(400, 300),
        rotation: 0.0,
      );
      const vpHigh = Viewport(
        center: LatLng(latitude: 45.0, longitude: 10.0),
        zoom: 8.0,
        size: Size(400, 300),
        rotation: 0.0,
      );

      final bLow = vpLow.bounds;
      final bHigh = vpHigh.bounds;

      final spanLow = bLow.north - bLow.south;
      final spanHigh = bHigh.north - bHigh.south;

      expect(spanHigh, lessThan(spanLow));
    });
  });
}
