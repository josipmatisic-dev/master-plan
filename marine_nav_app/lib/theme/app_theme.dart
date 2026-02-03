/// Ocean Glass Design System - App Theme
///
/// Main theme configuration for the Marine Navigation App.
/// Provides ThemeData for both dark and light modes following
/// the Ocean Glass design language.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'dimensions.dart';
import 'text_styles.dart';

/// App theme configuration with Ocean Glass design system
class AppTheme {
  AppTheme._(); // Private constructor

  // ============ Dark Theme (Primary) ============

  /// Dark theme following Ocean Glass design language
  /// This is the primary theme optimized for marine navigation
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: OceanColors.seafoamGreen,
        secondary: OceanColors.teal,
        surface: OceanColors.surface,
        error: OceanColors.error,
        onPrimary: OceanColors.pureWhite,
        onSecondary: OceanColors.pureWhite,
        onSurface: OceanColors.textPrimary,
        onError: OceanColors.pureWhite,
      ),

      scaffoldBackgroundColor: OceanColors.background,

      // Typography
      textTheme: _buildTextTheme(OceanColors.textPrimary),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: OceanColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: OceanTextStyles.fontFamily,
        ),
        iconTheme: IconThemeData(color: OceanColors.textPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: OceanColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OceanDimensions.radius),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: OceanColors.textPrimary,
        size: OceanDimensions.icon,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: OceanColors.textDisabled.withValues(alpha: 0.2),
        thickness: 1,
        space: OceanDimensions.spacingM,
      ),

      useMaterial3: true,
    );
  }

  // ============ Light Theme (Secondary) ============

  /// Light theme for daytime use
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: OceanColors.seafoamGreen,
        secondary: OceanColors.teal,
        surface: OceanColors.surfaceLight,
        error: OceanColors.error,
        onPrimary: OceanColors.pureWhite,
        onSecondary: OceanColors.pureWhite,
        onSurface: OceanColors.textPrimaryLight,
        onError: OceanColors.pureWhite,
      ),

      scaffoldBackgroundColor: OceanColors.backgroundLight,

      // Typography
      textTheme: _buildTextTheme(OceanColors.textPrimaryLight),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: OceanColors.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: OceanTextStyles.fontFamily,
        ),
        iconTheme: IconThemeData(color: OceanColors.textPrimaryLight),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: OceanColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OceanDimensions.radius),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: OceanColors.textPrimaryLight,
        size: OceanDimensions.icon,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: OceanColors.textSecondaryLight.withValues(alpha: 0.2),
        thickness: 1,
        space: OceanDimensions.spacingM,
      ),

      useMaterial3: true,
    );
  }

  // ============ Helper Methods ============

  /// Build text theme with specified color
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: OceanTextStyles.dataValue.copyWith(color: textColor),
      headlineLarge: OceanTextStyles.heading1.copyWith(color: textColor),
      headlineMedium: OceanTextStyles.heading2.copyWith(color: textColor),
      bodyLarge: OceanTextStyles.bodyLarge.copyWith(color: textColor),
      bodyMedium: OceanTextStyles.body.copyWith(color: textColor),
      bodySmall: OceanTextStyles.bodySmall.copyWith(color: textColor),
      labelLarge: OceanTextStyles.labelLarge.copyWith(color: textColor),
      labelMedium: OceanTextStyles.label.copyWith(color: textColor),
      labelSmall: OceanTextStyles.labelSmall.copyWith(color: textColor),
    );
  }
}

/// Responsive breakpoint helpers
extension ResponsiveContext on BuildContext {
  /// Check if current screen is mobile (<600px)
  bool get isMobile =>
      MediaQuery.of(this).size.width < OceanDimensions.breakpointMobile;

  /// Check if current screen is tablet (600-1200px)
  bool get isTablet =>
      MediaQuery.of(this).size.width >= OceanDimensions.breakpointMobile &&
      MediaQuery.of(this).size.width < OceanDimensions.breakpointTablet;

  /// Check if current screen is desktop (>1200px)
  bool get isDesktop =>
      MediaQuery.of(this).size.width >= OceanDimensions.breakpointTablet;
}
