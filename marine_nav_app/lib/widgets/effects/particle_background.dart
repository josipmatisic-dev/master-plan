/// High-performance particle background with optional multi-touch interactivity.
///
/// Auto-adaptive density based on screen size and FPS. Supports touch
/// attraction, burst repulsion, and drag trail effects.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single particle with physics, animation, and optional trail behavior.
class Particle {
  final double size, pulseSpeed, lifetime;
  final Color color;
  final bool isTrail;
  double x, y, vx, vy, age, opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.pulseSpeed,
    required this.lifetime,
    this.isTrail = false,
  })  : age = 0,
        opacity = 0.3;

  bool get isDead => age >= lifetime;

  void update(double dt) {
    age += dt;
    x += vx;
    y += vy;
    if (isTrail) {
      opacity = (1.0 - age / lifetime).clamp(0.0, 0.8);
    } else {
      opacity =
          0.3 + 0.5 * (math.sin(age * pulseSpeed * 2 * math.pi) * 0.5 + 0.5);
    }
  }

  void reset(double w, double h, List<Color> colors) {
    age = 0;
    opacity = 0.3;
    x = math.Random().nextDouble() * w;
    y = h + 10;
    vx = 0.5 + math.Random().nextDouble();
    vy = -0.3 - math.Random().nextDouble() * 0.5;
  }
}

/// Renders particles to a canvas.
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Paint _paint = Paint()..strokeCap = StrokeCap.round;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.x >= 0 && p.x <= size.width && p.y >= -10) {
        _paint
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.x, p.y), p.size / 2, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// High-performance particle background for holographic theme.
///
/// Set [interactive] to `true` (default) to enable multi-touch attraction,
/// burst repulsion, and drag trail effects. Use `false` for IgnorePointer screens.
class ParticleBackground extends StatefulWidget {
  /// Custom particle count (null = auto-detect based on screen size).
  final int? particleCount;

  /// Custom color palette.
  final List<Color>? colors;

  /// Debug mode (logs FPS metrics).
  final bool debugMode;

  /// Whether touch events are captured for interactive effects.
  final bool interactive;

  const ParticleBackground({
    super.key,
    this.particleCount,
    this.colors,
    this.debugMode = false,
    this.interactive = true,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  late List<Color> _colors;
  final _rng = math.Random();
  int _targetParticleCount = 50, _currentParticleCount = 50, _frameCount = 0;
  double _fps = 60;
  Stopwatch? _frameTimer;

  final Map<int, Offset> _activePointers = {};
  static const _maxPointers = 5, _attractR = 80.0, _burstR = 60.0;

  // --- Touch handlers ---
  void _onPointerDown(PointerDownEvent e) {
    if (_activePointers.length < _maxPointers) {
      _activePointers[e.pointer] = e.localPosition;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_activePointers.containsKey(e.pointer)) return;
    _activePointers[e.pointer] = e.localPosition;
    _spawnTrail(e.localPosition);
  }

  void _onPointerUp(PointerUpEvent e) {
    final pos = _activePointers.remove(e.pointer);
    if (pos != null) _applyBurst(pos);
  }

  void _onPointerCancel(PointerCancelEvent e) =>
      _activePointers.remove(e.pointer);

  void _spawnTrail(Offset pos) {
    for (int i = 0, n = 2 + _rng.nextInt(2); i < n; i++) {
      _particles.add(Particle(
        x: pos.dx + _rng.nextDouble() * 6 - 3,
        y: pos.dy + _rng.nextDouble() * 6 - 3,
        vx: _rng.nextDouble() * 0.6 - 0.3,
        vy: _rng.nextDouble() * 0.6 - 0.3,
        size: 1.0 + _rng.nextDouble(),
        color: _colors[_rng.nextInt(_colors.length)],
        pulseSpeed: 1.0,
        lifetime: 1.0 + _rng.nextDouble(),
        isTrail: true,
      ));
    }
  }

  void _applyBurst(Offset pos) {
    for (final p in _particles) {
      if (p.isTrail) continue;
      final dx = p.x - pos.dx, dy = p.y - pos.dy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < _burstR && d > 0.1) {
        final s = (1.0 - d / _burstR) * 4.0;
        p.vx += (dx / d) * s;
        p.vy += (dy / d) * s;
      }
    }
  }

  void _applyAttraction() {
    if (_activePointers.isEmpty) return;
    for (final p in _particles) {
      if (p.isTrail) continue;
      for (final pos in _activePointers.values) {
        final dx = pos.dx - p.x, dy = pos.dy - p.y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < _attractR && d > 0.1) {
          final s = (1.0 - d / _attractR) * 0.3;
          p.vx += (dx / d) * s;
          p.vy += (dy / d) * s;
        }
      }
    }
  }

  // --- Core loop ---
  void _onAnimationUpdate() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    if (MediaQuery.of(context).disableAnimations) return;
    const dt = 1.0 / 60.0;
    if (widget.interactive) _applyAttraction();
    for (final p in _particles) {
      p.update(dt);
      if (p.isDead && !p.isTrail) p.reset(size.width, size.height, _colors);
    }
    _particles.removeWhere((p) => p.isTrail && p.isDead);
    // Adaptive FPS monitoring
    _frameCount++;
    if (_frameTimer!.elapsedMilliseconds >= 1000) {
      _fps = _frameCount.toDouble();
      _frameCount = 0;
      _frameTimer!.reset();
      if (_fps < 50 && _currentParticleCount > 20) {
        _currentParticleCount = (_currentParticleCount * 0.8).toInt();
        final keep =
            _particles.where((p) => !p.isTrail).take(_currentParticleCount);
        _particles = [...keep, ..._particles.where((p) => p.isTrail)];
        if (widget.debugMode) {
          debugPrint(
              'ParticleBackground: FPS=$_fps, reducing to $_currentParticleCount');
        }
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _colors = widget.colors ??
        const [Color(0xFF00D9FF), Color(0xFF00FFFF), Color(0xFFFF00FF)];
    _particles = [];
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _controller.addListener(_onAnimationUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateParticleCount();
      _spawnInitial();
    });
    _frameTimer = Stopwatch()..start();
  }

  void _updateParticleCount() {
    if (widget.particleCount != null) {
      _targetParticleCount = widget.particleCount!;
      return;
    }
    final w = MediaQuery.of(context).size.width;
    _targetParticleCount = w > 1200
        ? 80 + _rng.nextInt(41)
        : w > 600
            ? 50 + _rng.nextInt(31)
            : 30 + _rng.nextInt(21);
    _currentParticleCount = _targetParticleCount;
  }

  void _spawnInitial() {
    if (!mounted) return;
    final sz = MediaQuery.of(context).size;
    for (int i = 0; i < _currentParticleCount; i++) {
      _particles.add(Particle(
        x: _rng.nextDouble() * sz.width,
        y: _rng.nextDouble() * sz.height,
        vx: 0.5 + _rng.nextDouble(),
        vy: -0.3 - _rng.nextDouble() * 0.5,
        size: 2.0 + _rng.nextDouble() * 4.0,
        color: _colors[_rng.nextInt(_colors.length)],
        pulseSpeed: 0.5 + _rng.nextDouble() * 1.5,
        lifetime: 5.0 + _rng.nextDouble() * 5.0,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateParticleCount();
  }

  @override
  void dispose() {
    _controller.dispose();
    _frameTimer?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
        painter: ParticlePainter(particles: _particles), size: Size.infinite);
    return RepaintBoundary(
      child: widget.interactive
          ? Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              behavior: HitTestBehavior.translucent,
              child: paint)
          : paint,
    );
  }
}
