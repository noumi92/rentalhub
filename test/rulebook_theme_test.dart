// Rulebook theme tests — DOC-12 (`.ai/doc12_comprehensive_rulebook.md`), §4 & §6.
//
// Static tests check the §4.2 colour tokens in `AppColors`; widget tests
// check the themes actually render those tokens. Target-state tests for
// work that does not exist yet are `skip:`ped with their debt ID
// (rulebook §7.7) — they show as pending, never as silent passes.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';

// Rulebook §4.2: tokens that exist in `AppColors` today, with the exact
// values the docs require. If a value changes, the rulebook (§4.2) and
// this map change together — never one without the other.
const Map<String, String> kLightTokens = {
  'primary': '0xFF1B1E5C',
  'primaryDark': '0xFF16194F',
  'primaryLight': '0xFFEEF0FF',
  'primaryContainer': '0xFFEEF0FF',
  'primaryOnDark': '0xFF252B7A',
  'primaryContainerOnDark': '0xFF1A1D42',
  'primaryDarkOnDark': '0xFF0B0D26',
  'secondary': '0xFFF95700',
  // Rulebook §4.2: secondaryLight is the pale tint; the bright orange is
  // the *dark* secondary (secondaryDark).
  'secondaryLight': '0xFFFFF3EB',
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
// value lived under the wrong name. Aliases (`background`,
// `textPrimary`, `textSecondary`, `textMuted`) are excluded: they
// reference another constant instead of a literal.
const Map<String, String> kTokenBindings = {
  'primary': '0xFF1B1E5C',
  'primaryDark': '0xFF16194F',
  'primaryOnDark': '0xFF252B7A',
  'primaryContainerOnDark': '0xFF1A1D42',
  'primaryDarkOnDark': '0xFF0B0D26',
  'primaryLight': '0xFFEEF0FF',
  'primaryContainer': '0xFFEEF0FF',
  'secondary': '0xFFF95700',
  'secondaryLight': '0xFFFFF3EB',
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
      expect(theme.colorScheme.secondary, const Color(0xFFF95700));
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
      expect(theme.colorScheme.secondary, const Color(0xFFFF6D24));
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
}
