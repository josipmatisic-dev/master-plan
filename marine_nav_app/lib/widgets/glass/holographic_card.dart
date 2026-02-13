/// Holographic Card - Neon Glow Glass Container
///
/// High-performance holographic glassmorphism component with neon glow effects.
/// Combines cyberpunk aesthetics with smooth hover/tap interactions.
/// Maintains 60 FPS performance using RepaintBoundary.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/dimensions.dart';
import '../../theme/holographic_colors.dart';
import '../../theme/holographic_effects.dart';

/// Padding size variants for holographic cards (matches GlassCard)
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

/// Holographic Card - Neon glow glass container component
///
/// High-performance cyberpunk-themed glassmorphism card with:
/// - 3-layer neon glow effect
/// - Smooth hover/tap state transitions
/// - Electric Blue neon border
/// - 20px backdrop blur (stronger than Ocean Glass)
/// - 60 FPS performance via RepaintBoundary
///
/// Example:
/// ```dart
/// HolographicCard(
///   child: Text('Navigation Data'),
///   padding: GlassCardPadding.medium,
///   enableHover: true,
/// )
/// ```
class HolographicCard extends StatefulWidget {
  /// Child widget to display inside the holographic card
  final Widget child;

  /// Padding variant
  final GlassCardPadding padding;

  /// Custom border radius (optional, default: 16px)
  final double? borderRadius;

  /// Enable hover/tap effects (default: true)
  final bool enableHover;

  /// Creates a holographic card with neon glow effects
  const HolographicCard({
    super.key,
    required this.child,
    this.padding = GlassCardPadding.medium,
    this.borderRadius,
    this.enableHover = true,
  });

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard> {
  /// Track pressed state for hover/tap effects
  bool _isPressed = false;

  /// Get padding value based on variant
  double get _paddingValue {
    switch (widget.padding) {
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

  /// Get border opacity based on pressed state
  double get _borderOpacity {
    return _isPressed ? 0.5 : 0.3;
  }

  /// Get glow intensity multiplier based on pressed state
  double get _glowIntensity {
    return _isPressed ? 2.0 : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? OceanDimensions.radius;

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: widget.enableHover ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enableHover ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.enableHover ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            // Glass background: Space Navy @ 15% opacity
            color: HolographicColors.glassBackground,
            borderRadius: BorderRadius.circular(radius),
            // Electric Blue border with animated opacity
            border: Border.all(
              color: HolographicColors.electricBlue.withValues(
                alpha: _borderOpacity,
              ),
              width: 1.5,
            ),
            // 3-layer neon glow effect with animated intensity
            boxShadow: GlowShadows.electricBlue(intensity: _glowIntensity),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              // Stronger blur: 20px sigma (vs Ocean Glass's 12px)
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Padding(
                padding: EdgeInsets.all(_paddingValue),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
