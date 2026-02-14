/// Glass Card - Theme-Aware Frosted Glass Container
///
/// Automatically adapts between Ocean Glass and Holographic Cyberpunk styles
/// based on the active theme variant. Uses RepaintBoundary for 60 FPS.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/holographic_colors.dart';

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

/// Glass Card - Theme-aware frosted glass container
///
/// Reads theme variant from ThemeProvider and applies:
/// - Ocean Glass: subtle blur, muted border
/// - Holographic: neon glow border, deeper blur, purple-tinted glass
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

  /// Creates a glass card with frosted glass effect
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

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final radius = borderRadius ?? OceanDimensions.radius;
    final blurSigma = isHolographic
        ? 20.0
        : (intenseBlur
            ? OceanDimensions.glassBlurIntense
            : OceanDimensions.glassBlur);

    return RepaintBoundary(
      child: Container(
        decoration: isHolographic
            ? _holographicDecoration(radius)
            : _oceanDecoration(radius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Padding(
              padding: EdgeInsets.all(_paddingValue),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _oceanDecoration(double radius) {
    return BoxDecoration(
      color: isDark
          ? OceanColors.deepNavy.withValues(alpha: OceanDimensions.glassOpacity)
          : OceanColors.pureWhite
              .withValues(alpha: OceanDimensions.glassOpacityLight),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? OceanColors.glassBorder : OceanColors.glassBorderLight,
        width: OceanDimensions.glassBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: OceanColors.glassShadow,
          blurRadius: OceanDimensions.shadowBlur,
          offset: const Offset(0, OceanDimensions.shadowOffsetY),
        ),
      ],
    );
  }

  BoxDecoration _holographicDecoration(double radius) {
    return BoxDecoration(
      color: HolographicColors.spaceNavy.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: HolographicColors.electricBlue.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        // Inner glow
        BoxShadow(
          color: HolographicColors.electricBlue.withValues(alpha: 0.15),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        // Outer neon glow
        BoxShadow(
          color: HolographicColors.electricBlue.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
