import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/weather_data.dart';
import '../providers/weather_provider.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/weather/weather_map_view.dart';

/// Screen displaying current weather conditions and forecasts.
class WeatherScreen extends StatelessWidget {
  /// Creates a [WeatherScreen].
  const WeatherScreen({super.key});

  static const _beaufortLabels = [
    'Calm',
    'Light Air',
    'Light Breeze',
    'Gentle Breeze',
    'Moderate Breeze',
    'Fresh Breeze',
    'Strong Breeze',
    'Near Gale',
    'Gale',
    'Strong Gale',
    'Storm',
    'Violent Storm',
    'Hurricane',
  ];

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
          _buildWindCard(wind, cs, tt),
          const SizedBox(height: 12)
        ],
        if (wave != null) ...[
          _buildWaveCard(wave, cs, tt),
          const SizedBox(height: 12)
        ],
        _buildLayerToggles(context, weather, cs, tt),
        const SizedBox(height: 12),
        if (data.hasFrames) ...[
          _buildForecast(data, cs, tt),
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

  Widget _buildWindCard(WindDataPoint wind, ColorScheme cs, TextTheme tt) {
    final beaufort = wind.beaufortScale.clamp(0, 12);
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.air, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          GlowText('Wind Details',
              glowStyle: GlowTextStyle.heading,
              color: cs.primary,
              textStyle: tt.titleMedium),
        ]),
        const SizedBox(height: 12),
        _detailRow(
            'Speed', '${wind.speedKnots.toStringAsFixed(1)} kts', cs, tt),
        _detailRow(
            'Direction',
            '${_compassDirection(wind.directionDegrees)} (${wind.directionDegrees.round()}°)',
            cs,
            tt),
        _detailRow(
            'Beaufort', 'F$beaufort – ${_beaufortLabels[beaufort]}', cs, tt),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: beaufort / 12.0,
            minHeight: 6,
            backgroundColor: cs.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              beaufort >= 8
                  ? cs.error
                  : beaufort >= 5
                      ? cs.primary
                      : cs.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildWaveCard(WaveDataPoint wave, ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.waves, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          GlowText('Wave Details',
              glowStyle: GlowTextStyle.heading,
              color: cs.primary,
              textStyle: tt.titleMedium),
        ]),
        const SizedBox(height: 12),
        _detailRow(
            'Height', '${wave.heightMeters.toStringAsFixed(1)} m', cs, tt),
        _detailRow(
            'Direction',
            '${_compassDirection(wave.directionDegrees)} (${wave.directionDegrees.round()}°)',
            cs,
            tt),
        if (wave.periodSeconds != null)
          _detailRow(
              'Period', '${wave.periodSeconds!.toStringAsFixed(1)} s', cs, tt),
      ]),
    );
  }

  Widget _detailRow(String label, String value, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        Text(value,
            style: tt.bodyLarge
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
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

  Widget _buildForecast(WeatherData data, ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlowText('Hourly Forecast',
            glowStyle: GlowTextStyle.heading,
            color: cs.primary,
            textStyle: tt.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.frames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) =>
                _buildFrameTile(data.frames[i], cs, tt),
          ),
        ),
      ]),
    );
  }

  Widget _buildFrameTile(WeatherFrame frame, ColorScheme cs, TextTheme tt) {
    final hour = '${frame.time.hour.toString().padLeft(2, '0')}:00';
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(hour,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (frame.hasWind)
          Text('${frame.wind!.speedKnots.toStringAsFixed(0)} kts',
              style: tt.bodySmall?.copyWith(color: cs.onSurface)),
        if (frame.hasWind)
          Text(_compassDirection(frame.wind!.directionDegrees),
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
        const SizedBox(height: 4),
        if (frame.hasWave)
          Text('${frame.wave!.heightMeters.toStringAsFixed(1)} m',
              style: tt.bodySmall?.copyWith(color: cs.primary)),
      ]),
    );
  }
}
