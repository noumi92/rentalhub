import 'package:flutter/material.dart';

/// Phase A (A2): the single naming set for the rulebook's 13 tokens
/// (DOC-12 §4.2, §11). One name per token, no aliases — every view reads
/// these constants and nothing else. Values are the rulebook values, light
/// and dark; where the old file disagreed with the rulebook, the rulebook
/// wins (see the notes on `primaryLight`, `secondaryLight`, `borderDark`).
/// Audit SH-N3 (2026-11-13) deleted the zero-use aliases
/// (`primaryLight`, `secondaryLight`, `background`, `surface`,
/// `textMutedDark`); `textPrimary` / `textSecondary` / `textMuted`
/// remain only as @Deprecated legacy aliases because other modules
/// still reference them — new code must use the `onSurface*` names.
class AppColors {
  // Header gradient (rulebook §4.3): the curved header's base gradient
  // is #16194F → #242875 in light mode and #0B0D26 → #16194F in dark
  // mode. The light end #242875 was removed earlier as a redundant navy
  // (see primaryLight) — it now has rulebook meaning as the header
  // gradient end, so it lives here under a header- name.
  static const Color headerGradientEnd = Color(0xFF242875);
  // Decorative arc/glow hues of the header painter (same hues in both
  // modes, light and dark variants). These are the painter's organic
  // layered curves behind the base gradient, not rulebook tokens.
  static const Color headerArcLight = Color(0xFF2E3792);
  static const Color headerArcLightSoft = Color(0xFF1F256C);
  static const Color headerArcDark = Color(0xFF2B338A);
  static const Color headerArcDarkSoft = Color(0xFF1D2362);
  static const Color headerArc2Light = Color(0xFF3843AC);
  static const Color headerArc2Dark = Color(0xFF3B46B6);
  static const Color headerGlowLight = Color(0xFF2E3896);

  // Splash gradient (audit SH-N1, 2026-11-13): the splash screen's
  // navy gradient lived as four hardcoded hex literals in
  // `splash_view.dart`. It now lives here. `splashGradientTop`
  // #0F1336 is also the `flutter_native_splash` colour in
  // pubspec.yaml — the native splash and the in-app splash share it
  // deliberately so there is no colour jump at handover.
  static const Color splashBackground = Color(0xFF131842);
  static const Color splashGradientTop = Color(0xFF0F1336);
  static const Color splashGradientMiddle = Color(0xFF161B4A);
  static const Color splashGradientBottom = Color(0xFF12163F);

  // Pakistani number-plate strip colours (audit SH-N1): real plate
  // colours, not theme colours — Islamabad plates carry a blue
  // strip, other provinces a green one. Named tokens so the widget
  // never hardcodes hex.
  static const Color plateStripIslamabad = Color(0xFF1E3A8A);
  static const Color plateStripDefault = Color(0xFF15803D);

  // Primary palette (Deep Midnight Navy)
  static const Color primaryDark = Color(0xFF16194F);
  static const Color primary = Color(0xFF1B1E5C);
  // Dark-mode values of the primary tokens (rulebook §4.2, Dark column).
  static const Color primaryOnDark = Color(0xFF252B7A);
  static const Color primaryContainerOnDark = Color(0xFF1A1D42);
  static const Color primaryDarkOnDark = Color(0xFF0B0D26);
  // Rulebook §4.2: primaryLight is the light container tint #EEF0FF (the
  // old #242875 was a second navy with no rulebook meaning and no usages).
  // Audit SH-N3 (2026-11-13): `primaryLight` was a duplicate name for
  // this value — it is deleted; `primaryContainer` is the one name.
  static const Color primaryContainer = Color(0xFFEEF0FF);

