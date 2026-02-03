// ignore_for_file: avoid_classes_with_only_static_members

/// Projection service for coordinate transforms.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../models/lat_lng.dart';
import '../models/viewport.dart';

/// Projection service for EPSG:4326 ↔ EPSG:3857 and screen transforms.
class ProjectionService {
  /// Web Mercator earth radius in meters.
  static const double earthRadius = 6378137.0;

  /// Maximum latitude supported by Web Mercator.
  static const double maxLatitude = 85.05112878;

  /// Tile size in pixels.
  static const double tileSize = 256.0;

  /// Converts a LatLng into world pixel coordinates at a zoom level.
  static Offset latLngToWorld(LatLng position, double zoom) {
    final clampedLat = position.latitude.clamp(-maxLatitude, maxLatitude);
    final scale = _scale(zoom);
    final x = (position.longitude + 180.0) / 360.0 * scale;
    final latRad = _degToRad(clampedLat);
    final y =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            scale;
    return Offset(x, y);
  }

  /// Converts world pixel coordinates into LatLng at a zoom level.
  static LatLng worldToLatLng(Offset world, double zoom) {
    final scale = _scale(zoom);
    final lng = world.dx / scale * 360.0 - 180.0;
    final n = math.pi - 2.0 * math.pi * world.dy / scale;
    final lat = _radToDeg(math.atan(_sinh(n)));
    return LatLng(latitude: lat, longitude: lng);
  }

  /// Converts LatLng to screen coordinates for a viewport.
  static Offset latLngToScreen(LatLng position, Viewport viewport) {
    final world = latLngToWorld(position, viewport.zoom);
    final centerWorld = latLngToWorld(viewport.center, viewport.zoom);
    var dx = world.dx - centerWorld.dx;
    var dy = world.dy - centerWorld.dy;

    if (viewport.rotation != 0) {
      final cosTheta = math.cos(viewport.rotation);
      final sinTheta = math.sin(viewport.rotation);
      final rotatedX = dx * cosTheta - dy * sinTheta;
      final rotatedY = dx * sinTheta + dy * cosTheta;
      dx = rotatedX;
      dy = rotatedY;
    }

    final screenX = viewport.size.width / 2 + dx;
    final screenY = viewport.size.height / 2 + dy;
    return Offset(screenX, screenY);
  }

  /// Converts screen coordinates to LatLng for a viewport.
  static LatLng screenToLatLng(Offset screen, Viewport viewport) {
    var dx = screen.dx - viewport.size.width / 2;
    var dy = screen.dy - viewport.size.height / 2;

    if (viewport.rotation != 0) {
      final cosTheta = math.cos(-viewport.rotation);
      final sinTheta = math.sin(-viewport.rotation);
      final rotatedX = dx * cosTheta - dy * sinTheta;
      final rotatedY = dx * sinTheta + dy * cosTheta;
      dx = rotatedX;
      dy = rotatedY;
    }

    final centerWorld = latLngToWorld(viewport.center, viewport.zoom);
    final world = Offset(centerWorld.dx + dx, centerWorld.dy + dy);
    return worldToLatLng(world, viewport.zoom);
  }

  static double _scale(double zoom) => tileSize * math.pow(2, zoom).toDouble();

  static double _degToRad(double deg) => deg * math.pi / 180.0;

  static double _radToDeg(double rad) => rad * 180.0 / math.pi;

  static double _sinh(double value) {
    return (math.exp(value) - math.exp(-value)) / 2.0;
  }
}
