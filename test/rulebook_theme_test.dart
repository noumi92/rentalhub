// Rulebook theme tests — DOC-12 (`.ai/doc12_comprehensive_rulebook.md`), §4 & §6.
//
// Static tests check the §4.2 colour tokens in `AppColors`; widget tests
// check the themes actually render those tokens. Target-state tests for
// work that does not exist yet are `skip:`ped with their debt ID
// (rulebook §7.7) — they show as pending, never as silent passes.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_feedback.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Rulebook §4.2: tokens that exist in `AppColors` today, with the exact
// values the docs require. If a value changes, the rulebook (§4.2) and
// this map change together — never one without the other.
const Map<String, String> kLightTokens = {
  'primary': '0xFF1B1E5C',
  // Showroom redesign Phase 0 (2026-11-16): the light AppBar navy is
  // #0F172A (was #16194F); the dark AppBar stays #0B0D26.
  'primaryDark': '0xFF0F172A',
  'primaryContainer': '0xFFEEF0FF',
  'primaryOnDark': '0xFF252B7A',
  'primaryContainerOnDark': '0xFF1A1D42',
  'primaryDarkOnDark': '0xFF0B0D26',
  'secondary': '0xFFF95700',
  // Rulebook §4.2: the bright orange is the *dark* secondary
  // (secondaryDark); the pale tint lives under secondaryContainer.
  // Audit SH-N3 deleted the duplicate names primaryLight and
  // secondaryLight — they are gone from AppColors and from here.
  'secondaryDark': '0xFFFF6D24',
  'secondaryLightDark': '0xFF3D1B08',
  'backgroundLight': '0xFFF8FAFC',
  'backgroundDark': '0xFF0A0B1A',
  'surfaceLight': '0xFFFFFFFF',
  'surfaceDark': '0xFF13152C',
  'surfaceElevated': '0xFFF1F5F9',
  'surfaceElevatedDark': '0xFF1C1F3D',
  'onSurfaceLight': '0xFF0F172A',
  'onSurfaceDark': '0xFFF8FAFC',
  'onSurfaceVariantLight': '0xFF64748B',
  'onSurfaceVariantDark': '0xFF94A3B8',
  'accentDanger': '0xFFEF4444',
  'accentDangerDark': '0xFFF87171',
  'accentSuccess': '0xFF10B981',
  'accentSuccessDark': '0xFF34D399',
  'borderSubtle': '0xFFE2E8F0',
  'borderDark': '0xFF23274D',
  // Showroom redesign Phase 0 (2026-11-16): guide accent + badge tints.
  'accentOrange': '0xFFEA580C',
  'successBadge': '0xFFDCFCE7',
  'errorBadge': '0xFFFEE2E2',
};

// Rulebook §4.2 (Phase A3): the dark container / on-container tokens.
// The pale light containers glare in dark mode, so dark mode uses
// these darker slabs with a light on-container colour for the text
// and icons that sit on them. `primaryFocusedOnDark` exists because
// `primaryOnDark` is invisible against the dark field fill.
const Map<String, String> kDarkContainerTokens = {
  'successContainer': '0xFFECFDF5',
  'successContainerDark': '0xFF123524',
  'successOnContainerDark': '0xFF86EFAC',
  'errorContainer': '0xFFFEF2F2',
  'errorContainerDark': '0xFF3B1215',
  'errorOnContainerDark': '0xFFFCA5A5',
  'warning': '0xFFF59E0B',
  'warningContainer': '0xFFFFFBEB',
  'warningContainerDark': '0xFF3A2A05',
  'warningOnContainerDark': '0xFFFCD34D',
  'primaryFocusedOnDark': '0xFF6C72D9',
  'surfaceContainerDark': '0xFF171A30',
  'surfaceContainerHighestDark': '0xFF1E2138',
  'surfaceContainerHighestLight': '0xFFF8FAFC',
  'headerGradientEnd': '0xFF242875',
  'errorDark': '0xFFDC2626',
};

