import 'package:flutter/material.dart';

/// Phase A (A2): the single naming set for the rulebook's 13 tokens
/// (DOC-12 §4.2, §11). One name per token, no aliases — every view reads
/// these constants and nothing else. Values are the rulebook values, light
/// and dark; where the old file disagreed with the rulebook, the rulebook
/// wins (see the notes on `primaryLight`, `secondaryLight`, `borderDark`).
class AppColors {
  // Primary palette (Deep Midnight Navy)
  static const Color primaryDark = Color(0xFF16194F);
  static const Color primary = Color(0xFF1B1E5C);
  // Dark-mode values of the primary tokens (rulebook §4.2, Dark column).
  static const Color primaryOnDark = Color(0xFF252B7A);
  static const Color primaryContainerOnDark = Color(0xFF1A1D42);
  static const Color primaryDarkOnDark = Color(0xFF0B0D26);
  // Rulebook §4.2: primaryLight is the light container tint #EEF0FF (the
  // old #242875 was a second navy with no rulebook meaning and no usages).
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color primaryContainer = Color(0xFFEEF0FF);

  // Accent palette (Vibrant Sunset Orange)
  static const Color secondary = Color(0xFFF95700);
  // Rulebook §4.2: secondaryLight (light) is the pale tint #FFF3EB; the
  // old #FF6D24 is the *dark* secondary — it now lives in `secondaryDark`.
  static const Color secondaryLight = Color(0xFFFFF3EB);
  static const Color secondaryContainer = Color(0xFFFFF3EB);
  static const Color secondaryDark = Color(0xFFFF6D24);
  static const Color secondaryLightDark = Color(0xFF3D1B08);

  // Status colors — canonical names are accentSuccess / accentDanger
  // (rulebook §11). Dark variants added in Phase A (were missing, D9).
  static const Color accentSuccess = Color(0xFF10B981);
  static const Color accentSuccessDark = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFECFDF5);
  // Dark-mode container tones for the pale success/error/warning slabs
  // in views (rulebook §4.2 Dark column). The pale light containers
  // glare in dark mode; these replace them, with a light on-container
  // colour for the text/icons that sit on them.
  static const Color successContainerDark = Color(0xFF123524);
  static const Color successOnContainerDark = Color(0xFF86EFAC);

  static const Color accentDanger = Color(0xFFEF4444);
  static const Color accentDangerDark = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color errorContainerDark = Color(0xFF3B1215);
  static const Color errorOnContainerDark = Color(0xFFFCA5A5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color warningContainerDark = Color(0xFF3A2A05);
  static const Color warningOnContainerDark = Color(0xFFFCD34D);

  // Dark-mode focused input border. primaryOnDark #252B7A is invisible
  // against the dark field fill #1E2138 / border #23274D, so focused
  // fields were indistinguishable from unfocused ones.
  static const Color primaryFocusedOnDark = Color(0xFF6C72D9);

  /// Brightness-aware container/foreground pairs for the pale success and
  /// error slabs (WhatsApp buttons, status pills, banners). Light mode
  /// keeps the original pale tints; dark mode uses the dark container
  /// tokens so the slab and its text stay readable on dark surfaces.
  static Color successContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? successContainerDark : successContainer;
  static Color successOnContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? successOnContainerDark : accentSuccess;
  static Color successBorderFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? accentSuccessDark
          : const Color(0xFF86EFAC);
  static Color errorContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? errorContainerDark : errorContainer;
  static Color errorOnContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? errorOnContainerDark : accentDanger;

  /// Brightness-aware status TEXT colours (icons, labels, amounts on a
  /// surface). The light tokens are too dark to read on dark surfaces
  /// (accentDanger #EF4444 ≈ 3.9:1, accentSuccess #16A34A ≈ 3.0:1), so
  /// dark mode uses the lighter variants; light mode is unchanged.
  static Color dangerTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? accentDangerDark : accentDanger;
  static Color successTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? accentSuccessDark : accentSuccess;
  static Color warningTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningOnContainerDark : warning;
  static Color warningContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningContainerDark : warningContainer;
  static Color warningOnContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningOnContainerDark : warning;

  // Background & surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0A0B1A);
  static const Color background = backgroundLight;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF13152C);
  static const Color surface = surfaceLight;
  // Rulebook §4.2 surfaceElevated (was `surfaceMuted`, light only).
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color surfaceElevatedDark = Color(0xFF1C1F3D);
  static const Color surfaceContainerHighestLight = Color(0xFFF8FAFC);
  // Form-field fills per theme. Light fields use backgroundLight; dark
  // fields use these two so typed (light) text stays readable instead of
  // vanishing on a hardcoded light fill.
  static const Color surfaceContainerDark = Color(0xFF171A30);
  static const Color surfaceContainerHighestDark = Color(0xFF1E2138);

  // Typography
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);
  static const Color textPrimary = onSurfaceLight;
  static const Color textSecondary = onSurfaceVariantLight;
  // textMuted is the muted grey for text on LIGHT surfaces ONLY.
  // 0xFF64748B reads at ~4.6:1 on white (WCAG AA) but only ~3.8:1 on
  // dark surfaces, failing AA — never use it on a dark surface; use
  // textMutedDark (onSurfaceVariantDark, ~7:1 on dark) instead.
  // (Was 0xFF94A3B8 — ~2.2:1, unreadable.)
  static const Color textMuted = onSurfaceVariantLight;
  static const Color textMutedDark = onSurfaceVariantDark;

  // Borders — canonical name is borderSubtle (rulebook §4.2).
  static const Color borderSubtle = Color(0xFFE2E8F0);
  // Rulebook §4.2: dark borderSubtle is #23274D (was #2D3748).
  static const Color borderDark = Color(0xFF23274D);
}