  // Accent palette (Vibrant Sunset Orange)
  static const Color secondary = Color(0xFFF95700);
  // Rulebook §4.2: secondaryLight (light) is the pale tint #FFF3EB; the
  // old #FF6D24 is the *dark* secondary — it now lives in `secondaryDark`.
  // Audit SH-N3 (2026-11-13): `secondaryLight` was a duplicate name for
  // this value — it is deleted; `secondaryContainer` is the one name.
  static const Color secondaryContainer = Color(0xFFFFF3EB);
  static const Color secondaryDark = Color(0xFFFF6D24);
  static const Color secondaryLightDark = Color(0xFF3D1B08);

  // Orange TEXT / FILL tokens (audit C3, 2026-11-08). White on
  // `secondary` #F95700 is only 3.29:1 — it passes WCAG AA for large /
  // bold text (>= 3:1) but FAILS for small text (>= 4.5:1), so #F95700
  // stays the brand / large-fill token only and must never carry small
  // white text (white on `secondaryDark` #FF6D24 is worse, 2.81:1).
  // Measured WCAG ratios (script in the foundation report):
  //   orangeText #C2410C on white 5.18:1, on #FFF3EB 4.75:1;
  //   white on orangeFill #C2410C 5.18:1 (same value serves both roles);
  //   orangeTextDark #FB923C on dark surface #13152C 7.92:1, on the dark
  //   orange container #3D1B08 6.83:1.
  // Small orange text: `orangeTextFor(brightness)`. Filled chips and
  // buttons with small white text (both modes): `orangeFill`.
  static const Color orangeText = Color(0xFFC2410C);
  static const Color orangeTextDark = Color(0xFFFB923C);
  static const Color orangeFill = Color(0xFFC2410C);

