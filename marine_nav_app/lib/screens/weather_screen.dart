import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_data.dart';
import '../providers/theme_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/holographic_colors.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/effects/holographic_shimmer.dart';
import '../widgets/effects/particle_background.dart';
import '../widgets/effects/scan_line_effect.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/weather/forecast_timeline.dart';
import '../widgets/weather/timeline_scrubber.dart';
import '../widgets/weather/weather_detail_cards.dart';
import '../widgets/weather/weather_map_view.dart';

/// Screen displaying current weather conditions and forecasts.
class WeatherScreen extends StatelessWidget {
  /// Creates a [WeatherScreen].
  const WeatherScreen({super.key});

  static String _compassDirection(double degrees) {
    const dirs = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW'
    ];
    return dirs[((degrees % 360) / 22.5).round() % 16];
  }

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasData = weather.hasData;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          const Positioned.fill(
            child: WeatherMapView(
              height: null,
              showScrubber: false,
            ),
          ),
          if (isHolographic)
            const Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ParticleBackground(
                    interactive: false,
                    particleCount: 30,
                  ),
                ),
              ),
            ),
          if (isHolographic) const Positioned.fill(child: ScanLineEffect()),
          _buildTopBar(context, weather, cs, isHolographic),
          if (!hasData)
            _buildFallbackOverlay(context, weather, cs, tt)
          else
            _buildBottomSheet(context, weather, cs, tt, isHolographic),
        ],
      ),
    );
  }

  Widget _buildCurrentConditions(
      WindDataPoint? wind, WaveDataPoint? wave, ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlowText('Current Conditions',
            glowStyle: GlowTextStyle.heading,
            color: cs.primary,
            textStyle: tt.titleMedium),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Flexible(
            child: DataOrb(
              label: 'Wind',
              value: wind != null ? wind.speedKnots.toStringAsFixed(1) : '--',
              unit: 'kts',
              size: DataOrbSize.small,
              state: wind != null && wind.beaufortScale >= 7
                  ? DataOrbState.alert
                  : DataOrbState.normal,
            ),
          ),
          Flexible(
            child: DataOrb(
              label: 'Waves',
              value: wave != null ? wave.heightMeters.toStringAsFixed(1) : '--',
              unit: 'm',
              size: DataOrbSize.small,
              state: wave != null && wave.heightMeters >= 3.0
                  ? DataOrbState.alert
                  : DataOrbState.normal,
            ),
          ),
          Flexible(
            child: DataOrb(
              label: 'Wind Dir',
              value: wind != null
                  ? _compassDirection(wind.directionDegrees)
                  : '--',
              unit: wind != null ? '${wind.directionDegrees.round()}°' : '',
              size: DataOrbSize.small,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildTopBar(BuildContext context, WeatherProvider weather,
      ColorScheme cs, bool isHolographic) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            HolographicShimmer(
              enabled: isHolographic,
              child: GlassCard(
                padding: GlassCardPadding.small,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    GlowText('Weather',
                        glowStyle: GlowTextStyle.heading,
                        color: isHolographic
                            ? HolographicColors.electricBlue
                            : cs.primary),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (weather.isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (weather.isStale)
              Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, WeatherProvider weather,
      ColorScheme cs, TextTheme tt, bool isHolographic) {
    final data = weather.data;
    final wind = data.windPoints.isNotEmpty ? data.windPoints.first : null;
    final wave = data.wavePoints.isNotEmpty ? data.wavePoints.first : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.22,
      maxChildSize: 0.65,
      builder: (ctx, controller) {
        return Container(
          decoration: BoxDecoration(
            color: (isHolographic ? HolographicColors.cosmicBlack : cs.surface)
                .withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: isHolographic
                    ? HolographicColors.electricBlue.withValues(alpha: 0.15)
                    : Colors.black26,
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const TimelineScrubber(),
              const SizedBox(height: 12),
              _buildCurrentConditions(wind, wave, cs, tt),
              const SizedBox(height: 12),
              if (wind != null) ...[
                WindDetailCard(wind: wind),
                const SizedBox(height: 12)
              ],
              if (wave != null) ...[
                WaveDetailCard(wave: wave),
                const SizedBox(height: 12)
              ],
              _buildLayerToggles(context, weather, cs, tt),
              const SizedBox(height: 12),
              if (data.hasFrames) ...[
                ForecastTimeline(data: data),
                const SizedBox(height: 4),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackOverlay(BuildContext context, WeatherProvider weather,
      ColorScheme cs, TextTheme tt) {
    if (weather.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (weather.errorMessage != null) {
      return Center(
        child: GlassCard(
          padding: GlassCardPadding.medium,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(weather.errorMessage!,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      );
    }
    return Center(
      child: GlassCard(
        padding: GlassCardPadding.medium,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('No weather data available',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerToggles(BuildContext context, WeatherProvider weather,
      ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlowText('Map Layers',
            glowStyle: GlowTextStyle.heading,
            color: cs.primary,
            textStyle: tt.titleMedium),
        const SizedBox(height: 8),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('Wind Layer',
              style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
          secondary: Icon(Icons.air, color: cs.primary),
          activeThumbColor: cs.primary,
          value: weather.isWindVisible,
          onChanged: (_) => weather.toggleLayer(WeatherLayer.wind),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('Wave Layer',
              style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
          secondary: Icon(Icons.waves, color: cs.primary),
          activeThumbColor: cs.primary,
          value: weather.isWaveVisible,
          onChanged: (_) => weather.toggleLayer(WeatherLayer.wave),
        ),
      ]),
    );
  }
}
