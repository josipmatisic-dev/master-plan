/// Rain/snow/hail overlay using GLSL fragment shader.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Precipitation type for the shader.
enum PrecipType {
  /// Rain drops.
  rain,

  /// Snowflakes.
  snow,

  /// Hailstones.
  hail,
}

/// Renders animated precipitation via the rain.frag shader.
class RainOverlay extends StatefulWidget {
  /// Precipitation intensity (0.0-1.0).
  final double intensity;

  /// Wind angle in radians (direction rain falls from).
  final double windAngle;

  /// Wind speed in knots (affects streak length).
  final double windSpeed;

  /// Precipitation type.
  final PrecipType precipType;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Creates a rain overlay with the given precipitation parameters.
  const RainOverlay({
    super.key,
    this.intensity = 0.0,
    this.windAngle = 0.0,
    this.windSpeed = 0.0,
    this.precipType = PrecipType.rain,
    this.isHolographic = false,
  });

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late Ticker _ticker;
  double _time = 0;
  bool _shaderLoaded = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/rain.frag');
      if (mounted) setState(() => _shaderLoaded = true);
    } catch (e) {
      debugPrint('RainOverlay: shader load failed: $e');
    }
  }

  void _onTick(Duration elapsed) {
    if (widget.intensity > 0.01) {
      setState(() => _time = elapsed.inMilliseconds / 1000.0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.intensity < 0.01 || !_shaderLoaded || _program == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _RainPainter(
          program: _program!,
          time: _time,
          intensity: widget.intensity,
          windAngle: widget.windAngle,
          windSpeed: widget.windSpeed,
          precipType: widget.precipType,
          isHolographic: widget.isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double intensity;
  final double windAngle;
  final double windSpeed;
  final PrecipType precipType;
  final bool isHolographic;

  final Paint _shaderPaint = Paint();

  _RainPainter({
    required this.program,
    required this.time,
    required this.intensity,
    required this.windAngle,
    required this.windSpeed,
    required this.precipType,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // uResolution
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uTime
    shader.setFloat(2, time);
    // uIntensity
    shader.setFloat(3, intensity);
    // uWindAngle
    shader.setFloat(4, windAngle);
    // uWindSpeed
    shader.setFloat(5, windSpeed);
    // uDropColor (theme-dependent)
    if (isHolographic) {
      // electricBlue #00D9FF
      shader.setFloat(6, 0.0);
      shader.setFloat(7, 0.851);
      shader.setFloat(8, 1.0);
    } else {
      // pureWhite #FFFFFF
      shader.setFloat(6, 1.0);
      shader.setFloat(7, 1.0);
      shader.setFloat(8, 1.0);
    }
    // uPrecipType
    final precipValue = switch (precipType) {
      PrecipType.rain => 0.0,
      PrecipType.snow => 0.5,
      PrecipType.hail => 1.0,
    };
    shader.setFloat(9, precipValue);

    _shaderPaint.shader = shader;
    canvas.drawRect(Offset.zero & size, _shaderPaint);
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) =>
      time != oldDelegate.time ||
      intensity != oldDelegate.intensity ||
      windAngle != oldDelegate.windAngle ||
      windSpeed != oldDelegate.windSpeed ||
      precipType != oldDelegate.precipType ||
      isHolographic != oldDelegate.isHolographic;
}
