/// WeatherLayerStack — composes all 7 visual layers into a unified Stack.
///
/// Replaces MapWebView in screens, providing map + weather effects
/// as a single composable widget.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ais_provider.dart';
import '../../providers/boat_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/weather_provider.dart';
import 'ais_target_overlay.dart';
import 'boat_marker_overlay.dart';
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
/// 2. Ocean surface caustics (GLSL) — only when wave data exists
/// 3. Wind flow particles (CustomPainter) — geographic, viewport-aware
/// 3.5. AIS vessel targets (CustomPainter) — colored by threat level
/// 3.7. Own vessel marker + track trail (CustomPainter)
/// 4. Fog/atmosphere (GLSL)
/// 5. Rain/snow/hail (GLSL)
/// 6. Lightning/thunder (CustomPainter + flash)
/// 7. UI overlays (handled by parent screen, not this widget)
class WeatherLayerStack extends StatelessWidget {
  /// Map height — null for Positioned.fill usage.
  final double? height;

  /// Creates a weather layer stack.
  const WeatherLayerStack({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final weather = context.watch<WeatherProvider>();
    final mapProvider = context.watch<MapProvider>();
    final aisProvider = context.watch<AisProvider>();
    final boatProvider = context.watch<BoatProvider>();

    final windPoints = weather.data.windPoints;
    final wavePoints = weather.data.wavePoints;
    final hasWind = windPoints.isNotEmpty && weather.isWindVisible;
    final hasWaves = wavePoints.isNotEmpty;

    // Use MapProvider viewport bounds for geographic overlay positioning
    final vp = mapProvider.viewport;
    final vpBounds = vp.size.isEmpty ? null : vp.bounds;
    final geoBounds = vpBounds != null
        ? (
            south: vpBounds.south,
            north: vpBounds.north,
            west: vpBounds.west,
            east: vpBounds.east,
          )
        : null;

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

    // Compute wave intensity from data
    double waveIntensity = 0;
    if (hasWaves) {
      double sum = 0;
      for (final wp in wavePoints) {
        sum += wp.heightMeters;
      }
      waveIntensity = (sum / wavePoints.length / 4.0).clamp(0.0, 1.0);
    }

    // Derive precipitation from wind speed + wave height (proxy until
    // we have actual precip/visibility data from API)
    final precipIntensity = avgWindSpeed >= 34
        ? 0.9
        : avgWindSpeed >= 25
            ? 0.6
            : avgWindSpeed >= 15
                ? 0.3
                : avgWindSpeed >= 8
                    ? 0.1
                    : 0.0;

    // Fog density derived from wave height (proxy for visibility)
    final fogDensity = waveIntensity >= 0.8
        ? 0.7
        : waveIntensity >= 0.5
            ? 0.4
            : waveIntensity >= 0.3
                ? 0.15
                : 0.0;

    final stormIntensity = avgWindSpeed >= 34
        ? 0.8
        : avgWindSpeed >= 25
            ? 0.4
            : 0.0;

    final stack = Stack(
      children: [
        // Layer 1: Map
        const Positioned.fill(child: MapLibreMapWidget()),

        // Layer 2: Ocean surface caustics — only when wave data exists
        if (hasWaves)
          Positioned.fill(
            child: IgnorePointer(
              child: OceanSurfaceOverlay(
                waveIntensity: waveIntensity,
                isHolographic: isHolographic,
              ),
            ),
          ),

        // Layer 3: Wind flow particles — geographic, viewport-aware
        if (hasWind && geoBounds != null)
          Positioned.fill(
            child: IgnorePointer(
              child: WindParticleOverlay(
                windPoints: windPoints,
                isHolographic: isHolographic,
                bounds: geoBounds,
              ),
            ),
          ),

        // Layer 3.5: AIS vessel targets — above wind, below atmosphere
        if (geoBounds != null && aisProvider.targets.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AisTargetOverlay(
                targets: aisProvider.targets,
                bounds: geoBounds,
                zoom: vp.zoom,
                isHolographic: isHolographic,
              ),
            ),
          ),

        // Layer 3.7: Own vessel marker + track trail
        if (geoBounds != null && boatProvider.currentPosition != null)
          Positioned.fill(
            child: IgnorePointer(
              child: BoatMarkerOverlay(
                position: boatProvider.currentPosition,
                trackHistory: boatProvider.trackHistory,
                showTrack: boatProvider.showTrack,
                bounds: geoBounds,
                zoom: vp.zoom,
                isHolographic: isHolographic,
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
