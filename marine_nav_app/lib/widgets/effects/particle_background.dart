/// High-performance particle background system for holographic theme.
///
/// Implements an efficient particle system using CustomPainter for 60 FPS
/// performance with auto-adaptive density based on screen size and FPS.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============ Particle Model ============

/// Represents a single particle in the system with physics and animation
class Particle {
  /// Size in pixels (2.0-6.0 range)
  final double size;

  /// Color of the particle (from HolographicColors palette)
  final Color color;

  /// Pulsing frequency in Hz (0.5-2.0 range)
  final double pulseSpeed;

  /// Particle lifetime in seconds (5.0-10.0 range)
  final double lifetime;

  /// Current X position
  double x;

  /// Current Y position
  double y;

  /// X velocity (upward float, positive = right)
  double vx;

  /// Y velocity (upward float, negative = up)
  double vy;

  /// Age of particle in seconds
  double age;

  /// Current opacity (0.0-1.0)
  double opacity;

  /// Create a new Particle instance
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.pulseSpeed,
    required this.lifetime,
  })  : age = 0,
        opacity = 0.3;

  /// Check if particle has reached end of lifetime
  bool get isDead => age >= lifetime;

  /// Update particle physics and animation for time delta (dt in seconds)
  void update(double dt) {
    age += dt;

    // Physics update
    x += vx;
    y += vy;

    // Pulsing opacity (sine wave)
    final pulsePhase = (age * pulseSpeed * 2 * math.pi);
    opacity = 0.3 + 0.5 * (math.sin(pulsePhase) * 0.5 + 0.5);
  }

  /// Reset particle to new random position and age
  void reset(double screenWidth, double screenHeight, List<Color> colors) {
    age = 0;
    x = math.Random().nextDouble() * screenWidth;
    y = screenHeight + 10; // Start below screen
    vx = 0.5 + math.Random().nextDouble() * 1.0;
    vy = -0.3 - math.Random().nextDouble() * 0.5;
    opacity = 0.3;
  }
}

// ============ Particle Painter ============

/// Paints particles to canvas for rendering
class ParticlePainter extends CustomPainter {
  /// List of particles to render
  final List<Particle> particles;

  /// Reusable paint object for performance
  final Paint _paint = Paint()..strokeCap = StrokeCap.round;

  /// Create a new ParticlePainter
  ParticlePainter({required this.particles});

  /// Paint particles to the canvas at the given size
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.x >= 0 && particle.x <= size.width && particle.y >= -10) {
        _paint
          ..color = particle.color.withValues(alpha: particle.opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size / 2,
          _paint,
        );
      }
    }
  }

  /// Always repaint to update particle positions
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// ============ Particle Background Widget ============

/// High-performance particle background for holographic theme
///
/// Auto-adapts particle count based on screen size:
/// - Desktop (>1200px): 80-120 particles
/// - Tablet (600-1200px): 50-80 particles
/// - Mobile (<600px): 30-50 particles
/// - Low-end (FPS < 50): 20-30 particles
class ParticleBackground extends StatefulWidget {
  /// Custom particle count (null = auto-detect based on screen size)
  final int? particleCount;

  /// Custom color palette (null = use HolographicColors.particleColors)
  final List<Color>? colors;

  /// Debug mode (logs FPS metrics)
  final bool debugMode;

  /// Create a new ParticleBackground widget
  const ParticleBackground({
    super.key,
    this.particleCount,
    this.colors,
    this.debugMode = false,
  });

  /// Create the mutable state for ParticleBackground
  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  late List<Color> _colors;

  int _targetParticleCount = 50;
  int _currentParticleCount = 50;
  double _fps = 60;
  Stopwatch? _frameTimer;
  int _frameCount = 0;

  /// Called whenever a particle updates on animation frame
  void _onAnimationUpdate() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    const dt = 1.0 / 60.0; // Assume 60 FPS

    // Check if animations are disabled (accessibility)
    if (MediaQuery.of(context).disableAnimations) {
      return;
    }

    // Update particles
    for (final particle in _particles) {
      particle.update(dt);

      if (particle.isDead) {
        particle.reset(size.width, size.height, _colors);
      }
    }

    // Adaptive FPS monitoring
    _frameCount++;
    if (_frameTimer!.elapsedMilliseconds >= 1000) {
      _fps = _frameCount.toDouble();
      _frameCount = 0;
      _frameTimer!.reset();

      // Auto-reduce particle count if FPS drops below 50
      if (_fps < 50 && _currentParticleCount > 20) {
        _currentParticleCount = (_currentParticleCount * 0.8).toInt();
        _particles = _particles.take(_currentParticleCount).toList();

        if (widget.debugMode) {
          debugPrint(
            'ParticleBackground: FPS=$_fps, reducing particles to $_currentParticleCount',
          );
        }
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // Determine colors
    _colors = widget.colors ??
        [
          const Color(0xFF00D9FF), // Electric Blue
          const Color(0xFF00FFFF), // Neon Cyan
          const Color(0xFFFF00FF), // Neon Magenta
        ];

    // Initialize particles
    _particles = [];

    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_onAnimationUpdate);

    // Determine particle count based on screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateParticleCount();
      _spawnInitialParticles();
    });

    // Start FPS monitoring
    _frameTimer = Stopwatch()..start();
  }

  /// Update particle count based on current screen size
  void _updateParticleCount() {
    if (widget.particleCount != null) {
      _targetParticleCount = widget.particleCount!;
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      // Desktop: 80-120 particles
      _targetParticleCount = 80 + math.Random().nextInt(41);
    } else if (screenWidth > 600) {
      // Tablet: 50-80 particles
      _targetParticleCount = 50 + math.Random().nextInt(31);
    } else {
      // Mobile: 30-50 particles
      _targetParticleCount = 30 + math.Random().nextInt(21);
    }

    _currentParticleCount = _targetParticleCount;
  }

  /// Spawn initial particles on screen
  void _spawnInitialParticles() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;

    for (int i = 0; i < _currentParticleCount; i++) {
      final particle = Particle(
        x: math.Random().nextDouble() * size.width,
        y: math.Random().nextDouble() * size.height,
        vx: 0.5 + math.Random().nextDouble() * 1.0,
        vy: -0.3 - math.Random().nextDouble() * 0.5,
        size: 2.0 + math.Random().nextDouble() * 4.0,
        color: _colors[math.Random().nextInt(_colors.length)],
        pulseSpeed: 0.5 + math.Random().nextDouble() * 1.5,
        lifetime: 5.0 + math.Random().nextDouble() * 5.0,
      );
      _particles.add(particle);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-calculate particle count if screen size changes
    _updateParticleCount();
  }

  /// Dispose of animation controller
  @override
  void dispose() {
    _controller.dispose();
    _frameTimer?.stop();
    super.dispose();
  }

  /// Build the particle background widget
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ParticlePainter(particles: _particles),
        size: Size.infinite,
      ),
    );
  }
}
