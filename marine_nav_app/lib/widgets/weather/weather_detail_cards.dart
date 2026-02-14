import 'package:flutter/material.dart';

import '../../models/weather_data.dart';
import '../common/glow_text.dart';
import '../glass/glass_card.dart';

/// Card showing detailed wind information with Beaufort scale bar.
class WindDetailCard extends StatelessWidget {
  /// The wind data point to display.
  final WindDataPoint wind;

  /// Creates a [WindDetailCard].
  const WindDetailCard({super.key, required this.wind});

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
        _row('Speed', '${wind.speedKnots.toStringAsFixed(1)} kts', cs, tt),
        _row(
            'Direction',
            '${_compassDirection(wind.directionDegrees)} (${wind.directionDegrees.round()}°)',
            cs,
            tt),
        _row('Beaufort', 'F$beaufort – ${_beaufortLabels[beaufort]}', cs, tt),
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

  Widget _row(String label, String value, ColorScheme cs, TextTheme tt) {
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
}

/// Card showing detailed wave information.
class WaveDetailCard extends StatelessWidget {
  /// The wave data point to display.
  final WaveDataPoint wave;

  /// Creates a [WaveDetailCard].
  const WaveDetailCard({super.key, required this.wave});

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
        Row(children: [
          Icon(Icons.waves, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          GlowText('Wave Details',
              glowStyle: GlowTextStyle.heading,
              color: cs.primary,
              textStyle: tt.titleMedium),
        ]),
        const SizedBox(height: 12),
        _row('Height', '${wave.heightMeters.toStringAsFixed(1)} m', cs, tt),
        _row(
            'Direction',
            '${_compassDirection(wave.directionDegrees)} (${wave.directionDegrees.round()}°)',
            cs,
            tt),
        if (wave.periodSeconds != null)
          _row('Period', '${wave.periodSeconds!.toStringAsFixed(1)} s', cs, tt),
      ]),
    );
  }

  Widget _row(String label, String value, ColorScheme cs, TextTheme tt) {
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
}
