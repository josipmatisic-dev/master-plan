/// CompassWidget - Heading and wind compass for SailStream.
///
/// Simplified implementation with rotating rose indicator and data labels.
library;

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Compass widget showing heading, speed, and wind data.
class CompassWidget extends StatelessWidget {
  const CompassWidget({
    super.key,
    required this.headingDegrees,
    required this.speedKnots,
    required this.windKnots,
    required this.windDirection,
    this.onToggleVr,
    this.isVrEnabled = false,
  });

  /// Current heading in degrees.
  final double headingDegrees;

  /// Boat speed in knots.
  final double speedKnots;

  /// Wind speed in knots.
  final double windKnots;

  /// Wind direction as text (e.g., "N 45°").
  final String windDirection;

  /// Callback when VR toggle pressed.
  final VoidCallback? onToggleVr;

  /// Whether VR mode is enabled.
  final bool isVrEnabled;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: OceanDimensions.radiusL,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildCompassRing(),
            _buildHeadingNeedle(),
            _buildCenterContent(),
            Positioned(
              bottom: OceanDimensions.spacing,
              child: _buildWindInfo(),
            ),
            Positioned(
              top: OceanDimensions.spacing,
              right: OceanDimensions.spacing,
              child: _buildVrButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassRing() {
    return SizedBox(
      width: 200,
      height: 200,
      child: CircularProgressIndicator(
        value: 1,
        strokeWidth: 2,
        valueColor:
            const AlwaysStoppedAnimation<Color>(OceanColors.textSecondary),
        backgroundColor: OceanColors.textSecondary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildHeadingNeedle() {
    return Transform.rotate(
      angle: headingDegrees * (3.1415926535 / 180),
      child: Container(
        width: 8,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            colors: [OceanColors.seafoamGreen, OceanColors.teal],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatHeading(headingDegrees),
          style: OceanTextStyles.heading2,
        ),
        const SizedBox(height: OceanDimensions.spacingS),
        Text(
          '${speedKnots.toStringAsFixed(1)} kts',
          style:
              OceanTextStyles.body.copyWith(color: OceanColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWindInfo() {
    return Column(
      children: [
        Text(
          'Wind',
          style:
              OceanTextStyles.label.copyWith(color: OceanColors.textSecondary),
        ),
        const SizedBox(height: OceanDimensions.spacingXS),
        Text(
          '${windKnots.toStringAsFixed(1)} kts · $windDirection',
          style: OceanTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVrButton() {
    return IconButton(
      onPressed: onToggleVr,
      icon: Icon(
        isVrEnabled ? Icons.vrpano : Icons.vrpano_outlined,
        color:
            isVrEnabled ? OceanColors.seafoamGreen : OceanColors.textSecondary,
      ),
      tooltip: 'Toggle VR',
    );
  }

  String _formatHeading(double heading) {
    final normalized = (heading % 360 + 360) % 360;
    return 'N ${normalized.toStringAsFixed(0)}°';
  }
}
