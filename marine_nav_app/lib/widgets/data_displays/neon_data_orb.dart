/// NeonDataOrb - Holographic cyberpunk circular data display with animated glows.
///
/// Implements neon ring effects with state-based animations and gradient progress rings.
library;

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/holographic_colors.dart';
import '../../theme/holographic_effects.dart';
import 'data_orb.dart';

/// NeonDataOrb widget: animated circular neon display with ring glows and effects.
class NeonDataOrb extends StatefulWidget {
  const NeonDataOrb({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.subtitle,
    this.size = DataOrbSize.medium,
    this.state = DataOrbState.normal,
    this.progress,
    this.heroTag,
  });

  final String label, value, unit;
  final String? subtitle;
  final DataOrbSize size;
  final DataOrbState state;
  final double? progress;
  final Object? heroTag;

  @override
  State<NeonDataOrb> createState() => _NeonDataOrbState();
}

class _NeonDataOrbState extends State<NeonDataOrb>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Rotation animation for gradient progress ring (4s loop)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Only start rotation if not disabled by accessibility settings
    if (!MediaQuery.of(context).disableAnimations) {
      _rotationController.repeat();
    }

    // Pulse animation for critical state (1s loop, sine wave)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Only activate pulse for critical state if animations enabled
    if (widget.state == DataOrbState.critical &&
        !MediaQuery.of(context).disableAnimations) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NeonDataOrb oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update pulse controller when state changes
    if (oldWidget.state != widget.state) {
      if (widget.state == DataOrbState.critical &&
          !MediaQuery.of(context).disableAnimations) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = _dimensionForSize(widget.size);
    final inactive = widget.state == DataOrbState.inactive;

    final orb = RepaintBoundary(
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background with radial gradient
            _buildBackground(dimension, inactive),

            // Animated ring with state-based colors and glows
            _buildRing(dimension, inactive),

            // Optional progress ring with gradient animation
            if (widget.progress != null)
              _buildProgressRing(dimension, inactive),

            // Center content (value, unit, label, subtitle)
            _buildContent(inactive),
          ],
        ),
      ),
    );

    if (widget.heroTag == null) return orb;
    return Hero(tag: widget.heroTag!, child: orb);
  }

  Widget _buildBackground(double dimension, bool inactive) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: HolographicColors.orbGradient,
        color: HolographicColors.spaceNavy.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildRing(double dimension, bool inactive) {
    final ringColor = _ringColorForState(widget.state);
    final glowIntensity = _glowIntensityForState(widget.state);

    if (widget.state == DataOrbState.critical) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = 0.6 +
              (0.4 * (math.sin(_pulseController.value * 2 * math.pi) + 1) / 2);
          return _buildRingWithGlow(dimension, ringColor, glowIntensity, pulse);
        },
      );
    }

    return _buildRingWithGlow(
      dimension,
      ringColor,
      glowIntensity,
      inactive ? 0.3 : 1.0,
    );
  }

  Widget _buildRingWithGlow(
    double dimension,
    Color ringColor,
    double glowIntensity,
    double opacity,
  ) {
    final glow = GlowShadows.intensified(
      color: ringColor,
      intensity: glowIntensity,
    );

    return Container(
      width: dimension * 0.95,
      height: dimension * 0.95,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: ringColor.withValues(alpha: opacity), width: 3),
        boxShadow: [
          for (var shadow in glow)
            shadow.copyWith(
              color: shadow.color.withValues(alpha: shadow.color.a * opacity),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(double dimension, bool inactive) {
    if (widget.progress == null || widget.progress! <= 0) {
      return const SizedBox.shrink();
    }

    final progress = widget.progress!.clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) => Transform.rotate(
        angle: _rotationController.value * 2 * math.pi,
        child: SizedBox(
          width: dimension * 0.9,
          height: dimension * 0.9,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: HolographicColors.neonMagenta
                .withValues(alpha: inactive ? 0.1 : 0.2),
            valueColor: AlwaysStoppedAnimation(
              inactive
                  ? HolographicColors.neonMagenta.withValues(alpha: 0.3)
                  : HolographicColors.neonMagenta,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool inactive) {
    final valueFontSize = _fontSizeForSize(widget.size);
    final glowColor = _glowColorForState(widget.state);
    final valueStyle = TextStyle(
      fontSize: valueFontSize,
      fontWeight: FontWeight.bold,
      color: inactive
          ? HolographicColors.textSecondary.withValues(alpha: 0.6)
          : HolographicColors.pureWhite,
      shadows: inactive ? [] : TextGlow.dataValue(glowColor),
    );
    final labelStyle = TextStyle(
      fontSize: 12,
      color: inactive
          ? HolographicColors.textSecondary.withValues(alpha: 0.6)
          : HolographicColors.textSecondary,
      letterSpacing: 0.5,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.value,
            style: valueStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(widget.unit, style: labelStyle, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(widget.label, style: labelStyle, overflow: TextOverflow.ellipsis),
        if (widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.subtitle!,
                style: labelStyle.copyWith(fontSize: 10),
                overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }

  Color _ringColorForState(DataOrbState state) => switch (state) {
        DataOrbState.normal => HolographicColors.electricBlue,
        DataOrbState.alert => HolographicColors.neonMagenta,
        DataOrbState.critical => HolographicColors.neonMagenta,
        DataOrbState.inactive => HolographicColors.textSecondary,
      };

  Color _glowColorForState(DataOrbState state) => switch (state) {
        DataOrbState.normal => HolographicColors.electricBlue,
        DataOrbState.alert => HolographicColors.neonMagenta,
        DataOrbState.critical => HolographicColors.neonMagenta,
        DataOrbState.inactive => HolographicColors.textSecondary,
      };

  double _glowIntensityForState(DataOrbState state) => switch (state) {
        DataOrbState.normal => 1.0,
        DataOrbState.alert => 1.5,
        DataOrbState.critical => 2.0,
        DataOrbState.inactive => 0.0,
      };

  double _dimensionForSize(DataOrbSize size) => switch (size) {
        DataOrbSize.small => 80,
        DataOrbSize.medium => 140,
        DataOrbSize.large => 200,
      };

  double _fontSizeForSize(DataOrbSize size) => switch (size) {
        DataOrbSize.small => 32,
        DataOrbSize.medium => 48,
        DataOrbSize.large => 56,
      };
}
