/// Wind texture generator for WebGL overlay rendering.
///
/// Converts sparse wind data points into a packed RGBA texture image
/// suitable for GPU-accelerated wind particle visualization.
/// The texture encodes u/v wind components in R/G channels, allowing
/// WebGL shaders to sample wind vectors at any position.
// ignore_for_file: avoid_classes_with_only_static_members
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/weather_data.dart';

/// Result of wind texture generation, containing the encoded image
/// and metadata needed by the WebGL layer.
class WindTextureData {
  /// Base64-encoded PNG image (R=u, G=v, normalized to 0-255).
  final String base64Png;

  /// Minimum u-component value (m/s) mapped to pixel value 0.
  final double uMin;

  /// Maximum u-component value (m/s) mapped to pixel value 255.
  final double uMax;

  /// Minimum v-component value (m/s) mapped to pixel value 0.
  final double vMin;

  /// Maximum v-component value (m/s) mapped to pixel value 255.
  final double vMax;

  /// Grid width in pixels.
  final int width;

  /// Grid height in pixels.
  final int height;

  /// Geographic bounds of the texture.
  final double south, north, west, east;

  /// Creates wind texture data.
  const WindTextureData({
    required this.base64Png,
    required this.uMin,
    required this.uMax,
    required this.vMin,
    required this.vMax,
    required this.width,
    required this.height,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });
}

/// Result of wave texture generation for WebGL heatmap.
class WaveTextureData {
  /// GeoJSON FeatureCollection string for MapLibre heatmap layer.
  final String geoJson;

  /// Maximum wave height in the dataset (for normalization).
  final double maxHeight;

  /// Creates wave texture data.
  const WaveTextureData({
    required this.geoJson,
    required this.maxHeight,
  });
}

/// Generates GPU-ready textures from weather data points.
class WindTextureGenerator {
  /// Default texture resolution (pixels per axis).
  static const int defaultResolution = 64;

  /// Converts wind speed (knots) + direction (degrees) to u-component (m/s).
  ///
  /// Meteorological convention: direction is where wind comes FROM.
  /// u = east-west component (positive = from west / blowing east).
  static double windU(double speedKnots, double directionDeg) {
    final speedMs = speedKnots * 0.514444;
    final rad = directionDeg * math.pi / 180.0;
    // Wind FROM direction → negate to get flow direction
    return -speedMs * math.sin(rad);
  }

  /// Converts wind speed (knots) + direction (degrees) to v-component (m/s).
  ///
  /// v = north-south component (positive = from south / blowing north).
  static double windV(double speedKnots, double directionDeg) {
    final speedMs = speedKnots * 0.514444;
    final rad = directionDeg * math.pi / 180.0;
    return -speedMs * math.cos(rad);
  }

