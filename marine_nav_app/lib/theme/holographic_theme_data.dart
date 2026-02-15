/// Holographic Cyberpunk Theme Data
///
/// ThemeData definitions for the Holographic Cyberpunk theme variant
/// in both dark and light modes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'dimensions.dart';
import 'holographic_colors.dart';
import 'text_styles.dart';

/// Holographic theme data builder.
class HolographicThemeData {
  HolographicThemeData._();

  /// Holographic Cyberpunk dark theme with neon effects.
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: HolographicColors.electricBlue,
        secondary: HolographicColors.neonCyan,
        surface: HolographicColors.surface,
        error: HolographicColors.error,
        onPrimary: HolographicColors.pureWhite,
        onSecondary: HolographicColors.cosmicBlack,
        onSurface: HolographicColors.textPrimary,
        onError: HolographicColors.pureWhite,
      ),
      scaffoldBackgroundColor: HolographicColors.background,
      textTheme: _buildTextTheme(HolographicColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: HolographicColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: OceanTextStyles.fontFamily,
        ),
        iconTheme: IconThemeData(color: HolographicColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: HolographicColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OceanDimensions.radius),
        ),
      ),
      iconTheme: const IconThemeData(
        color: HolographicColors.textPrimary,
        size: OceanDimensions.icon,
      ),
      dividerTheme: DividerThemeData(
        color: HolographicColors.textDisabled.withValues(alpha: 0.2),
        thickness: 1,
        space: OceanDimensions.spacingM,
      ),
      useMaterial3: true,
    );
  }

  /// Holographic Cyberpunk light theme (for day use).
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: HolographicColors.electricBlue,
        secondary: HolographicColors.cyberPurple,
        surface: OceanColors.surfaceLight,
        error: HolographicColors.error,
        onPrimary: HolographicColors.pureWhite,
        onSecondary: HolographicColors.pureWhite,
        onSurface: OceanColors.textPrimaryLight,
        onError: HolographicColors.pureWhite,
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
