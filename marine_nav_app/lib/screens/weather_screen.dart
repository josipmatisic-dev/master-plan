import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_data.dart';
import '../providers/weather_provider.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/weather/forecast_timeline.dart';
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GlowText('Weather',
            glowStyle: GlowTextStyle.heading, color: cs.primary),
        actions: [
          if (weather.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (weather.isStale)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child:
                  Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, weather, cs, tt),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WeatherProvider weather,
      ColorScheme cs, TextTheme tt) {
    if (weather.errorMessage != null && !weather.hasData) {
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

    if (!weather.hasData && !weather.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No weather data available',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (!weather.hasData && weather.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = weather.data;
    final wind = data.windPoints.isNotEmpty ? data.windPoints.first : null;
    final wave = data.wavePoints.isNotEmpty ? data.wavePoints.first : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Weather map with timeline scrubber
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const WeatherMapView(height: 240),
        ),
        const SizedBox(height: 16),
        _buildCurrentConditions(wind, wave, cs, tt),
        const SizedBox(height: 16),
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
          const SizedBox(height: 16)
        ],
      ],
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
          DataOrb(
            label: 'Wind',
            value: wind != null ? wind.speedKnots.toStringAsFixed(1) : '--',
            unit: 'kts',
            size: DataOrbSize.medium,
            state: wind != null && wind.beaufortScale >= 7
                ? DataOrbState.alert
                : DataOrbState.normal,
          ),
          DataOrb(
            label: 'Waves',
            value: wave != null ? wave.heightMeters.toStringAsFixed(1) : '--',
            unit: 'm',
            size: DataOrbSize.medium,
            state: wave != null && wave.heightMeters >= 3.0
                ? DataOrbState.alert
                : DataOrbState.normal,
          ),
          DataOrb(
            label: 'Wind Dir',
            value:
                wind != null ? _compassDirection(wind.directionDegrees) : '--',
            unit: wind != null ? '${wind.directionDegrees.round()}°' : '',
            size: DataOrbSize.medium,
          ),
        ]),
      ]),
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
