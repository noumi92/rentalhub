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
