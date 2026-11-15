// Phase A (A4/A5) — dark mode repair and the login/header identity fix.
//
// A4: no Scaffold forces a light background any more — every screen reads
// the theme's scaffoldBackgroundColor, so dark mode is real instead of a
// light screen with dark text. A5: the login screen ships with empty
// fields (no demo credentials) and the header no longer pretends to be a
// fake user.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  group('Phase A4 — dark mode', () {
    test('no widget forces a light background colour', () {
      // The 66 forced `backgroundColor: AppColors.backgroundLight`
      // Scaffold lines are gone; the remaining light fills are the two
      // deliberate near-white surfaces (QR pass, signature pad) which use
      // `color:`, not `backgroundColor:`.
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final content = file.readAsStringSync();
        if (content.contains('backgroundColor: AppColors.backgroundLight')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Light background still forced in:\n${offenders.join('\n')}');
    });

    test('AppTheme has no hardcoded colour literals', () {
      final content =
          File('lib/core/theme/app_theme.dart').readAsStringSync();
      final literals =
          RegExp(r'Color\(0xFF[0-9A-Fa-f]{6}\)').allMatches(content).length;
      expect(literals, 0,
          reason:
              'app_theme.dart still hardcodes $literals colour literals — every colour must come from AppColors.');
    });

    testWidgets('dark theme renders the rulebook §4.2 dark tokens',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const Scaffold()),
      );
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.colorScheme.primary, const Color(0xFF252B7A));
      // Audit 2026-11-15 AC-10: the scheme's secondary is orangeFill
      // now (white on #FF6D24 was 2.81:1).
      expect(theme.colorScheme.secondary, const Color(0xFFC2410C));
      expect(theme.colorScheme.primaryContainer, const Color(0xFF1A1D42));
      expect(theme.colorScheme.surface, const Color(0xFF13152C));
      expect(theme.colorScheme.onSurface, const Color(0xFFF8FAFC));
      expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF94A3B8));
      expect(theme.colorScheme.error, const Color(0xFFF87171));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0A0B1A));
      expect(theme.brightness, Brightness.dark);
    });

    test('dark input fill is the dark surface, not a light fill', () {
      final dark = AppTheme.darkTheme.inputDecorationTheme;
      expect(dark.fillColor, const Color(0xFF1E2138));
      final light = AppTheme.lightTheme.inputDecorationTheme;
      expect(light.fillColor, const Color(0xFFF8FAFC));
    });

    test('AppColors owns the dark token values (D9 resolved)', () {
      final content =
          File('lib/core/constants/app_colors.dart').readAsStringSync();
      for (final hex in [
        '0xFF23274D', // borderDark (§4.2 dark borderSubtle)
        '0xFF1C1F3D', // surfaceElevatedDark
        '0xFF34D399', // accentSuccessDark
        '0xFFF87171', // accentDangerDark
        '0xFF252B7A', // primaryOnDark
        '0xFF1A1D42', // primaryContainerOnDark
        '0xFF0B0D26', // primaryDarkOnDark
      ]) {
        expect(content, contains(hex), reason: 'missing dark token $hex');
      }
    });
  });

  group('Phase A5 — login and header identity', () {
    test('login ships with empty fields — no demo credentials', () {
      final login = File('lib/features/auth/presentation/views/login_view.dart')
          .readAsStringSync();
      expect(login, isNot(contains('ahmed.raza@rentalhub.pk')));
      expect(login, isNot(contains('password123')));
      expect(login, contains('TextEditingController()'));
    });

    test('login body is wrapped in SafeArea', () {
      final login = File('lib/features/auth/presentation/views/login_view.dart')
          .readAsStringSync();
      expect(login, contains('SafeArea('));
    });

    test('header has no fake default identity', () {
      final header =
          File('lib/core/widgets/custom_curved_header.dart').readAsStringSync();
      expect(header, isNot(contains("this.userName = 'Ahmed Raza'")));
      expect(header, contains("this.userName = ''"));
      expect(header, contains('this.isVerified = false'));
    });
  });
}