  /// Generates a wind texture from sparse wind data points.
  ///
  /// Uses IDW (inverse distance weighting) to interpolate a regular grid
  /// from the sparse input points. The grid is encoded as an RGBA PNG
  /// where R=u and G=v, normalized to [0,255] using uMin/uMax/vMin/vMax.
  ///
  /// Returns null if [windPoints] is empty.
  static Future<WindTextureData?> generate({
    required List<WindDataPoint> windPoints,
    required double south,
    required double north,
    required double west,
    required double east,
    int resolution = defaultResolution,
  }) async {
    if (windPoints.isEmpty) return null;

    final width = resolution;
    final height = resolution;

    // Convert all points to u/v
    final uvPoints = <({double lat, double lng, double u, double v})>[];
    for (final wp in windPoints) {
      uvPoints.add((
        lat: wp.position.latitude,
        lng: wp.position.longitude,
        u: windU(wp.speedKnots, wp.directionDegrees),
        v: windV(wp.speedKnots, wp.directionDegrees),
      ));
    }

    // Build the interpolated grid
    final uGrid = Float64List(width * height);
    final vGrid = Float64List(width * height);

    final latStep = (north - south) / height;
    final lngStep = (east - west) / width;

    for (var y = 0; y < height; y++) {
      final lat = north - y * latStep; // top-down
      for (var x = 0; x < width; x++) {
        final lng = west + x * lngStep;
        final idx = y * width + x;
        final (u, v) = _idwInterpolate(lat, lng, uvPoints);
        uGrid[idx] = u;
        vGrid[idx] = v;
      }
    }

    // Find min/max for normalization
    var uMin = double.infinity, uMax = double.negativeInfinity;
    var vMin = double.infinity, vMax = double.negativeInfinity;
    for (var i = 0; i < uGrid.length; i++) {
      if (uGrid[i] < uMin) uMin = uGrid[i];
      if (uGrid[i] > uMax) uMax = uGrid[i];
      if (vGrid[i] < vMin) vMin = vGrid[i];
      if (vGrid[i] > vMax) vMax = vGrid[i];
    }

    // Ensure non-zero range
    if (uMax == uMin) {
      uMax = uMin + 1;
    }
    if (vMax == vMin) {
      vMax = vMin + 1;
    }

    // Encode to RGBA pixels (R=u, G=v, B=0, A=255)
    final pixels = Uint8List(width * height * 4);
    for (var i = 0; i < uGrid.length; i++) {
      final uNorm = ((uGrid[i] - uMin) / (uMax - uMin) * 255).round();
      final vNorm = ((vGrid[i] - vMin) / (vMax - vMin) * 255).round();
      pixels[i * 4 + 0] = uNorm.clamp(0, 255); // R = u
      pixels[i * 4 + 1] = vNorm.clamp(0, 255); // G = v
      pixels[i * 4 + 2] = 0; // B unused
      pixels[i * 4 + 3] = 255; // A = opaque
    }

    // Encode to PNG via dart:ui
    final base64Png = await _encodePng(pixels, width, height);

    return WindTextureData(
      base64Png: base64Png,
      uMin: uMin,
      uMax: uMax,
      vMin: vMin,
      vMax: vMax,
      width: width,
      height: height,
      south: south,
      north: north,
      west: west,
      east: east,
    );
  }

  /// Generates GeoJSON from wave data points for MapLibre heatmap layer.
  static WaveTextureData? generateWaveGeoJson(List<WaveDataPoint> wavePoints) {
    if (wavePoints.isEmpty) return null;

    var maxHeight = 0.0;
    final features = <Map<String, dynamic>>[];

    for (final wp in wavePoints) {
      if (wp.heightMeters > maxHeight) maxHeight = wp.heightMeters;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [wp.position.longitude, wp.position.latitude],
        },
        'properties': {
          'height': wp.heightMeters,
          'direction': wp.directionDegrees,
          'period': wp.periodSeconds ?? 0,
        },
      });
    }

    final geoJson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    return WaveTextureData(geoJson: geoJson, maxHeight: maxHeight);
  }

  /// IDW interpolation for a single point from sparse data.
  static (double u, double v) _idwInterpolate(
    double lat,
    double lng,
    List<({double lat, double lng, double u, double v})> points,
  ) {
    var wSum = 0.0;
    var uSum = 0.0;
    var vSum = 0.0;

    for (final p in points) {
      final dLat = lat - p.lat;
      final dLng = lng - p.lng;
      final d2 = dLat * dLat + dLng * dLng;

      if (d2 < 1e-10) return (p.u, p.v);

      final w = 1.0 / d2; // IDW power=2
      wSum += w;
      uSum += w * p.u;
      vSum += w * p.v;
    }

    return wSum > 0 ? (uSum / wSum, vSum / wSum) : (0.0, 0.0);
  }

  /// Encodes raw RGBA pixel data to a base64 PNG string.
  static Future<String> _encodePng(
      Uint8List pixels, int width, int height) async {
    final completer = ui.ImmutableBuffer.fromUint8List(pixels);
    final buffer = await completer;

    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();

    if (byteData == null) {
      throw StateError('Failed to encode wind texture to PNG');
    }

    return base64Encode(byteData.buffer.asUint8List());
  }
}
