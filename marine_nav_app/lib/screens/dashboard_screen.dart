import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/boat_provider.dart';
import '../providers/nmea_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tide_provider.dart';
import '../providers/weather_provider.dart';
import '../services/trip_log_service.dart';
import '../theme/holographic_colors.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/data_displays/tide_card.dart';
import '../widgets/data_displays/trip_control_card.dart';
import '../widgets/effects/holographic_shimmer.dart';
import '../widgets/effects/particle_background.dart';
import '../widgets/effects/scan_line_effect.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/weather_reactive_glass_card.dart';

/// Main dashboard screen showing live marine navigation data.
class DashboardScreen extends StatelessWidget {
  /// Creates a [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final nmea = context.watch<NMEAProvider>();
    final weather = context.watch<WeatherProvider>();
    final boat = context.watch<BoatProvider>();
    final tide = context.watch<TideProvider>();
    final tripLog = context.watch<TripLogService>();
    final data = nmea.currentData;
    final pos = boat.currentPosition;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Holographic background
          if (isHolographic) ...[
            Container(
              decoration: const BoxDecoration(
                gradient: HolographicColors.deepSpaceBackground,
              ),
            ),
            const IgnorePointer(
              child: RepaintBoundary(
                child: ParticleBackground(interactive: false),
              ),
            ),
            const ScanLineEffect(),
          ],
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildHeader(context, cs, nmea.isConnected, isHolographic),
                const SizedBox(height: 16),
                _buildNavOrbs(context, data),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildPositionCard(context, cs, pos, boat),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildWindCard(context, cs, data, weather,
                      isHolographic),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: GlassCard(
                    padding: GlassCardPadding.medium,
                    child: TideCard(
                      tideData: tide.tideData,
                      nextHigh: tide.nextHighTide,
                      nextLow: tide.nextLowTide,
                      isLoading: tide.isLoading,
                      error: tide.error,
                      isHolographic: isHolographic,
                      onRefresh: pos != null
                          ? () => tide.fetchForPosition(
                                latitude: pos.position.latitude,
                                longitude: pos.position.longitude,
                              )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: GlassCard(
                    padding: GlassCardPadding.medium,
                    child: TripControlCard(
                      isRecording: tripLog.isRecording,
                      activeTrip: tripLog.activeTrip,
                      savedTrips: tripLog.savedTrips,
                      isHolographic: isHolographic,
                      onToggleRecording: () {
                        if (tripLog.isRecording) {
                          tripLog.stopTrip();
                        } else {
                          tripLog.startTrip();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(context, cs),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildStatusCard(context, cs, nmea, weather, pos),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool connected,
      bool isHolographic) {
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    return Row(children: [
      Expanded(
        child: GlowText('Dashboard',
            glowStyle: GlowTextStyle.heading, color: cs.primary),
      ),
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: connected ? Colors.green : Colors.red,
        ),
      ),
      const SizedBox(width: 8),
      Text(time,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurface)),
    ]);
  }

  Widget _buildNavOrbs(BuildContext context, dynamic data) {
    final sog = data?.speedOverGroundKnots as double?;
    final cog = data?.courseOverGroundDegrees as double?;
    final depth = data?.depthMeters as double?;
    final hasAny = sog != null || cog != null || depth != null;

    if (!hasAny) {
      final cs = Theme.of(context).colorScheme;
      final tt = Theme.of(context).textTheme;
      return GlassCard(
        padding: GlassCardPadding.medium,
        child: Column(children: [
          Icon(Icons.sensors_off, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('Connect your instruments',
              style: tt.titleMedium?.copyWith(color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('NMEA data will appear here once connected',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    return Row(children: [
      Expanded(
          child: DataOrb(
        label: 'SOG',
        value: sog?.toStringAsFixed(1) ?? '--',
        unit: 'kts',
        size: DataOrbSize.medium,
        state: sog != null ? DataOrbState.normal : DataOrbState.inactive,
      )),
      Expanded(
          child: DataOrb(
        label: 'COG',
        value: cog?.toStringAsFixed(0) ?? '--',
        unit: '°',
        size: DataOrbSize.medium,
        state: cog != null ? DataOrbState.normal : DataOrbState.inactive,
      )),
      Expanded(
          child: DataOrb(
        label: 'DEPTH',
        value: depth?.toStringAsFixed(1) ?? '--',
        unit: 'm',
        size: DataOrbSize.medium,
        state: depth != null
            ? (depth < 3.0 ? DataOrbState.critical : DataOrbState.normal)
            : DataOrbState.inactive,
      )),
    ]);
  }

  Widget _buildPositionCard(
      BuildContext context, ColorScheme cs, dynamic pos, BoatProvider boat) {
    final lat = pos?.position.latitude as double?;
    final lng = pos?.position.longitude as double?;
    final src = boat.source == PositionSource.nmea ? 'NMEA' : 'Phone GPS';
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Position', style: tt.titleMedium?.copyWith(color: cs.primary)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.location_on, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
            lat != null && lng != null
                ? '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
                : 'No fix',
            style: tt.bodyLarge?.copyWith(color: cs.onSurface),
          )),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Source: $src',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          Text('Track: ${boat.trackPointCount} pts',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  Widget _buildWindCard(BuildContext context, ColorScheme cs, dynamic data,
      WeatherProvider weather, bool isHolographic) {
    final windSpd = data?.windSpeedKnots as double?;
    final windDir = data?.windDirectionDegrees as double?;
    final tt = Theme.of(context).textTheme;

    final (String label, Color color) = switch (true) {
      _ when weather.isLoading => ('Loading…', cs.onSurfaceVariant),
      _ when weather.isStale => ('Stale', Colors.orange),
      _ when weather.hasData => ('Current', Colors.green),
      _ => ('No data', cs.onSurfaceVariant),
    };

    // Get average wind/wave from weather API for reactive effects
    final apiWind = weather.hasData && weather.data.windPoints.isNotEmpty
        ? weather.data.windPoints
                .map((p) => p.speedKnots)
                .reduce((a, b) => a + b) /
            weather.data.windPoints.length
        : windSpd ?? 0.0;
    final apiWaveH = weather.hasData && weather.data.wavePoints.isNotEmpty
        ? weather.data.wavePoints
                .map((p) => p.heightMeters)
                .reduce((a, b) => a + b) /
            weather.data.wavePoints.length
        : 0.0;
    final apiWindDir = weather.hasData && weather.data.windPoints.isNotEmpty
        ? weather.data.windPoints.first.directionDegrees
        : windDir ?? 0.0;

    return WeatherReactiveGlassCard(
      windSpeedKnots: apiWind,
      waveHeightMeters: apiWaveH,
      windDirectionDegrees: apiWindDir,
      isHolographic: isHolographic,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Wind & Weather',
            style: tt.titleMedium?.copyWith(color: cs.primary)),
        const SizedBox(height: 8),
        Row(children: [
          if (windDir != null)
            Transform.rotate(
              angle: windDir * math.pi / 180,
              child: Icon(Icons.navigation, size: 24, color: cs.primary),
            )
          else
            Icon(Icons.air, size: 24, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                windSpd != null
                    ? '${windSpd.toStringAsFixed(1)} kts'
                    : '-- kts',
                style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
            Text(windDir != null ? '${windDir.toStringAsFixed(0)}°' : '--°',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: tt.labelSmall?.copyWith(color: color)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme cs) {
    Widget btn(IconData icon, String label, String route) => Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, route),
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
    return Row(children: [
      btn(Icons.map, 'Map', '/map'),
      const SizedBox(width: 8),
      btn(Icons.navigation, 'Navigate', '/navigation'),
      const SizedBox(width: 8),
      btn(Icons.settings, 'Settings', '/settings'),
    ]);
  }

  Widget _buildStatusCard(BuildContext context, ColorScheme cs,
      NMEAProvider nmea, WeatherProvider weather, dynamic pos) {
    final tt = Theme.of(context).textTheme;

    Widget row(String label, String value, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
            const SizedBox(width: 8),
            Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
            const Spacer(),
            Text(value,
                style: tt.bodySmall
                    ?.copyWith(color: c, fontWeight: FontWeight.w600)),
          ]),
        );

    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('System Status',
            style: tt.titleMedium?.copyWith(color: cs.primary)),
        const SizedBox(height: 8),
        row('NMEA', nmea.status.name.toUpperCase(),
            nmea.isConnected ? Colors.green : Colors.red),
        row(
            'Weather',
            weather.hasData ? (weather.isStale ? 'STALE' : 'OK') : 'NO DATA',
            weather.hasData
                ? (weather.isStale ? Colors.orange : Colors.green)
                : cs.onSurfaceVariant),
        row('GPS Fix', pos != null ? 'ACQUIRED' : 'NO FIX',
            pos != null ? Colors.green : Colors.red),
      ]),
    );
  }
}
