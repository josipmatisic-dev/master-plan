import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

/// Course Deviation Indicator — shows XTE offset from planned track.
class CourseDeviationIndicator extends StatelessWidget {
  /// Cross-track error in nautical miles (+ right, − left).
  final double xte;

  /// Creates a [CourseDeviationIndicator].
  const CourseDeviationIndicator({super.key, required this.xte});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clamped = xte.clamp(-0.5, 0.5);
    final fraction = (clamped / 0.5 + 1) / 2; // 0.0 = full left, 1.0 = right
    final label = xte.abs() < 0.01
        ? 'On Track'
        : '${xte.abs().toStringAsFixed(2)} nm ${xte > 0 ? 'R' : 'L'}';
    final color = xte.abs() < 0.05
        ? Colors.green
        : xte.abs() < 0.2
            ? Colors.amber
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('XTE: $label', style: OceanTextStyles.bodySmall),
          const SizedBox(height: 2),
          SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Align(
                  child: Container(width: 2, color: OceanColors.pureWhite),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
