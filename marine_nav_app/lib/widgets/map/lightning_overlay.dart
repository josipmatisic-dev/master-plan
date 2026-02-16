/// Lightning bolt overlay with procedural electric arcs and screen flash.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders procedural lightning bolts with glow and screen flash.
class LightningOverlay extends StatefulWidget {
  /// Storm intensity (0.0=none, 1.0=severe).
  final double stormIntensity;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Creates a lightning overlay with the given storm intensity.
  const LightningOverlay({
    super.key,
    this.stormIntensity = 0.0,
    this.isHolographic = false,
  });

  @override
  State<LightningOverlay> createState() => _LightningOverlayState();
}

class _LightningOverlayState extends State<LightningOverlay>
    with TickerProviderStateMixin {
  final _random = Random();
  late AnimationController _flashController;
  late AnimationController _boltController;

  List<_BoltSegment> _currentBolt = [];
  double _flashOpacity = 0;
  bool _strikeScheduled = false;
  Timer? _strikeTimer;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        setState(() {
          _flashOpacity = _flashCurve(_flashController.value);
        });
      });

    _boltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() => setState(() {}));

    _scheduleNextStrike();
  }

  /// Flash brightness curve: spike at 50ms, secondary flash at 200ms.
  double _flashCurve(double t) {
    if (t < 0.1) return t / 0.1 * 0.5;
    if (t < 0.2) return 0.5 - (t - 0.1) / 0.1 * 0.4;
    if (t < 0.4) return 0.1 + sin((t - 0.2) / 0.2 * pi) * 0.15;
    return 0.25 * (1.0 - (t - 0.4) / 0.6);
  }

  void _scheduleNextStrike() {
    if (widget.stormIntensity < 0.01 || _strikeScheduled) return;
    _strikeScheduled = true;

    // Strike interval decreases with intensity
    final maxInterval = 15.0 - widget.stormIntensity * 12.0;
    final minInterval = 1.0 + (1.0 - widget.stormIntensity) * 3.0;
    final nextStrikeIn =
        minInterval + _random.nextDouble() * (maxInterval - minInterval);

    _strikeTimer = Timer(
      Duration(milliseconds: (nextStrikeIn * 1000).toInt()),
      () {
        _strikeScheduled = false;
        if (!mounted || widget.stormIntensity < 0.01) return;
        _strike();
        _scheduleNextStrike();
      },
    );
  }

  void _strike() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;

    // Generate bolt from top area to mid-screen
    final startX = size.width * (0.2 + _random.nextDouble() * 0.6);
    final startY = size.height * 0.05;
    final endX = startX + (_random.nextDouble() - 0.5) * size.width * 0.3;
    final endY = size.height * (0.4 + _random.nextDouble() * 0.3);

    _currentBolt = _generateBolt(
      Offset(startX, startY),
      Offset(endX, endY),
      widget.isHolographic ? 8 : 6,
    );

    _flashController.forward(from: 0);
    _boltController.forward(from: 0);

    // Haptic feedback
    HapticFeedback.heavyImpact();
  }

  List<_BoltSegment> _generateBolt(Offset start, Offset end, int depth) {
    final segments = <_BoltSegment>[];
    _subdivideBolt(start, end, depth, segments, 1.0);
    return segments;
  }

  void _subdivideBolt(
    Offset start,
    Offset end,
    int depth,
    List<_BoltSegment> segments,
    double brightness,
  ) {
    if (depth <= 0 || (end - start).distance < 8) {
      segments.add(_BoltSegment(start, end, brightness));
      return;
    }

    final mid = Offset(
      (start.dx + end.dx) / 2 +
          (_random.nextDouble() - 0.5) * (end - start).distance * 0.3,
      (start.dy + end.dy) / 2 +
          (_random.nextDouble() - 0.5) * (end - start).distance * 0.15,
    );

    _subdivideBolt(start, mid, depth - 1, segments, brightness);
    _subdivideBolt(mid, end, depth - 1, segments, brightness);

    // Branch
    final branchChance = widget.isHolographic ? 0.4 : 0.25;
    if (_random.nextDouble() < branchChance && depth > 2) {
      final branchDir = Offset(
        (_random.nextDouble() - 0.5) * 120,
        40 + _random.nextDouble() * 80,
      );
      _subdivideBolt(
        mid,
        mid + branchDir,
        depth - 2,
        segments,
        brightness * 0.6,
      );
    }
  }

  @override
  void didUpdateWidget(LightningOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stormIntensity < 0.01 && widget.stormIntensity >= 0.01) {
      _scheduleNextStrike();
    }
  }

  @override
  void dispose() {
    _strikeTimer?.cancel();
    _flashController.dispose();
    _boltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stormIntensity < 0.01) return const SizedBox.shrink();

    return Stack(
      children: [
        // Screen flash
        if (_flashOpacity > 0.001)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: widget.isHolographic
                    ? Color.fromRGBO(0, 217, 255, _flashOpacity * 0.6)
                    : Color.fromRGBO(255, 255, 255, _flashOpacity * 0.8),
              ),
            ),
          ),
        // Lightning bolt
        if (_currentBolt.isNotEmpty && _boltController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BoltPainter(
                    segments: _currentBolt,
                    progress: 1.0 - _boltController.value,
                    isHolographic: widget.isHolographic,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BoltSegment {
  final Offset start;
  final Offset end;
  final double brightness;

  _BoltSegment(this.start, this.end, this.brightness);
}

class _BoltPainter extends CustomPainter {
  final List<_BoltSegment> segments;
  final double progress;
  final bool isHolographic;

  final Paint _outerGlow = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 14
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _innerGlow = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final Paint _core = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2;

  _BoltPainter({
    required this.segments,
    required this.progress,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final coreColor =
        isHolographic ? const Color(0xFF00D9FF) : const Color(0xFFFFFFFF);
    final glowColor =
        isHolographic ? const Color(0xFF00FFFF) : const Color(0xFFB0D4F1);

    for (final seg in segments) {
      final alpha = (progress * seg.brightness).clamp(0.0, 1.0);

      // Outer glow
      _outerGlow.color = glowColor.withValues(alpha: alpha * 0.25);
      canvas.drawLine(seg.start, seg.end, _outerGlow);

      // Inner glow
      _innerGlow.color = glowColor.withValues(alpha: alpha * 0.6);
      canvas.drawLine(seg.start, seg.end, _innerGlow);

      // Core line
      _core.color = coreColor.withValues(alpha: alpha);
      canvas.drawLine(seg.start, seg.end, _core);
    }

    // Holographic: afterglow ring at bolt origin
    if (isHolographic && segments.isNotEmpty && progress > 0.3) {
      final origin = segments.first.start;
      final ringAlpha = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      final ringRadius = (1.0 - ringAlpha) * 60;
      _outerGlow
        ..color = const Color(0xFF00D9FF).withValues(alpha: ringAlpha * 0.15)
        ..strokeWidth = 2;
      canvas.drawCircle(origin, ringRadius, _outerGlow);
      _outerGlow.strokeWidth = 14; // restore
    }
  }

  @override
  bool shouldRepaint(_BoltPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      isHolographic != oldDelegate.isHolographic;
}
