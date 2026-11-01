import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Deep Midnight Navy)
  static const Color primaryDark = Color(0xFF16194F);
  static const Color primary = Color(0xFF1B1E5C);
  static const Color primaryLight = Color(0xFF242875);
  static const Color primaryContainer = Color(0xFFEEF0FF);

  // Aliases for Midnight Navy
  static const Color midnightNavyDark = primaryDark;
  static const Color midnightNavy = primary;
  static const Color midnightNavyLight = primaryLight;
  static const Color royalNavy = primary;
  static const Color lavenderMist = primaryContainer;
  static const Color navySurface = Color(0xFF0F172A);

  // Accent Palette (Vibrant Sunset Orange)
  static const Color secondary = Color(0xFFF95700);
  static const Color secondaryLight = Color(0xFFFF6D24);
  static const Color secondaryContainer = Color(0xFFFFF3EB);

  // Aliases for Sunset Orange
  static const Color sunsetOrange = secondary;
  static const Color orangeLight = secondaryLight;
  static const Color orangeSoftBg = secondaryContainer;
  static const Color softOrangeTint = secondaryContainer;
  static const Color orangeGlow = Color(0xFFFFA066);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFECFDF5);
  static const Color emeraldGreen = success;
  static const Color emeraldSoftBg = successContainer;
  static const Color slateGray = onSurfaceVariantLight;

  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color crimsonRed = error;
  static const Color crimsonDark = errorDark;
  static const Color crimsonSoftBg = errorContainer;

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color amberWarning = warning;
  static const Color amberGold = warning;
  static const Color amberSoftBg = warningContainer;

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0A0B1A);
  static const Color background = backgroundLight;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF13152C);
  static const Color surface = surfaceLight;
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Typography
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);
  static const Color textPrimary = onSurfaceLight;
  static const Color textSecondary = onSurfaceVariantLight;
  static const Color textMuted = onSurfaceVariantDark;
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textLavender = primaryContainer;

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D3748);
  static const Color borderStrong = Color(0xFFCBD5E1);
}