// Rulebook §4.2: every canonical token NAME must bind to its rulebook
// VALUE in `AppColors` — a hex-presence check alone would pass if the
// value lived under the wrong name. The surviving legacy aliases
// (`textPrimary`, `textSecondary`, `textMuted` — @Deprecated, see the
// SH-N3 test below) are excluded: they reference another constant
// instead of a literal.
const Map<String, String> kTokenBindings = {
  'primary': '0xFF1B1E5C',
  'primaryDark': '0xFF0F172A',
  'primaryOnDark': '0xFF252B7A',
  'primaryContainerOnDark': '0xFF1A1D42',
  'primaryDarkOnDark': '0xFF0B0D26',
  'primaryContainer': '0xFFEEF0FF',
  'secondary': '0xFFF95700',
  'secondaryDark': '0xFFFF6D24',
  'secondaryLightDark': '0xFF3D1B08',
  'secondaryContainer': '0xFFFFF3EB',
  'backgroundLight': '0xFFF8FAFC',
  'backgroundDark': '0xFF0A0B1A',
  'surfaceLight': '0xFFFFFFFF',
  'surfaceDark': '0xFF13152C',
  'surfaceElevated': '0xFFF1F5F9',
  'surfaceElevatedDark': '0xFF1C1F3D',
  'onSurfaceLight': '0xFF0F172A',
  'onSurfaceDark': '0xFFF8FAFC',
  'onSurfaceVariantLight': '0xFF64748B',
  'onSurfaceVariantDark': '0xFF94A3B8',
  'accentDanger': '0xFFEF4444',
  'accentDangerDark': '0xFFF87171',
  'accentSuccess': '0xFF10B981',
  'accentSuccessDark': '0xFF34D399',
  'borderSubtle': '0xFFE2E8F0',
  'borderDark': '0xFF23274D',
  'successContainer': '0xFFECFDF5',
  'successContainerDark': '0xFF123524',
  'successOnContainerDark': '0xFF86EFAC',
  'errorContainer': '0xFFFEF2F2',
  'errorContainerDark': '0xFF3B1215',
  'errorOnContainerDark': '0xFFFCA5A5',
  'warning': '0xFFF59E0B',
  'warningContainer': '0xFFFFFBEB',
  'warningContainerDark': '0xFF3A2A05',
  'warningOnContainerDark': '0xFFFCD34D',
  'primaryFocusedOnDark': '0xFF6C72D9',
  'surfaceContainerDark': '0xFF171A30',
  'surfaceContainerHighestDark': '0xFF1E2138',
  'headerGradientEnd': '0xFF242875',
  'errorDark': '0xFFDC2626',
  // Showroom redesign Phase 0 (2026-11-16): guide accent + badge tints.
  // No `errorStrong` binding: `errorText` #B91C1C already IS that value
  // (one name per value, SH-N3), so the badge error text is `errorText`.
  'accentOrange': '0xFFEA580C',
  'successBadge': '0xFFDCFCE7',
  'errorBadge': '0xFFFEE2E2',
  // Audit SH-N1/SH-N14: tokens added for the splash gradient, the
  // plate strips and the light warning on-container text.
  'splashBackground': '0xFF131842',
  'splashGradientTop': '0xFF0F1336',
  'splashGradientMiddle': '0xFF161B4A',
  'splashGradientBottom': '0xFF12163F',
  'plateStripIslamabad': '0xFF1E3A8A',
  'plateStripDefault': '0xFF15803D',
  'warningOnContainer': '0xFF92400E',
};

