/// Theme variant enumeration for multi-theme support
///
/// Defines the visual style variants available in the app.
/// Each variant has its own color palette, effects, and animations.
library;

/// Available theme variants
enum ThemeVariant {
  /// Professional nautical theme with frosted glass effects
  /// - Subtle blues and teals
  /// - Soft glass blur (12px)
  /// - Minimal glow effects
  /// - Optimized for readability in marine conditions
  oceanGlass,

  /// Futuristic cyberpunk theme with neon effects
  /// - Vibrant neon colors (electric blue, magenta, cyan)
  /// - Strong glass blur (20px)
  /// - Multi-layer glow effects
  /// - Particle background system
  /// - Animated gradient borders
  holographicCyberpunk,
}

/// Extension methods for ThemeVariant
extension ThemeVariantExtension on ThemeVariant {
  /// Human-readable name for the theme
  String get displayName {
    switch (this) {
      case ThemeVariant.oceanGlass:
        return 'Ocean Glass';
      case ThemeVariant.holographicCyberpunk:
        return 'Holographic Cyberpunk';
    }
  }

  /// Description of the theme variant
  String get description {
    switch (this) {
      case ThemeVariant.oceanGlass:
        return 'Professional nautical theme optimized for marine navigation';
      case ThemeVariant.holographicCyberpunk:
        return 'Futuristic theme with neon effects and particle animations';
    }
  }

  /// Persistence key for SharedPreferences
  String get persistenceKey {
    switch (this) {
      case ThemeVariant.oceanGlass:
        return 'ocean_glass';
      case ThemeVariant.holographicCyberpunk:
        return 'holographic_cyberpunk';
    }
  }

  /// Parse ThemeVariant from persistence key
  static ThemeVariant fromPersistenceKey(String key) {
    switch (key) {
      case 'ocean_glass':
        return ThemeVariant.oceanGlass;
      case 'holographic_cyberpunk':
        return ThemeVariant.holographicCyberpunk;
      default:
        return ThemeVariant.oceanGlass; // Default fallback
    }
  }
}
