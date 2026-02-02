/// Glass Card - Frosted Glass Container
///
/// Base reusable component with Ocean Glass frosted glass effect.
/// Maintains 60 FPS performance using RepaintBoundary.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';

/// Padding size variants for glass cards
enum GlassCardPadding {
  /// Small padding: 12px
  small,

  /// Medium padding: 16px (default)
  medium,

  /// Large padding: 24px
  large,

  /// No padding
  none,
}

/// Glass Card - Frosted glass container component
///
/// Base component for Ocean Glass design system.
/// Uses RepaintBoundary for 60 FPS performance.
///
/// Example:
/// ```dart
/// GlassCard(
///   child: Text('Navigation Data'),
///   padding: GlassCardPadding.medium,
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// Child widget to display inside the glass card
  final Widget child;

  /// Padding variant
  final GlassCardPadding padding;

  /// Use dark glass effect (default: true)
  final bool isDark;

  /// Custom border radius (optional)
  final double? borderRadius;

  /// Enable intense blur for overlays (default: false)
  final bool intenseBlur;

  /// Creates a glass card with optional customization
  const GlassCard({
    super.key,
    required this.child,
    this.padding = GlassCardPadding.medium,
    this.isDark = true,
    this.borderRadius,
    this.intenseBlur = false,
  });

  /// Get padding value based on variant
  double get _paddingValue {
    switch (padding) {
      case GlassCardPadding.small:
        return OceanDimensions.spacingM;
      case GlassCardPadding.medium:
        return OceanDimensions.spacing;
      case GlassCardPadding.large:
        return OceanDimensions.spacingL;
      case GlassCardPadding.none:
        return 0;
    }
  }

  /// Get blur sigma based on intensity
  double get _blurSigma {
    return intenseBlur
        ? OceanDimensions.glassBlurIntense
        : OceanDimensions.glassBlur;
  }

  /// Builds the glass card with frosted glass effect and backdrop filter
  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? OceanDimensions.radius;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? OceanColors.deepNavy.withOpacity(OceanDimensions.glassOpacity)
              : OceanColors.pureWhite
                  .withOpacity(OceanDimensions.glassOpacityLight),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color:
                isDark ? OceanColors.glassBorder : OceanColors.glassBorderLight,
            width: OceanDimensions.glassBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: OceanColors.glassShadow,
              blurRadius: OceanDimensions.shadowBlur,
              offset: const Offset(0, OceanDimensions.shadowOffsetY),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _blurSigma,
              sigmaY: _blurSigma,
            ),
            child: Padding(
              padding: EdgeInsets.all(_paddingValue),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
