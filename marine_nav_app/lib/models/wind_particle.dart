/// Wind particle state for flow field visualization.
library;

import 'dart:ui';

/// Single wind particle with position, velocity, age, and trail history.
class WindParticle {
  /// Current position in normalized coordinates (0-1 range).
  double x;
  double y;

  /// Current velocity in screen units per frame.
  double vx;
  double vy;

  /// Current age in seconds.
  double age;

  /// Maximum lifetime in seconds before respawn.
  double lifetime;

  /// Trail positions (most recent first).
  final List<Offset> trail;

  /// Wind speed magnitude at this particle (m/s).
  double speed;

  WindParticle({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.age = 0,
    this.lifetime = 4.0,
    this.speed = 0,
  }) : trail = [];

  /// Whether this particle has expired.
  bool get isDead => age >= lifetime;

  /// Normalized age (0.0 = just born, 1.0 = about to die).
  double get normalizedAge => (age / lifetime).clamp(0.0, 1.0);

  /// Alpha based on age — fade in at birth, fade out at death.
  double get alpha {
    if (normalizedAge < 0.1) return normalizedAge / 0.1;
    if (normalizedAge > 0.8) return (1.0 - normalizedAge) / 0.2;
    return 1.0;
  }
}
