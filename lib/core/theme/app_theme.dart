import 'package:flutter/material.dart';
export '../constants/app_colors.dart';
export '../constants/app_dimensions.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Phase A: the single source of truth for look & feel.
/// - Fonts: Inter (Latin) + Noto Nastaliq Urdu (Urdu), bundled in
///   `assets/fonts/` — no network font loading, works offline.
/// - Type scale: rulebook §4.5 (displayLarge 28/Bold/34, titleLarge
///   20/600/26, titleMedium 16/600/22, bodyLarge 15/400/22, bodyMedium
///   13/400/18, labelSmall 11/500/14) plus M3 companions (titleSmall,
///   bodySmall, labelLarge, labelMedium) so views never need an ad-hoc
///   `fontSize:`. Every text style sets size + weight + height + colour.
/// - No `Color(0xFF…)` literals anywhere in this file: every colour comes
///   from `AppColors` (light and dark).
/// Header text slots (audit SH-N8, 2026-11-13): the 18 sp / w900 title
/// + 12 sp subtitle pair that [MinimalAppBar] (and the login hero
/// brand) use. It lives in the theme — not hardcoded in the widgets —
/// so the pair is one spec: the "header spec" (rulebook §4.3,
/// white-on-navy header). Urdu (Noto Nastaliq Urdu) has no w900
/// instance — its variable font spans wght 400–700 — so the Urdu
/// title caps at w700 (see SH-N13); Inter (wght 100–900) keeps w900.
class HeaderTextTheme extends ThemeExtension<HeaderTextTheme> {
  const HeaderTextTheme({
    required this.headerTitle,
    required this.headerSubtitle,
  });

  final TextStyle headerTitle;
  final TextStyle headerSubtitle;

  /// The header pair for [fontFamily]: w900 title for Inter, w700 for
  /// Noto Nastaliq Urdu (its variable font tops out at 700).
  factory HeaderTextTheme.forFont(String fontFamily) {
    final titleWeight = fontFamily == AppTheme.fontFamilyUrdu
        ? FontWeight.w700
        : FontWeight.w900;
    return HeaderTextTheme(
      headerTitle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: titleWeight,
        color: Colors.white,
      ),
      headerSubtitle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        color: Colors.white70,
      ),
    );
  }

  /// The header pair for the current theme, falling back to the
  /// documented 18/12 pair when no extension is installed (e.g. a
  /// bare ThemeData in a test pump).
  static HeaderTextTheme of(BuildContext context) =>
      Theme.of(context).extension<HeaderTextTheme>() ??
      HeaderTextTheme.forFont(AppTheme.fontFamilyLatin);

  @override
  HeaderTextTheme copyWith({
    TextStyle? headerTitle,
    TextStyle? headerSubtitle,
  }) =>
      HeaderTextTheme(
        headerTitle: headerTitle ?? this.headerTitle,
        headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      );

  @override
  HeaderTextTheme lerp(ThemeExtension<HeaderTextTheme>? other, double t) {
    if (other is! HeaderTextTheme) return this;
    return HeaderTextTheme(
      headerTitle: TextStyle.lerp(headerTitle, other.headerTitle, t)!,
      headerSubtitle:
          TextStyle.lerp(headerSubtitle, other.headerSubtitle, t)!,
    );
  }
}

class AppTheme {
  static const String fontFamilyLatin = 'Inter';
  static const String fontFamilyUrdu = 'Noto Nastaliq Urdu';

  static String fontFamilyFor(Locale? locale) =>
      locale?.languageCode == 'ur' ? fontFamilyUrdu : fontFamilyLatin;

