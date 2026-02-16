/// Fog overlay using GLSL fragment shader for atmospheric depth effect.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Renders animated volumetric fog via the sea_fog.frag shader.
class FogOverlay extends StatefulWidget {
  /// Fog density from visibility data (0.0=clear, 1.0=dense fog).
  final double fogDensity;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Creates a fog overlay with the given density.
  const FogOverlay({
    super.key,
    this.fogDensity = 0.0,
    this.isHolographic = false,
  });

  @override
  State<FogOverlay> createState() => _FogOverlayState();
}

class _FogOverlayState extends State<FogOverlay>
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
      _program = await ui.FragmentProgram.fromAsset('shaders/sea_fog.frag');
      if (mounted) setState(() => _shaderLoaded = true);
    } catch (e) {
      debugPrint('FogOverlay: shader load failed: $e');
    }
  }

  void _onTick(Duration elapsed) {
    // Only update if fog is actually visible
    if (widget.fogDensity > 0.01) {
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
    // Don't render shader when there's no fog
    if (widget.fogDensity < 0.01 || !_shaderLoaded || _program == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _FogPainter(
          program: _program!,
          time: _time,
          fogDensity: widget.fogDensity,
          isHolographic: widget.isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double fogDensity;
  final bool isHolographic;

  final Paint _shaderPaint = Paint();

  _FogPainter({
    required this.program,
    required this.time,
    required this.fogDensity,
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
    // uFogDensity
    shader.setFloat(3, fogDensity);
    // uFogColor (theme-dependent)
    if (isHolographic) {
      // Purple haze: mix of cyberPurple and electricBlue
      shader.setFloat(4, 0.345); // R: ~88/255
      shader.setFloat(5, 0.141); // G: ~36/255
      shader.setFloat(6, 0.651); // B: ~166/255
    } else {
      // Maritime blue-grey: #8BA4B8
      shader.setFloat(4, 0.545); // R
      shader.setFloat(5, 0.643); // G
      shader.setFloat(6, 0.722); // B
    }
    // uNoiseAmplitude
    shader.setFloat(7, isHolographic ? 0.35 : 0.25);
    // uNoiseSpeed
    shader.setFloat(8, isHolographic ? 0.12 : 0.08);

    _shaderPaint.shader = shader;
    canvas.drawRect(Offset.zero & size, _shaderPaint);
  }

  @override
  bool shouldRepaint(_FogPainter oldDelegate) =>
      time != oldDelegate.time ||
      fogDensity != oldDelegate.fogDensity ||
      isHolographic != oldDelegate.isHolographic;
}
