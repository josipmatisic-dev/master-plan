/// Viewport model for map state.
library;

import 'dart:ui';

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
