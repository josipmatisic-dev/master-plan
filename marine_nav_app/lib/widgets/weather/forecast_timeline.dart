import 'package:flutter/material.dart';

import '../../models/weather_data.dart';
import '../common/glow_text.dart';
import '../glass/glass_card.dart';

/// Horizontal scrollable forecast timeline showing hourly weather frames.
class ForecastTimeline extends StatelessWidget {
  /// The weather data containing forecast frames.
  final WeatherData data;

  /// Creates a [ForecastTimeline].
  const ForecastTimeline({super.key, required this.data});

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          Text('${frame.windPoints.first.speedKnots.toStringAsFixed(0)} kts',
              style: tt.bodySmall?.copyWith(color: cs.onSurface)),
        if (frame.hasWind)
          Text(_compassDirection(frame.windPoints.first.directionDegrees),
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10)),
        const SizedBox(height: 4),
        if (frame.hasWave)
          Text('${frame.wavePoints.first.heightMeters.toStringAsFixed(1)} m',
              style: tt.bodySmall?.copyWith(color: cs.primary)),
      ]),
    );
  }
}
