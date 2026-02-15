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
import 'holographic_theme_data.dart';
import 'text_styles.dart';
import 'theme_variant.dart';

/// App theme configuration with Ocean Glass design system
class AppTheme {
  AppTheme._();

  /// Get ThemeData for specific variant and brightness
  static ThemeData getThemeForVariant(bool isDark, ThemeVariant variant) {
    switch (variant) {
      case ThemeVariant.oceanGlass:
        return isDark ? darkTheme : lightTheme;
      case ThemeVariant.holographicCyberpunk:
        return isDark ? HolographicThemeData.dark : HolographicThemeData.light;
    }
  }

  /// Dark theme following Ocean Glass design language
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
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
      textTheme: _buildTextTheme(OceanColors.textPrimary),
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
      cardTheme: CardThemeData(
        color: OceanColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OceanDimensions.radius),
        ),
      ),
      iconTheme: const IconThemeData(
        color: OceanColors.textPrimary,
        size: OceanDimensions.icon,
      ),
      dividerTheme: DividerThemeData(
        color: OceanColors.textDisabled.withValues(alpha: 0.2),
        thickness: 1,
        space: OceanDimensions.spacingM,
      ),
      useMaterial3: true,
    );
  }

  /// Light theme for daytime use
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
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
      textTheme: _buildTextTheme(OceanColors.textPrimaryLight),
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
      cardTheme: CardThemeData(
        color: OceanColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OceanDimensions.radius),
        ),
      ),
      iconTheme: const IconThemeData(
        color: OceanColors.textPrimaryLight,
        size: OceanDimensions.icon,
      ),
      dividerTheme: DividerThemeData(
        color: OceanColors.textSecondaryLight.withValues(alpha: 0.2),
        thickness: 1,
        space: OceanDimensions.spacingM,
      ),
      useMaterial3: true,
    );
  }

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
