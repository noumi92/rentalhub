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

  static ButtonStyle _buttonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.all(backgroundColor),
      foregroundColor: WidgetStateProperty.all(foregroundColor),
      minimumSize: WidgetStateProperty.all(const Size(64, 48)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
        surfaceContainer: AppColors.surfaceElevated,
        surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
        error: AppColors.accentDanger,
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
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          borderColor: AppColors.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.secondary,
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
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surfaceElevated,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceLight,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
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
        backgroundColor: AppColors.secondary,
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
    );
  }

  static ThemeData get darkTheme => darkThemeFor();
  static ThemeData darkThemeFor({String fontFamily = fontFamilyLatin}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      primaryColor: AppColors.primaryOnDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOnDark,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainerOnDark,
        secondary: AppColors.secondaryDark,
        onSecondary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        surfaceContainer: AppColors.surfaceContainerDark,
        surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
        error: AppColors.accentDangerDark,
        onError: Colors.white,
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
        focusedColor: AppColors.primaryOnDark,
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
          backgroundColor: AppColors.secondaryDark,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(
          backgroundColor: AppColors.secondaryDark,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onSurfaceDark,
          borderColor: AppColors.onSurfaceDark,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _buttonStyle(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onSurfaceDark,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primaryDarkOnDark,
        indicatorColor: AppColors.secondaryDark,
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
        selectedColor: AppColors.primaryContainerOnDark,
        disabledColor: AppColors.surfaceContainerDark,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
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
        backgroundColor: AppColors.secondaryDark,
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
    );
  }
}