  static TextTheme _textTheme({
    required String fontFamily,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    TextStyle base({
      required double fontSize,
      required FontWeight fontWeight,
      required double height,
      required Color color,
    }) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        );
    return TextTheme(
      displayLarge: base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        color: onSurface,
      ),
      titleLarge: base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 26 / 20,
        color: onSurface,
      ),
      titleMedium: base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 22 / 16,
        color: onSurface,
      ),
      titleSmall: base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: onSurface,
      ),
      bodyLarge: base(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 22 / 15,
        color: onSurface,
      ),
      bodyMedium: base(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: onSurface,
      ),
      bodySmall: base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: onSurfaceVariant,
      ),
      labelLarge: base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: onSurface,
      ),
      labelMedium: base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: onSurfaceVariant,
      ),
      labelSmall: base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
        color: onSurfaceVariant,
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fillColor,
    required Color hintColor,
    required Color labelColor,
    required Color floatingLabelColor,
    required Color borderColor,
    required Color focusedColor,
    required Color errorColor,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          // Rulebook §4.4: inputs radius 16.
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor, fontSize: 13),
      labelStyle: TextStyle(color: labelColor),
      floatingLabelStyle: TextStyle(color: floatingLabelColor),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: border(borderColor),
      enabledBorder: border(borderColor),
      // Rulebook §4.4: focused 2 px primary border.
      focusedBorder: border(focusedColor, 2),
      errorBorder: border(errorColor),
      focusedErrorBorder: border(errorColor, 2),
    );
  }

  // Button labels (user decision 2026-11-09): regular weight, never bold.
  // Primary (elevated/filled) labels are 14sp; secondary
  // (outlined/text) labels are 13sp (audit 2026-11-15 DS-8: 12sp is
  // off-scale — §4.5 has no 12sp step). `fontSize` picks the tier.
  static ButtonStyle _buttonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    double fontSize = 14,
  }) {
    // Disabled buttons dim instead of looking identical to enabled
    // ones (the old WidgetStateProperty.all never dimmed).
    Color dim(Color color, Set<WidgetState> states) =>
        states.contains(WidgetState.disabled)
            ? color.withValues(alpha: 0.38)
            : color;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => dim(backgroundColor, states),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => dim(foregroundColor, states),
      ),
      minimumSize: WidgetStateProperty.all(
        const Size(64, AppDimensions.buttonHeight),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStateProperty.resolveWith(
        (states) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: dim(borderColor, states), width: 1.5),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400),
      ),
    );
  }

  // Default (Inter) themes, for tests and anywhere the locale is not in
  // scope. main.dart uses lightThemeFor/darkThemeFor with the locale font.
  static ThemeData get lightTheme => lightThemeFor();
  static ThemeData lightThemeFor({String fontFamily = fontFamilyLatin}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      // Audit SH-N8: the header 18/12 pair lives in the theme.
      extensions: <ThemeExtension<dynamic>>[
        HeaderTextTheme.forFont(fontFamily),
      ],
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      // Dropdown menus fall back to canvasColor; keep it the surface so
      // menus match the theme in both modes.
      canvasColor: AppColors.surfaceLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        // Audit 2026-11-15 AC-10: `secondary` #F95700 with white
        // onSecondary is 3.29:1 — the scheme's secondary is the
        // orangeFill #C2410C instead (white on it is 5.18:1), so any
        // widget reading onSecondary as text inherits a passing pair.
        // #F95700 stays the brand / large-fill token in AppColors.
        secondary: AppColors.orangeFill,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.onSurfaceLight,
        onSurfaceVariant: AppColors.onSurfaceVariantLight,
        surfaceContainer: AppColors.surfaceElevated,
        surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
        // Audit 2026-11-15 AC-10: `error` was accentDanger #EF4444
        // with white onError (3.76:1). errorDark #DC2626 with white
        // onError is 4.83:1.
        error: AppColors.errorDark,
        onError: Colors.white,
      ),
      textTheme: _textTheme(
        fontFamily: fontFamily,
        onSurface: AppColors.onSurfaceLight,
        onSurfaceVariant: AppColors.onSurfaceVariantLight,
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: AppColors.backgroundLight,
        hintColor: AppColors.onSurfaceVariantLight,
        labelColor: AppColors.onSurfaceVariantLight,
        floatingLabelColor: AppColors.onSurfaceLight,
        borderColor: AppColors.borderSubtle,
        focusedColor: AppColors.primary,
        errorColor: AppColors.accentDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          // Audit SH-M1: white on `secondary` #F95700 is 3.29:1 — it
          // fails WCAG AA for the 14 sp label. `orangeFill` #C2410C
          // is 5.18:1 with white in BOTH modes, so primary buttons
          // use it; #F95700 stays the brand / large-fill token only.
          backgroundColor: AppColors.orangeFill,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          backgroundColor: AppColors.orangeFill,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          borderColor: AppColors.primary,
          fontSize: 13,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          fontSize: 13,
        ),
      ),
      // Card rework (2026-11-10), showroom redesign Phase 0
      // (2026-11-16): the guide reintroduces a 1 px hairline border
      // in `borderSubtle` (`#E2E8F0` light / `#23274D` dark) with
      // elevation 1.5 and radius 16 — the 2026-11-10 borderless look
      // is superseded deliberately (the old 1 px `dividerColor` side
      // read as a dark outline because it resolved to M3 `outline`,
      // a mid-grey; the hairline uses the subtle token instead).
      // Light: white card on the #F8FAFC screen; elevation 1.5 with
      // a soft shadow.
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primary,
        // Audit 2026-11-15 AC-1: white on `secondary` #F95700 is
        // 3.29:1 (light) / 2.81:1 (dark) — the selected icon failed
        // even the 3:1 non-text threshold in dark. orangeFill
        // #C2410C with the white icon is 5.18:1 in both modes.
        indicatorColor: AppColors.orangeFill,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return IconThemeData(
            color: Colors.white.withValues(alpha: 0.6),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.cardRadius),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        // Audit 2026-11-15 DS-1: ONE selected-chip spec — navy fill
        // + white label (white on primary #1B1E5C is 15.14:1). The
        // pale primaryContainer selected state was the weakest of
        // three dialects; per-file selectedColor overrides are gone.
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceElevated,
        // Audit 2026-11-15 DS-8: the 12 sp label is off-scale (§4.5:
        // 28/20/16/15/13/11) — labelSmall 11.
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceLight,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.onSurfaceVariantLight,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        // Audit 2026-11-15 AC-10: white on `secondary` #F95700 is
        // 3.29:1 — latent (the one FAB overrides), so the theme pair
        // is orangeFill + white (5.18:1) like the buttons.
        backgroundColor: AppColors.orangeFill,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
        linearTrackColor: AppColors.primaryContainer,
        circularTrackColor: AppColors.primaryContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.onSurfaceVariantLight;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.borderSubtle),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      // Audit SH-N10: booking flows use date/time pickers and owner
      // flows use switches/checkboxes/radios — these rendered with
      // unthemed M3 defaults. They now follow the theme in both modes.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceLight,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : null),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.onSurfaceLight),
        todayForegroundColor:
            WidgetStateProperty.all(AppColors.primary),
        todayBackgroundColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceLight,
        hourMinuteColor: AppColors.primaryContainer,
        hourMinuteTextColor: AppColors.primary,
        dayPeriodColor: AppColors.primaryContainer,
        dayPeriodTextColor: AppColors.primary,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.surfaceElevated,
        entryModeIconColor: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.borderSubtle),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.onSurfaceVariantLight),
      ),
    );
  }

  static ThemeData get darkTheme => darkThemeFor();
  static ThemeData darkThemeFor({String fontFamily = fontFamilyLatin}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      // Audit SH-N8: the header 18/12 pair lives in the theme.
      extensions: <ThemeExtension<dynamic>>[
        HeaderTextTheme.forFont(fontFamily),
      ],
      primaryColor: AppColors.primaryOnDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      // Dropdown menus fall back to canvasColor; keep it the surface so
      // menus match the theme in both modes.
      canvasColor: AppColors.surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOnDark,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainerOnDark,
        // Audit 2026-11-15 AC-10: same orangeFill secondary as light
        // (white on secondaryDark #FF6D24 is 2.81:1).
        secondary: AppColors.orangeFill,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryLightDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        surfaceContainer: AppColors.surfaceContainerDark,
        surfaceContainerLow: AppColors.backgroundDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
        // Audit 2026-11-15 AC-10: the dark error fill stays the
        // light red #F87171 (6.48:1 as text on the dark surface —
        // `error` is read as a text colour by error labels) with a
        // dark onError (6.59:1 on the fill, the M3 dark pattern).
        // errorDark #DC2626 as the fill would pass for white onError
        // (4.83:1) but reads only ~3.67:1 as text on #13152C.
        error: AppColors.accentDangerDark,
        onError: AppColors.surfaceDark,
      ),
      textTheme: _textTheme(
        fontFamily: fontFamily,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
      ),
      inputDecorationTheme: _inputTheme(
        fillColor: AppColors.surfaceContainerHighestDark,
        hintColor: AppColors.onSurfaceVariantDark,
        labelColor: AppColors.onSurfaceVariantDark,
        floatingLabelColor: AppColors.onSurfaceDark,
        borderColor: AppColors.borderDark,
        focusedColor: AppColors.primaryFocusedOnDark,
        errorColor: AppColors.accentDangerDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDarkOnDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(
          // Audit SH-M1: dark `secondaryDark` #FF6D24 is 2.81:1 with
          // white — worse than light. Same `orangeFill` #C2410C
          // (5.18:1) in both modes.
          backgroundColor: AppColors.orangeFill,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          backgroundColor: AppColors.orangeFill,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onSurfaceDark,
          borderColor: AppColors.onSurfaceDark,
          fontSize: 13,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onSurfaceDark,
          fontSize: 13,
        ),
      ),
      // Card rework (2026-11-10), showroom redesign Phase 0
      // (2026-11-16): same 1 px hairline + elevation 1.5 + radius 16
      // as light, with the dark border token. Dark: #13152C card on
      // the #0A0B1A screen, so the card is a lighter slab than the
      // screen and still lifts; the shadow is stronger because it
      // falls on near-black.
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primaryDarkOnDark,
        // Audit 2026-11-15 AC-1: same orangeFill indicator as light
        // (white on secondaryDark #FF6D24 is 2.81:1).
        indicatorColor: AppColors.orangeFill,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return IconThemeData(
            color: Colors.white.withValues(alpha: 0.6),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.cardRadius),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighestDark,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        // Audit 2026-11-15 DS-1: same navy selected fill as light
        // (white label on primary #1B1E5C is 15.14:1).
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceContainerDark,
        // Audit 2026-11-15 DS-8: the 12 sp label is off-scale (§4.5)
        // — labelSmall 11.
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.onSurfaceVariantDark,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        // Audit 2026-11-15 AC-10: same orangeFill FAB as light
        // (white on secondaryDark #FF6D24 is 2.81:1).
        backgroundColor: AppColors.orangeFill,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondaryDark,
        linearTrackColor: AppColors.primaryContainerOnDark,
        circularTrackColor: AppColors.primaryContainerOnDark,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryContainerOnDark;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.onSurfaceVariantDark;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.borderDark),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      // Audit SH-N10: same picker/switch/checkbox/radio theming as
      // light, with the dark tokens (see the light theme above).
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        headerBackgroundColor: AppColors.primaryDarkOnDark,
        headerForegroundColor: Colors.white,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primaryOnDark
                : null),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.onSurfaceDark),
        todayForegroundColor:
            WidgetStateProperty.all(AppColors.primaryFocusedOnDark),
        todayBackgroundColor:
            WidgetStateProperty.all(Colors.transparent),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        hourMinuteColor: AppColors.primaryContainerOnDark,
        hourMinuteTextColor: Colors.white,
        dayPeriodColor: AppColors.primaryContainerOnDark,
        dayPeriodTextColor: Colors.white,
        dialHandColor: AppColors.primaryFocusedOnDark,
        dialBackgroundColor: AppColors.surfaceContainerDark,
        entryModeIconColor: AppColors.primaryFocusedOnDark,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primaryOnDark
                : AppColors.borderDark),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primaryOnDark
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.borderDark, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primaryFocusedOnDark
                : AppColors.onSurfaceVariantDark),
      ),
    );
  }
}
