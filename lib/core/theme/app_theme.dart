import 'package:flutter/material.dart';
export '../constants/app_colors.dart';
export '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.onSurfaceLight,
        onSurfaceVariant: AppColors.onSurfaceVariantLight,
        surfaceContainer: AppColors.surfaceMuted,
        surfaceContainerHighest: Color(0xFFF8FAFC),
        error: AppColors.error,
        onError: Colors.white,
      ),
      // Feedback (typography): every text style and form field reads
      // from the theme, so typed text, hints and labels stay readable in
      // light AND dark mode instead of hardcoding light fills with
      // theme-following text.
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.onSurfaceLight),
        bodyMedium: TextStyle(color: AppColors.onSurfaceLight),
        titleMedium: TextStyle(color: AppColors.onSurfaceLight),
        titleLarge: TextStyle(color: AppColors.onSurfaceLight),
        labelLarge: TextStyle(color: AppColors.onSurfaceLight),
        labelMedium: TextStyle(color: AppColors.onSurfaceLight),
        bodySmall: TextStyle(color: AppColors.onSurfaceVariantLight),
        labelSmall: TextStyle(color: AppColors.onSurfaceVariantLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundLight,
        hintStyle: const TextStyle(
          color: AppColors.onSurfaceVariantLight,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariantLight),
        floatingLabelStyle:
            const TextStyle(color: AppColors.onSurfaceLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.sunsetOrange,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF252B7A),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF252B7A),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1A1D42),
        secondary: Color(0xFFFF6D24),
        onSecondary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        surfaceContainer: AppColors.surfaceContainerDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.onSurfaceDark),
        bodyMedium: TextStyle(color: AppColors.onSurfaceDark),
        titleMedium: TextStyle(color: AppColors.onSurfaceDark),
        titleLarge: TextStyle(color: AppColors.onSurfaceDark),
        labelLarge: TextStyle(color: AppColors.onSurfaceDark),
        labelMedium: TextStyle(color: AppColors.onSurfaceDark),
        bodySmall: TextStyle(color: AppColors.onSurfaceVariantDark),
        labelSmall: TextStyle(color: AppColors.onSurfaceVariantDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighestDark,
        hintStyle: const TextStyle(
          color: AppColors.onSurfaceVariantDark,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariantDark),
        floatingLabelStyle: const TextStyle(color: AppColors.onSurfaceDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryLight,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0D26),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6D24),
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
    );
  }
}