  // Status colors — canonical names are accentSuccess / accentDanger
  // (rulebook §11). Dark variants added in Phase A (were missing, D9).
  static const Color accentSuccess = Color(0xFF10B981);
  static const Color accentSuccessDark = Color(0xFF34D399);
  // Filled-success token (audit C3 / triage Approve button, 2026-11-08).
  // White on `accentSuccess` #10B981 is only 2.54:1 — it must never carry
  // button text. White on `accentSuccessStrong` #047857 measures 5.48:1
  // (>= 4.5:1), so this is the fill for success buttons with white text
  // in BOTH modes; it also reads 5.48:1 as text on white and 5.21:1 on
  // the light success container #ECFDF5.
  static const Color accentSuccessStrong = Color(0xFF047857);
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
  // Readable red TEXT token (label/colour audit, 2026-11-14).
  // `accentDanger` #EF4444 is only 3.76:1 on white and 3.44:1 on the
  // pale error container — both fail WCAG AA for small text — so small
  // red text uses this instead: #B91C1C measures 6.47:1 on white and
  // ~6.1:1 on #FEF2F2. `errorDark` #DC2626 (4.83:1 on white) stays the
  // fill for destructive buttons with white text.
  static const Color errorText = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color errorContainerDark = Color(0xFF3B1215);
  static const Color errorOnContainerDark = Color(0xFFFCA5A5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color warningContainerDark = Color(0xFF3A2A05);
  static const Color warningOnContainerDark = Color(0xFFFCD34D);
  // Audit SH-N14 (2026-11-13): text on the light warning container.
  // The old light value was `warning` #F59E0B itself — 2.07:1 on
  // #FFFBEB, failing WCAG AA for the offline banner and every other
  // warning-container text. Amber-800 #92400E measures 6.84:1 on
  // #FFFBEB (>= 4.5:1), so this is the light on-container text.
  static const Color warningOnContainer = Color(0xFF92400E);

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
      // Label/colour audit (2026-11-14): the old light value was
      // `accentSuccess` #10B981 — 2.54:1 on white, 2.41:1 on the pale
      // container, failing WCAG AA everywhere it labelled a slab.
      // `accentSuccessStrong` #047857 is 5.48:1 on white, 5.21:1 on
      // the light success container (see SuccessBanner, which already
      // used it for exactly this reason).
      brightness == Brightness.dark ? successOnContainerDark : accentSuccessStrong;
  static Color successBorderFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? accentSuccessDark
          // Audit SH-N3: was an inlined `const Color(0xFF86EFAC)` —
          // the same value as `successOnContainerDark`. One name.
          : successOnContainerDark;
  static Color errorContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? errorContainerDark : errorContainer;
  static Color errorOnContainerFor(Brightness brightness) =>
      // Label/colour audit (2026-11-14): the old light value was
      // `accentDanger` #EF4444 — 3.44:1 on #FEF2F2, failing WCAG AA
      // for the banner text that sits on it. `errorText` #B91C1C is
      // ~6.1:1 on the container and 6.47:1 on white.
      brightness == Brightness.dark ? errorOnContainerDark : errorText;

  /// Brightness-aware status TEXT colours (icons, labels, amounts on a
  /// surface). The light legs are the readable text variants, not the
  /// brand fills: `accentSuccess` #10B981 is 2.54:1 on white,
  /// `accentDanger` #EF4444 is 3.76:1, and `warning` #F59E0B is
  /// 2.15:1 — all fail WCAG AA for small text (label/colour audit,
  /// 2026-11-14). Dark mode uses the lighter variants, unchanged.
  static Color dangerTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? accentDangerDark : errorText;
  static Color successTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? accentSuccessDark : accentSuccessStrong;
  static Color warningTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningOnContainerDark : warningOnContainer;
  static Color warningContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningContainerDark : warningContainer;
  static Color warningOnContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningOnContainerDark : warningOnContainer;

  /// Brightness-aware ORANGE text / container colours (audit C3).
  /// Light mode uses the dark orange #C2410C (5.18:1 on white, 4.75:1 on
  /// the pale container); dark mode uses the light orange #FB923C (7.92:1
  /// on the dark surface #13152C, 6.83:1 on the dark container #3D1B08).
  static Color orangeTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? orangeTextDark : orangeText;
  static Color orangeContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryLightDark : secondaryContainer;
  static Color orangeOnContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? orangeTextDark : orangeText;

  // Background & surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0A0B1A);
  // Audit SH-N3 (2026-11-13): `background` and `surface` were
  // duplicate names for `backgroundLight` / `surfaceLight` — both
  // deleted (zero / one use; the one `background` use now reads
  // `backgroundLight`). One name per value.
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF13152C);
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
  // Audit SH-N3 (2026-11-13): `textPrimary` / `textSecondary` /
  // `textMuted` duplicate `onSurfaceLight` / `onSurfaceVariantLight`
  // and are still referenced by customer, owner and bookings widgets
  // plus two test files outside this change's scope, so they stay as
  // deprecated legacy aliases instead of being deleted (deleting them
  // would break those files). New code must use the `onSurface*`
  // names; the alias scan test fails on any NEW alias.
  @Deprecated('Use onSurfaceLight instead')
  static const Color textPrimary = onSurfaceLight;
  @Deprecated('Use onSurfaceVariantLight instead')
  static const Color textSecondary = onSurfaceVariantLight;
  // textMuted is the muted grey for text on LIGHT surfaces ONLY.
  // 0xFF64748B reads at ~4.6:1 on white (WCAG AA) but only ~3.8:1 on
  // dark surfaces, failing AA — never use it on a dark surface; use
  // onSurfaceVariantDark (~7:1 on dark) instead.
  // (Was 0xFF94A3B8 — ~2.2:1, unreadable.)
  // Audit SH-N3: `textMutedDark` (a duplicate of
  // `onSurfaceVariantDark` with zero uses) is deleted.
  @Deprecated('Use onSurfaceVariantLight instead')
  static const Color textMuted = onSurfaceVariantLight;

  // Borders — canonical name is borderSubtle (rulebook §4.2).
  static const Color borderSubtle = Color(0xFFE2E8F0);
  // Rulebook §4.2: dark borderSubtle is #23274D (was #2D3748).
  static const Color borderDark = Color(0xFF23274D);
}
