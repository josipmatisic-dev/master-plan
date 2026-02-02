/// Responsive Utilities
///
/// Helper functions and extensions for responsive design.
/// Implements the 3-breakpoint system (mobile, tablet, desktop).
library;

import 'package:flutter/widgets.dart';
import '../theme/dimensions.dart';

/// Responsive utilities for breakpoint-based layouts
class ResponsiveUtils {
  ResponsiveUtils._(); // Private constructor

  /// Get current breakpoint for screen width
  static Breakpoint getBreakpoint(double width) {
    if (width < OceanDimensions.breakpointMobile) {
      return Breakpoint.mobile;
    } else if (width < OceanDimensions.breakpointTablet) {
      return Breakpoint.tablet;
    } else {
      return Breakpoint.desktop;
    }
  }

  /// Get responsive value based on breakpoint
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = getBreakpoint(width);

    switch (breakpoint) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive spacing multiplier
  static double getSpacingMultiplier(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < OceanDimensions.breakpointMobile) {
      return 1.0; // Mobile: standard spacing
    } else if (width < OceanDimensions.breakpointTablet) {
      return 1.25; // Tablet: 25% more spacing
    } else {
      return 1.5; // Desktop: 50% more spacing
    }
  }
}

/// Device breakpoint enum
enum Breakpoint {
  /// Mobile devices (<600px)
  mobile,

  /// Tablet devices (600-1200px)
  tablet,

  /// Desktop devices (>1200px)
  desktop,
}

/// Extension methods for responsive design
extension ResponsiveExtensions on BuildContext {
  /// Get current breakpoint
  Breakpoint get breakpoint {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveUtils.getBreakpoint(width);
  }

  /// Check if device is mobile
  bool get isMobile => breakpoint == Breakpoint.mobile;

  /// Check if device is tablet
  bool get isTablet => breakpoint == Breakpoint.tablet;

  /// Check if device is desktop
  bool get isDesktop => breakpoint == Breakpoint.desktop;

  /// Get responsive value
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return ResponsiveUtils.getResponsiveValue(
      context: this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get responsive spacing
  double get responsiveSpacing {
    return OceanDimensions.spacing * ResponsiveUtils.getSpacingMultiplier(this);
  }
}

/// Spacing utility extension
extension SpacingExtensions on num {
  /// Convert number to SizedBox with height
  SizedBox get verticalSpace => SizedBox(height: toDouble());

  /// Convert number to SizedBox with width
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}
