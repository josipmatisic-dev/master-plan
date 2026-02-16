/// WeatherLayerStack — composes all 7 visual layers into a unified Stack.
///
/// Replaces MapWebView in screens, providing map + weather effects
/// as a single composable widget.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/weather_provider.dart';
import 'fog_overlay.dart';
import 'lightning_overlay.dart';
import 'maplibre_map_widget.dart';
import 'ocean_surface_overlay.dart';
import 'rain_overlay.dart';
import 'wind_particle_overlay.dart';

/// Composites all visual layers into a single Stack widget.
///
/// Layer order (bottom to top):
/// 1. Map (maplibre_gl)
/// 2. Ocean surface caustics (GLSL)
/// 3. Wind flow particles (CustomPainter)
/// 4. Fog/atmosphere (GLSL)
/// 5. Rain/snow/hail (GLSL)
/// 6. Lightning/thunder (CustomPainter + flash)
/// 7. UI overlays (handled by parent screen, not this widget)
class WeatherLayerStack extends StatelessWidget {
  /// Map height — null for Positioned.fill usage.
  final double? height;

  const WeatherLayerStack({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final weather = context.watch<WeatherProvider>();

    // Extract weather conditions for layer parameters
    final windPoints = weather.data.windPoints;
    final wavePoints = weather.data.wavePoints;
    final hasWeather = weather.hasData;

    // Compute average wind speed/direction for rain angle
    double avgWindAngle = 0;
    double avgWindSpeed = 0;
    if (windPoints.isNotEmpty) {
      double sinSum = 0, cosSum = 0, speedSum = 0;
      for (final wp in windPoints) {
        final rad = wp.directionDegrees * math.pi / 180.0;
        sinSum += math.sin(rad);
        cosSum += math.cos(rad);
        speedSum += wp.speedKnots;
      }
      avgWindAngle = math.atan2(sinSum, cosSum);
      avgWindSpeed = speedSum / windPoints.length;
    }

    // Compute average wave height for ocean intensity
    double waveIntensity = 0;
    if (wavePoints.isNotEmpty) {
      double sum = 0;
      for (final wp in wavePoints) {
        sum += wp.heightMeters;
      }
      // Normalize: 0m=0.0, 4m+=1.0
      waveIntensity = (sum / wavePoints.length / 4.0).clamp(0.0, 1.0);
    }

    // Compute wind data bounds for particle overlay
    ({double south, double north, double west, double east})? windBounds;
    if (windPoints.length >= 2) {
      double south = 90, north = -90, west = 180, east = -180;
      for (final wp in windPoints) {
        if (wp.position.latitude < south) south = wp.position.latitude;
        if (wp.position.latitude > north) north = wp.position.latitude;
        if (wp.position.longitude < west) west = wp.position.longitude;
        if (wp.position.longitude > east) east = wp.position.longitude;
      }
      windBounds = (south: south, north: north, west: west, east: east);
    }

    // TODO: These values would come from actual weather conditions
    // For now, derive from wind speed as a rough proxy
    final precipIntensity = hasWeather ? (avgWindSpeed > 20 ? 0.6 : 0.0) : 0.0;
    final fogDensity = 0.0; // Will be driven by visibility data
    final stormIntensity = hasWeather ? (avgWindSpeed > 30 ? 0.5 : 0.0) : 0.0;

    final stack = Stack(
      children: [
        // Layer 1: Map
        const Positioned.fill(child: MapLibreMapWidget()),

        // Layer 2: Ocean surface caustics
        if (hasWeather || waveIntensity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: OceanSurfaceOverlay(
                waveIntensity: waveIntensity,
                isHolographic: isHolographic,
              ),
            ),
          ),

        // Layer 3: Wind flow particles
        if (windPoints.isNotEmpty && weather.isWindVisible)
          Positioned.fill(
            child: IgnorePointer(
              child: WindParticleOverlay(
                windPoints: windPoints,
                isHolographic: isHolographic,
                bounds: windBounds,
              ),
            ),
          ),

        // Layer 4: Fog/atmosphere
        if (fogDensity > 0.01)
          Positioned.fill(
            child: IgnorePointer(
              child: FogOverlay(
                fogDensity: fogDensity,
                isHolographic: isHolographic,
              ),
            ),
          ),

        // Layer 5: Rain/snow/hail
        if (precipIntensity > 0.01)
          Positioned.fill(
            child: IgnorePointer(
              child: RainOverlay(
                intensity: precipIntensity,
                windAngle: avgWindAngle,
                windSpeed: avgWindSpeed,
                isHolographic: isHolographic,
              ),
            ),
          ),

        // Layer 6: Lightning
        if (stormIntensity > 0.01)
          Positioned.fill(
            child: IgnorePointer(
              child: LightningOverlay(
                stormIntensity: stormIntensity,
                isHolographic: isHolographic,
              ),
            ),
          ),
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: stack);
    }
    return stack;
  }
}
