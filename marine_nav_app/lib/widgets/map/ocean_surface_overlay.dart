/// Ocean surface caustics overlay using GLSL fragment shader.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Renders animated water caustic patterns via the ocean_surface.frag shader.
class OceanSurfaceOverlay extends StatefulWidget {
  /// Wave intensity from weather data (0.0-1.0).
  final double waveIntensity;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Creates an ocean surface caustics overlay.
  const OceanSurfaceOverlay({
    super.key,
    this.waveIntensity = 0.1,
    this.isHolographic = false,
  });

  @override
  State<OceanSurfaceOverlay> createState() => _OceanSurfaceOverlayState();
}

class _OceanSurfaceOverlayState extends State<OceanSurfaceOverlay>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late Ticker _ticker;
  double _time = 0;
  bool _shaderLoaded = false;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset(
        'shaders/ocean_surface.frag',
      );
      if (mounted) setState(() => _shaderLoaded = true);
    } catch (e) {
      debugPrint('OceanSurfaceOverlay: shader load failed: $e');
    }
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    // Throttle to ~30fps
    if (_frameCount % 2 != 0) return;
    setState(() {
      _time = elapsed.inMilliseconds / 1000.0;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shaderLoaded || _program == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: CustomPaint(
        painter: _OceanSurfacePainter(
          program: _program!,
          time: _time,
          waveIntensity: widget.waveIntensity,
          isHolographic: widget.isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _OceanSurfacePainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double waveIntensity;
  final bool isHolographic;

  _OceanSurfacePainter({
    required this.program,
    required this.time,
    required this.waveIntensity,
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
    // uCausticColor (theme-dependent)
    if (isHolographic) {
      shader.setFloat(3, 0.0); // R: 0x00
      shader.setFloat(4, 0.851); // G: 0xD9/FF
      shader.setFloat(5, 1.0); // B: 0xFF — electricBlue
    } else {
      shader.setFloat(3, 0.0); // R
      shader.setFloat(4, 0.788); // G: 0xC9/FF
      shader.setFloat(5, 0.655); // B: 0xA7/FF — seafoamGreen
    }
    // uIntensity
    final baseIntensity = isHolographic ? 0.25 : 0.15;
    final intensityScale = isHolographic
        ? _lerpDouble(0.10, 0.45, waveIntensity)
        : _lerpDouble(0.05, 0.30, waveIntensity);
    shader.setFloat(6, baseIntensity * intensityScale / baseIntensity);
    // uScale
    shader.setFloat(7, isHolographic ? 12.0 : 8.0);
    // uSpeed
    shader.setFloat(8, isHolographic ? 0.5 : 0.3);
    // uSecondLayer
    shader.setFloat(9, isHolographic ? 1.0 : 0.0);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_OceanSurfacePainter oldDelegate) =>
      time != oldDelegate.time ||
      waveIntensity != oldDelegate.waveIntensity ||
      isHolographic != oldDelegate.isHolographic;
}
