/// Ocean Glass Design System - Dimensions and Spacing
/// 
/// Defines spacing scale, border radius values, and glass effect parameters
/// following the Ocean Glass design language.
library;

/// Spacing and dimension constants for Ocean Glass design system
class OceanDimensions {
  OceanDimensions._(); // Private constructor
  
  // ============ Spacing Scale ============
  
  /// Extra small spacing: 4px
  static const double spacingXS = 4.0;
  
  /// Small spacing: 8px
  static const double spacingS = 8.0;
  
  /// Medium spacing: 12px
  static const double spacingM = 12.0;
  
  /// Default spacing: 16px
  static const double spacing = 16.0;
  
  /// Large spacing: 24px
  static const double spacingL = 24.0;
  
  /// Extra large spacing: 32px
  static const double spacingXL = 32.0;
  
  /// XXL spacing: 48px
  static const double spacingXXL = 48.0;
  
  // ============ Border Radius ============
  
  /// Small border radius: 8px
  static const double radiusS = 8.0;
  
  /// Medium border radius: 12px
  static const double radiusM = 12.0;
  
  /// Default border radius for glass cards: 16px
  static const double radius = 16.0;
  
  /// Large border radius: 20px
  static const double radiusL = 20.0;
  
  /// Extra large border radius: 24px
  static const double radiusXL = 24.0;
  
  // ============ Glass Effect Parameters ============
  
  /// Standard backdrop blur sigma: 12px
  static const double glassBlur = 12.0;
  
  /// Intense backdrop blur for overlays: 15px
  static const double glassBlurIntense = 15.0;
  
  /// Light backdrop blur for subtle effects: 8px
  static const double glassBlurLight = 8.0;
  
  /// Standard glass opacity for dark mode: 75%
  static const double glassOpacity = 0.75;
  
  /// Standard glass opacity for light mode: 85%
  static const double glassOpacityLight = 0.85;
  
  /// Glass border width: 1px
  static const double glassBorderWidth = 1.0;
  
  /// Glass border opacity: 20%
  static const double glassBorderOpacity = 0.2;
  
  /// Glass border opacity for light mode: 10%
  static const double glassBorderOpacityLight = 0.1;
  
  // ============ Shadow Parameters ============
  
  /// Shadow blur radius for glass cards
  static const double shadowBlur = 32.0;
  
  /// Shadow offset Y for glass cards
  static const double shadowOffsetY = 8.0;
  
  /// Shadow opacity
  static const double shadowOpacity = 0.3;
  
  // ============ Icon Sizes ============
  
  /// Small icon: 16px
  static const double iconS = 16.0;
  
  /// Medium icon: 20px
  static const double iconM = 20.0;
  
  /// Default icon: 24px
  static const double icon = 24.0;
  
  /// Large icon: 32px
  static const double iconL = 32.0;
  
  /// Extra large icon: 48px
  static const double iconXL = 48.0;
  
  // ============ Responsive Breakpoints ============
  
  /// Mobile breakpoint: 600px
  static const double breakpointMobile = 600.0;
  
  /// Tablet breakpoint: 1200px
  static const double breakpointTablet = 1200.0;
  
  // Desktop is anything above tablet breakpoint
}