void main() {
  group('Rulebook §4.2 — colour tokens', () {
    test('AppColors contains every required light/dark token value', () {
      final content =
          File('lib/core/constants/app_colors.dart').readAsStringSync();
      final missing = <String>[];
      kLightTokens.forEach((name, hex) {
        if (!content.contains(hex)) missing.add('$name $hex');
      });
      expect(missing, isEmpty,
          reason:
              'Rulebook §4.2: token values missing from AppColors:\n${missing.join('\n')}');
    });

    test('AppColors contains the dark container / on-container tokens', () {
      final content =
          File('lib/core/constants/app_colors.dart').readAsStringSync();
      final missing = <String>[];
      kDarkContainerTokens.forEach((name, hex) {
        if (!content.contains(hex)) missing.add('$name $hex');
      });
      expect(missing, isEmpty,
          reason:
              'Rulebook §4.2 (Phase A3): dark container tokens missing from AppColors:\n${missing.join('\n')}');
    });

    test('AppColors binds each canonical token name to its rulebook value',
        () {
      // A hex-presence check would pass if the value lived under the
      // wrong name; this test pins the name -> value binding for
      // every canonical token, light and dark, including the
      // container / on-container tokens.
      final content =
          File('lib/core/constants/app_colors.dart').readAsStringSync();
      final wrong = <String>[];
      kTokenBindings.forEach((name, hex) {
        if (!content.contains('static const Color $name = Color($hex)')) {
          wrong.add('$name should be $hex');
        }
      });
      expect(wrong, isEmpty,
          reason:
              'Rulebook §4.2: token name/value bindings wrong in AppColors:\n${wrong.join('\n')}');
    });

    test('app_theme.dart contains zero colour literals anywhere (D9)', () {
      // Rulebook §6.3 / D9: every colour in the theme file comes from
      // AppColors. The earlier test only scanned the dark section;
      // this one scans the whole file. The file's doc comment mentions
      // `Color(0xFF…)` with an ellipsis, which the strict regex below
      // does not match — only a real 6-digit literal fails.
      final content =
          File('lib/core/theme/app_theme.dart').readAsStringSync();
      final literals =
          RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)').allMatches(content).length;
      expect(literals, 0,
          reason:
              'Rulebook §6.3 (D9): app_theme.dart has $literals hardcoded colour literals. New literals are banned — use AppColors.');
    });

    test('dark theme hardcodes no colour literals (D9 resolved in Phase A)',
        () {
      // Rulebook §6.3 / D9: Phase A moved every dark colour into
      // AppColors, so the theme file must contain zero literals. The
      // number must stay at zero.
      final content =
          File('lib/core/theme/app_theme.dart').readAsStringSync();
      final darkSection = content.split('darkTheme').last;
      final literals =
          RegExp(r'Color\(0xFF[0-9A-Fa-f]{6}\)').allMatches(darkSection).length;
      expect(literals, 0,
          reason:
              'Rulebook §6.3 (D9): dark theme has $literals hardcoded colour literals. New literals are banned — use AppColors.');
    });
  });

  group('Rulebook §6 — rendered themes', () {
    testWidgets('light theme renders the §4.2 tokens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold()),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.colorScheme.primary, const Color(0xFF1B1E5C));
      // Audit 2026-11-15 AC-10: the scheme's secondary is orangeFill
      // now (white on #F95700 was 3.29:1); #F95700 stays the brand
      // token in AppColors.
      expect(theme.colorScheme.secondary, const Color(0xFFC2410C));
      expect(theme.colorScheme.primaryContainer, const Color(0xFFEEF0FF));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('dark theme renders the §4.2 dark tokens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const Scaffold()),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.colorScheme.primary, const Color(0xFF252B7A));
      // Audit 2026-11-15 AC-10: the scheme's secondary is orangeFill
      // now (white on #FF6D24 was 2.81:1).
      expect(theme.colorScheme.secondary, const Color(0xFFC2410C));
      expect(theme.colorScheme.primaryContainer, const Color(0xFF1A1D42));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0A0B1A));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('dark theme uses the dark container tokens, light the light ones',
        (tester) async {
      // Rulebook §4.2 (Phase A3): the dark theme's surface containers
      // are the dark container tokens, not the light tints — a pale
      // container glares on a dark surface.
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const Scaffold()),
      );
      final dark = Theme.of(tester.element(find.byType(Scaffold)));
      expect(dark.colorScheme.surfaceContainer, const Color(0xFF171A30));
      expect(
          dark.colorScheme.surfaceContainerHighest, const Color(0xFF1E2138));
      expect(dark.colorScheme.secondaryContainer, const Color(0xFF3D1B08));

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold()),
      );
      // AnimatedTheme lerps from the dark theme over 200 ms — settle
      // the animation before reading, or Theme.of still returns dark.
      await tester.pumpAndSettle();
      final light = Theme.of(tester.element(find.byType(Scaffold)));
      expect(light.colorScheme.surfaceContainer, const Color(0xFFF1F5F9));
      expect(light.colorScheme.surfaceContainerHighest,
          const Color(0xFFF8FAFC));
      expect(light.colorScheme.secondaryContainer, const Color(0xFFFFF3EB));
    });

    testWidgets('light and dark themes differ (dark is not a copy of light)',
        (tester) async {
      expect(AppTheme.lightTheme.colorScheme.primary,
          isNot(AppTheme.darkTheme.colorScheme.primary));
      expect(AppTheme.lightTheme.scaffoldBackgroundColor,
          isNot(AppTheme.darkTheme.scaffoldBackgroundColor));
    });

    test('themeMode follows a persisted user choice, not a hardcoded value',
        () {
      // Phase B (G3): D8 resolved — main.dart reads the persisted
      // choice from AppSettingsCubit instead of hardcoding light.
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, isNot(contains('themeMode: ThemeMode.light')));
      expect(main, contains('themeMode: settings.themeMode'));
      final cubit = File('lib/core/settings/app_settings_cubit.dart')
          .readAsStringSync();
      expect(cubit, contains("app_theme_mode"));
    });

    test('Light is the default; a saved choice is untouched', () async {
      // Rulebook §6.1 (phone-test #16): fresh installs start in Light.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(AppSettingsCubit(prefs: prefs).state.themeMode,
          ThemeMode.light);

      // An unknown stored value falls back to Light, not System.
      await prefs.setString(AppSettingsCubit.themeKey, 'bogus');
      expect(AppSettingsCubit(prefs: prefs).state.themeMode,
          ThemeMode.light);

      // An explicitly saved System (or Dark) choice is preserved.
      await prefs.setString(AppSettingsCubit.themeKey, 'system');
      expect(AppSettingsCubit(prefs: prefs).state.themeMode,
          ThemeMode.system);
      await prefs.setString(AppSettingsCubit.themeKey, 'dark');
      expect(AppSettingsCubit(prefs: prefs).state.themeMode,
          ThemeMode.dark);
    });

    test('dark theme reads all colours from AppColors (no inline literals)',
        () {
      // D9 resolved in Phase A: the dark theme section of app_theme.dart
      // contains no Color(0xFF...) literals at all.
      final content =
          File('lib/core/theme/app_theme.dart').readAsStringSync();
      final darkSection = content.split('darkTheme').last;
      final literals =
          RegExp(r'Color\(0xFF[0-9A-Fa-f]{6}\)').allMatches(darkSection).length;
      expect(literals, 0);
    });
  });

  group('Audit 2026-11-13 (shared) — contrast and token hygiene', () {
    test('primary buttons: white on orangeFill passes WCAG AA, both modes (SH-M1)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final style in [
          theme.elevatedButtonTheme.style,
          theme.filledButtonTheme.style,
        ]) {
          final bg =
              style?.backgroundColor?.resolve(<WidgetState>{});
          final fg =
              style?.foregroundColor?.resolve(<WidgetState>{});
          // White on secondary #F95700 was 3.29:1 (light) and on
          // secondaryDark #FF6D24 2.81:1 (dark) — both fail AA for
          // the 14 sp label. orangeFill #C2410C is 5.18:1.
          expect(bg, const Color(0xFFC2410C));
          expect(fg, Colors.white);
          expect(_contrastRatio(fg!, bg!), greaterThanOrEqualTo(4.5));
        }
        // SH-N7: the themed minimum height is the 54 dp CTA standard.
        final minSize = theme.elevatedButtonTheme.style?.minimumSize
            ?.resolve(<WidgetState>{});
        expect(minSize, const Size(64, 54));
      }
    });

    testWidgets('DebouncedButton defaults to orangeFill with white text (SH-M1)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DebouncedButton(text: 'Save', onPressed: () {}),
          ),
        ),
      );
      final style =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).style;
      final bg = style?.backgroundColor?.resolve(<WidgetState>{});
      final fg = style?.foregroundColor?.resolve(<WidgetState>{});
      expect(bg, const Color(0xFFC2410C));
      expect(fg, Colors.white);
      expect(_contrastRatio(fg!, bg!), greaterThanOrEqualTo(4.5));
    });

    testWidgets('light snackbars: white text on strong fills passes WCAG AA (SH-M2)',
        (tester) async {
      // White on accentSuccess #10B981 was 2.54:1, on accentDanger
      // #EF4444 3.76:1, on secondary #F95700 3.29:1 — all fail AA
      // for the 13 sp w700 text. The strong fills measure 5.48:1,
      // 4.83:1 and 5.18:1.
      final cases = <(void Function(BuildContext, String), Color)>[
        (AppFeedback.showSuccess, const Color(0xFF047857)),
        (AppFeedback.showError, const Color(0xFFDC2626)),
        (AppFeedback.showWarning, const Color(0xFFC2410C)),
      ];
      for (final (show, expectedBg) in cases) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => show(context, 'Test message'),
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        final bar = tester.widget<SnackBar>(find.byType(SnackBar));
        final text = tester.widget<Text>(find.text('Test message'));
        expect(bar.backgroundColor, expectedBg);
        expect(text.style?.color, Colors.white);
        expect(
          _contrastRatio(Colors.white, bar.backgroundColor!),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('dark snackbars keep the container pairs readable (SH-M2)',
        (tester) async {
      // Dark mode was already fine (dark containers + light
      // on-container text); pin the pairs so a later change cannot
      // silently reintroduce white-on-bright fills there.
      final cases = <(void Function(BuildContext, String), Color, Color)>[
        (
          AppFeedback.showSuccess,
          const Color(0xFF123524),
          const Color(0xFF86EFAC),
        ),
        (
          AppFeedback.showError,
          const Color(0xFF3B1215),
          const Color(0xFFFCA5A5),
        ),
        (
          AppFeedback.showWarning,
          const Color(0xFF3A2A05),
          const Color(0xFFFCD34D),
        ),
      ];
      for (final (show, expectedBg, expectedFg) in cases) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => show(context, 'Test message'),
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        final bar = tester.widget<SnackBar>(find.byType(SnackBar));
        final text = tester.widget<Text>(find.text('Test message'));
        expect(bar.backgroundColor, expectedBg);
        expect(text.style?.color, expectedFg);
        expect(
          _contrastRatio(expectedFg, expectedBg),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('destructive confirm: white on errorDark, radius 16, no custom padding (SH-M2/SH-N9)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => AppFeedback.showConfirmDialog(
                    context: context,
                    title: 'Delete?',
                    message: 'Sure?',
                    isDestructive: true,
                  ),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final style = tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Confirm'))
          .style;
      final bg = style?.backgroundColor?.resolve(<WidgetState>{});
      final fg = style?.foregroundColor?.resolve(<WidgetState>{});
      expect(bg, const Color(0xFFDC2626));
      expect(fg, Colors.white);
      expect(_contrastRatio(fg!, bg!), greaterThanOrEqualTo(4.5));
      final shape =
          style?.shape?.resolve(<WidgetState>{}) as RoundedRectangleBorder?;
      expect(shape?.borderRadius, BorderRadius.circular(16));
      expect(style?.padding, isNull,
          reason: 'The theme owns the confirm padding — no custom padding.');
    });

    test('no hardcoded colour literals in the shared files (SH-N1)', () {
      // The six audit-cited files, minus the two owner files
      // (whatsapp_log_tile.dart, owner_whatsapp_template_preview_view.dart)
      // — those are the owner worker's files, not this change's.
      const files = [
        'lib/features/auth/presentation/views/splash_view.dart',
        'lib/features/auth/presentation/views/widgets/google_sign_in_button.dart',
        'lib/core/widgets/pakistani_plate_widget.dart',
        'lib/core/widgets/vehicle_damage_schematic_widget.dart',
      ];
      final offenders = <String>[];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        final literals =
            RegExp(r'Color\(0x[0-9A-Fa-f]{6,8}\)').allMatches(content).length;
        if (literals > 0) offenders.add('$path ($literals)');
      }
      expect(offenders, isEmpty,
          reason:
              'Hardcoded colour literals survive — use AppColors:\n${offenders.join('\n')}');
    });

    test('no new token aliases in AppColors; legacy aliases stay deprecated (SH-N3)', () {
      final content =
          File('lib/core/constants/app_colors.dart').readAsStringSync();
      // Deleted aliases must not come back. (The ' =' suffix matters:
      // `secondaryLightDark` is a legitimate, different token.)
      for (final name in ['primaryLight', 'secondaryLight', 'textMutedDark']) {
        expect(content, isNot(contains('static const Color $name =')),
            reason: 'Deleted alias $name is back in AppColors.');
      }
      expect(content, isNot(contains('static const Color background =')),
          reason: 'Deleted alias background is back in AppColors.');
      expect(content, isNot(contains('static const Color surface =')),
          reason: 'Deleted alias surface is back in AppColors.');
      // The three surviving legacy aliases are explicitly deprecated
      // and point at their canonical name — new code must use it.
      const legacy = {
        'textPrimary': 'onSurfaceLight',
        'textSecondary': 'onSurfaceVariantLight',
        'textMuted': 'onSurfaceVariantLight',
      };
      for (final entry in legacy.entries) {
        expect(
          RegExp("@Deprecated\\('Use ${entry.value} instead'\\)\\s*\n\\s*static const Color ${entry.key} =")
              .hasMatch(content),
          isTrue,
          reason:
              'Legacy alias ${entry.key} must stay @Deprecated and point at ${entry.value}.',
        );
      }
    });

    test('header text theme carries the 18/12 pair in both modes (SH-N8)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final header = theme.extension<HeaderTextTheme>();
        expect(header, isNotNull);
        expect(header!.headerTitle.fontSize, 18);
        expect(header.headerTitle.fontWeight, FontWeight.w900);
        expect(header.headerTitle.color, Colors.white);
        expect(header.headerSubtitle.fontSize, 12);
        expect(header.headerSubtitle.color, Colors.white70);
      }
      // Urdu caps at w700 (Noto Nastaliq Urdu spans wght 400–700).
      final urdu = HeaderTextTheme.forFont(AppTheme.fontFamilyUrdu);
      expect(urdu.headerTitle.fontWeight, FontWeight.w700);
      // Inter keeps w900 (wght 100–900).
      expect(HeaderTextTheme.forFont(AppTheme.fontFamilyLatin)
          .headerTitle
          .fontWeight, FontWeight.w900);
    });

    test('picker and switch/checkbox/radio themes exist in both modes (SH-N10)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.datePickerTheme.backgroundColor, isNotNull);
        expect(theme.datePickerTheme.headerBackgroundColor, isNotNull);
        expect(theme.timePickerTheme.backgroundColor, isNotNull);
        expect(theme.timePickerTheme.dialHandColor, isNotNull);
        expect(theme.switchTheme.trackColor, isNotNull);
        expect(theme.checkboxTheme.fillColor, isNotNull);
        expect(theme.radioTheme.fillColor, isNotNull);
      }
    });
  });

  group('Audit 2026-11-15 (Team A) — nav indicator, on* pairs, chips, FAB, disabled button', () {
    test('nav selected indicator: white icon on orangeFill passes WCAG AA, both modes (AC-1)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        // White on secondary #F95700 was 3.29:1 (light) and on
        // secondaryDark #FF6D24 2.81:1 (dark) — both fail AA for the
        // 24 px selected icon. orangeFill #C2410C is 5.18:1.
        expect(theme.navigationBarTheme.indicatorColor,
            const Color(0xFFC2410C));
        final icon = theme.navigationBarTheme.iconTheme
            ?.resolve({WidgetState.selected});
        expect(icon?.color, Colors.white);
        expect(
          _contrastRatio(
              Colors.white, theme.navigationBarTheme.indicatorColor!),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('every on* colour measures >=4.5:1 against its fill, both schemes (AC-10)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final scheme = theme.colorScheme;
        final pairs = <(Color, Color, String)>[
          (scheme.onPrimary, scheme.primary, 'onPrimary/primary'),
          (scheme.onSecondary, scheme.secondary, 'onSecondary/secondary'),
          (scheme.onSurface, scheme.surface, 'onSurface/surface'),
          (
            scheme.onSurfaceVariant,
            scheme.surface,
            'onSurfaceVariant/surface'
          ),
          (scheme.onError, scheme.error, 'onError/error'),
        ];
        for (final (fg, bg, name) in pairs) {
          expect(
            _contrastRatio(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.brightness} $name',
          );
        }
      }
    });

    test('selected chip is navy fill + white w600 label, both modes (DS-1/DS-8)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        // One selected-chip spec: AppColors.primary fill with a
        // white label (15.14:1). The pale primaryContainer selected
        // state and the per-file orange/navy overrides are gone.
        expect(theme.chipTheme.selectedColor, const Color(0xFF1B1E5C));
        expect(theme.chipTheme.secondaryLabelStyle?.color, Colors.white);
        expect(theme.chipTheme.secondaryLabelStyle?.fontWeight,
            FontWeight.w600);
        // DS-8: the 12 sp chip labels were off-scale (§4.5 has no
        // 12 sp step) — labelSmall 11.
        expect(theme.chipTheme.secondaryLabelStyle?.fontSize, 11);
        expect(theme.chipTheme.labelStyle?.fontSize, 11);
      }
    });

    test('FAB is orangeFill + white in both modes (AC-10)', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        // White on secondary #F95700 was 3.29:1 (light) and on
        // secondaryDark #FF6D24 2.81:1 (dark) — latent, but any new
        // FAB would have inherited the failing pair.
        expect(theme.floatingActionButtonTheme.backgroundColor,
            const Color(0xFFC2410C));
        expect(theme.floatingActionButtonTheme.foregroundColor,
            Colors.white);
        expect(
          _contrastRatio(Colors.white,
              theme.floatingActionButtonTheme.backgroundColor!),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('DebouncedButton dims to 0.38 alpha when disabled (AC-20)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DebouncedButton(text: 'Save', onPressed: () {}),
          ),
        ),
      );
      final style =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).style;
      expect(style?.backgroundColor?.resolve(<WidgetState>{}),
          const Color(0xFFC2410C));
      expect(style?.foregroundColor?.resolve(<WidgetState>{}), Colors.white);
      expect(style?.backgroundColor?.resolve({WidgetState.disabled}),
          const Color(0xFFC2410C).withValues(alpha: 0.38));
      expect(style?.foregroundColor?.resolve({WidgetState.disabled}),
          Colors.white.withValues(alpha: 0.38));
    });
  });

  group('Showroom redesign Phase 0 (2026-11-16) — cards, accent orange, badge tints', () {
    test('card radius is 16 (rulebook §4.4) and card themes use elevation 1.5 + 1px borderSubtle hairline', () {
      // Rulebook §4.4 already said cards radius 16; the token was 20.
      expect(AppDimensions.cardRadius, 16.0);
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.cardTheme.elevation, 1.5);
        final shape = theme.cardTheme.shape as RoundedRectangleBorder?;
        expect(shape, isNotNull);
        expect(shape!.borderRadius,
            BorderRadius.circular(AppDimensions.cardRadius));
        final borderColor = theme.brightness == Brightness.dark
            ? AppColors.borderDark
            : AppColors.borderSubtle;
        expect(shape.side, BorderSide(color: borderColor, width: 1));
      }
    });

    test('accentOrange is the guide accent; white on it FAILS AA, so small white labels stay on orangeFill', () {
      expect(AppColors.accentOrange, const Color(0xFFEA580C));
      // White on #EA580C is 3.56:1 — below WCAG AA 4.5:1 for small
      // text. Filled buttons/chips keep orangeFill #C2410C (5.18:1).
      expect(_contrastRatio(Colors.white, AppColors.accentOrange),
          lessThan(4.5));
      expect(_contrastRatio(Colors.white, AppColors.orangeFill),
          greaterThanOrEqualTo(4.5));
      // Dark leg for text/icons on dark surfaces is orangeTextDark.
      expect(AppColors.accentOrangeFor(Brightness.light),
          AppColors.accentOrange);
      expect(AppColors.accentOrangeFor(Brightness.dark),
          AppColors.orangeTextDark);
    });

    test('badge tint pairs pass WCAG AA in both modes', () {
      // Light: guide tints with dark text — #047857 on #DCFCE7 is
      // 4.99:1, #B91C1C on #FEE2E2 is 5.3:1. Dark: the dark containers
      // with their light on-container text.
      expect(
          _contrastRatio(AppColors.accentSuccessStrong,
              AppColors.successBadge),
          greaterThanOrEqualTo(4.5));
      expect(
          _contrastRatio(
              AppColors.errorText, AppColors.errorBadge),
          greaterThanOrEqualTo(4.5));
      expect(
          _contrastRatio(AppColors.successOnContainerDark,
              AppColors.successContainerDark),
          greaterThanOrEqualTo(4.5));
      expect(
          _contrastRatio(AppColors.errorOnContainerDark,
              AppColors.errorContainerDark),
          greaterThanOrEqualTo(4.5));
      // The raw accents must NOT be badge text: #10B981 is 2.31:1
      // and #EF4444 is 3.08:1 as text on their badge tints.
      expect(
          _contrastRatio(
              AppColors.accentSuccess, AppColors.successBadge),
          lessThan(4.5));
      expect(
          _contrastRatio(AppColors.accentDanger, AppColors.errorBadge),
          lessThan(4.5));
    });

    test('AppBar navy is #0F172A light / #0B0D26 dark (white text still passes AA)', () {
      expect(AppTheme.lightTheme.appBarTheme.backgroundColor,
          const Color(0xFF0F172A));
      expect(AppTheme.darkTheme.appBarTheme.backgroundColor,
          const Color(0xFF0B0D26));
      expect(_contrastRatio(Colors.white, AppColors.primaryDark),
          greaterThanOrEqualTo(4.5));
    });
  });
}

/// WCAG 2.x relative luminance / contrast ratio, for the SH-M1/SH-M2
/// assertions. (Measured values: white on orangeFill #C2410C 5.18:1,
/// on accentSuccessStrong #047857 5.48:1, on errorDark #DC2626 4.83:1.)
double _luminance(Color color) {
  double channel(int value) {
    final c = value / 255;
    return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel((color.r * 255.0).round().clamp(0, 255)) +
      0.7152 * channel((color.g * 255.0).round().clamp(0, 255)) +
      0.0722 * channel((color.b * 255.0).round().clamp(0, 255));
}

double _contrastRatio(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}
