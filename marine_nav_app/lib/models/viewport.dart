/// Viewport model for map state.
library;

import 'dart:ui';

import '../services/projection_service.dart';
import 'lat_lng.dart';

/// Immutable viewport describing map center, zoom, size, and rotation.
class Viewport {
  /// Center coordinate of the map.
  final LatLng center;

  /// Zoom level (1-20).
  final double zoom;

  /// Pixel size of the map viewport.
  final Size size;

  /// Rotation in radians (clockwise).
  final double rotation;

  /// Creates a viewport instance.
  const Viewport({
    required this.center,
    required this.zoom,
    required this.size,
    required this.rotation,
  });

  /// Geographic bounding box of this viewport: (south, west, north, east).
  ({double south, double west, double north, double east}) get bounds {
    if (size.isEmpty) {
      return (
        south: center.latitude,
        west: center.longitude,
        north: center.latitude,
        east: center.longitude,
      );
    }
    final topLeft = ProjectionService.screenToLatLng(Offset.zero, this);
    final bottomRight = ProjectionService.screenToLatLng(
      Offset(size.width, size.height),
      this,
    );
    return (
      south: bottomRight.latitude,
      west: topLeft.longitude,
      north: topLeft.latitude,
      east: bottomRight.longitude,
    );
  }

  /// Returns a copy with updated fields.
  Viewport copyWith({
    LatLng? center,
    double? zoom,
    Size? size,
    double? rotation,
  }) {
    return Viewport(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
    );
  }
}
