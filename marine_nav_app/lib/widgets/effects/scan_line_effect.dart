library;

/// A CRT / holographic scan-line overlay that draws thin horizontal lines
/// scrolling slowly upward on an 8-second loop.
///
/// Every 5th line is rendered slightly brighter to mimic an occasional
/// "scan bar" passing over the display. Wrapped in [IgnorePointer] so it
/// never intercepts touch events.
import 'package:flutter/material.dart';

/// Overlays animated scan lines on its parent for a cyberpunk hologram look.
class ScanLineEffect extends StatefulWidget {
  /// Whether the scan-line animation is active.
  final bool enabled;

  /// Base opacity of normal scan lines, clamped to 0.0–1.0.
  final double intensity;

  /// Creates a scan-line overlay effect.
  const ScanLineEffect({
    super.key,
    this.enabled = true,
    this.intensity = 0.04,
  });

  @override
  State<ScanLineEffect> createState() => _ScanLineEffectState();
}

class _ScanLineEffectState extends State<ScanLineEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(ScanLineEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ScanLinePainter(
                offset: _controller.value,
                intensity: widget.intensity.clamp(0.0, 1.0),
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter that draws horizontal scan lines scrolling upward.
class _ScanLinePainter extends CustomPainter {
  final double offset;
  final double intensity;

  static const double _lineSpacing = 3.0;
  static const double _lineThickness = 1.0;

  _ScanLinePainter({required this.offset, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final normalPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, intensity)
      ..strokeWidth = _lineThickness;

    // Brighter "scan bar" lines are 2× the base intensity.
    final brightPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, (intensity * 2).clamp(0.0, 1.0))
      ..strokeWidth = _lineThickness;

    // Shift lines upward based on animation progress.
    final scrollPx = offset * _lineSpacing * 5;
    var y = -_lineSpacing + (scrollPx % _lineSpacing);
    var index = 0;

    while (y < size.height) {
      final paint = (index % 5 == 0) ? brightPaint : normalPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += _lineSpacing;
      index++;
    }
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.offset != offset || oldDelegate.intensity != intensity;
}
