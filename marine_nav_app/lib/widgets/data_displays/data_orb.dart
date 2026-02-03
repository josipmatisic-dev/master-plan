/// DataOrb - Circular glass data display for numeric values.
///
/// Implements Ocean Glass design with size variants and alert states.
library;

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Size variants for DataOrb.
enum DataOrbSize {
  /// Compact orb for dense layouts.
  small,

  /// Default orb size for mixed layouts.
  medium,

  /// Large orb for navigation mode emphasis.
  large,
}

/// Visual state for DataOrb (affects ring color/opacity).
enum DataOrbState {
  /// Normal operational state.
  normal,

  /// Warning state requiring attention.
  alert,

  /// Critical state indicating danger.
  critical,

  /// Inactive/suppressed display.
  inactive,
}

/// DataOrb widget: circular glass display with ring + labels.
class DataOrb extends StatelessWidget {
  const DataOrb({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.subtitle,
    this.size = DataOrbSize.medium,
    this.state = DataOrbState.normal,
    this.progress,
  });

  /// Primary label (e.g., SOG, COG, DEPTH).
  final String label;

  /// Numeric/string value to display.
  final String value;

  /// Unit string (e.g., kts, °, m).
  final String unit;

  /// Optional subtitle (e.g., heading text like WSW).
  final String? subtitle;

  /// Size variant.
  final DataOrbSize size;

  /// Visual state for ring color.
  final DataOrbState state;

  /// Optional progress (0-1) for ring fill; null = full ring.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final dimension = _dimensionForSize(size);
    final ringColor = _ringColorForState(state);
    final inactive = state == DataOrbState.inactive;

    return RepaintBoundary(
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GlassCard(
              padding: GlassCardPadding.none,
              child: SizedBox(
                width: dimension,
                height: dimension,
                child: ClipOval(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: dimension * 0.9,
              height: dimension * 0.9,
              child: CircularProgressIndicator(
                value: progress?.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: ringColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  inactive ? ringColor.withValues(alpha: 0.4) : ringColor,
                ),
              ),
            ),
            _buildContent(inactive),
          ],
        ),
      ),
    );
  }

  Color _ringColorForState(DataOrbState state) {
    switch (state) {
      case DataOrbState.normal:
        return OceanColors.seafoamGreen;
      case DataOrbState.alert:
        return OceanColors.safetyOrange;
      case DataOrbState.critical:
        return OceanColors.coralRed;
      case DataOrbState.inactive:
        return OceanColors.textSecondary;
    }
  }

  double _dimensionForSize(DataOrbSize size) {
    switch (size) {
      case DataOrbSize.small:
        return 80;
      case DataOrbSize.medium:
        return 140;
      case DataOrbSize.large:
        return 200;
    }
  }

  Widget _buildContent(bool inactive) {
    final valueStyle = OceanTextStyles.dataValue.copyWith(
      fontSize: _fontSizeForSize(size),
      color: inactive
          ? OceanColors.textSecondary.withValues(alpha: 0.6)
          : OceanColors.pureWhite,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: valueStyle, textAlign: TextAlign.center),
        const SizedBox(height: OceanDimensions.spacingS),
        Text(
          unit,
          style: OceanTextStyles.labelLarge.copyWith(
            color: inactive
                ? OceanColors.textSecondary.withValues(alpha: 0.6)
                : OceanColors.textSecondary,
          ),
        ),
        Text(
          label,
          style: OceanTextStyles.label.copyWith(
            color: inactive
                ? OceanColors.textSecondary.withValues(alpha: 0.6)
                : OceanColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: OceanDimensions.spacingXS),
          Text(
            subtitle!,
            style: OceanTextStyles.labelSmall.copyWith(
              color: inactive
                  ? OceanColors.textSecondary.withValues(alpha: 0.5)
                  : OceanColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  double _fontSizeForSize(DataOrbSize size) {
    switch (size) {
      case DataOrbSize.small:
        return 32;
      case DataOrbSize.medium:
        return 48;
      case DataOrbSize.large:
        return 56;
    }
  }
}
