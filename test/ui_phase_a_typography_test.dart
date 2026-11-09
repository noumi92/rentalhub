// Phase A (A1/A3) — typography scale, fonts and the completed theme.
//
// The rulebook §4.5 scale is the only type scale in the app: views read
// `Theme.of(context).textTheme` slots and never invent a `fontSize:`.
// These tests pin the scale values, the font families (Inter / Noto
// Nastaliq Urdu) and the component themes A3 added.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';

void main() {
  group('Phase A1 — fonts', () {
    test('Inter and Noto Nastaliq Urdu are bundled and declared', () {
      expect(File('assets/fonts/Inter.ttf').existsSync(), isTrue);
      expect(File('assets/fonts/NotoNastaliqUrdu.ttf').existsSync(), isTrue);
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/fonts/Inter.ttf'));
      expect(pubspec, contains('assets/fonts/NotoNastaliqUrdu.ttf'));
      expect(pubspec, contains('family: Inter'));
      expect(pubspec, contains('family: Noto Nastaliq Urdu'));
    });

    test('default font family is Inter; Urdu locale switches the family',
        () {
      expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(AppTheme.fontFamilyFor(const Locale('en')), 'Inter');
      expect(AppTheme.fontFamilyFor(const Locale('ur')),
          'Noto Nastaliq Urdu');
      expect(
        AppTheme.lightThemeFor(fontFamily: AppTheme.fontFamilyUrdu)
            .textTheme
            .bodyMedium
            ?.fontFamily,
        'Noto Nastaliq Urdu',
      );
    });
  });

  group('Phase A1 — rulebook §4.5 text scale', () {
    late TextTheme light;
    late TextTheme dark;

    setUpAll(() {
      light = AppTheme.lightTheme.textTheme;
      dark = AppTheme.darkTheme.textTheme;
    });

    test('display / title slots match §4.5', () {
      expect(light.displayLarge?.fontSize, 28);
      expect(light.displayLarge?.fontWeight, FontWeight.w700);
      expect(light.displayLarge?.height, closeTo(34 / 28, 0.01));
      expect(light.titleLarge?.fontSize, 20);
      expect(light.titleLarge?.fontWeight, FontWeight.w600);
      expect(light.titleLarge?.height, closeTo(26 / 20, 0.01));
      expect(light.titleMedium?.fontSize, 16);
      expect(light.titleMedium?.fontWeight, FontWeight.w600);
      expect(light.titleMedium?.height, closeTo(22 / 16, 0.01));
    });

    test('body / label slots match §4.5', () {
      expect(light.bodyLarge?.fontSize, 15);
      expect(light.bodyLarge?.fontWeight, FontWeight.w400);
      expect(light.bodyLarge?.height, closeTo(22 / 15, 0.01));
      expect(light.bodyMedium?.fontSize, 13);
      expect(light.bodyMedium?.fontWeight, FontWeight.w400);
      expect(light.bodyMedium?.height, closeTo(18 / 13, 0.01));
      expect(light.labelSmall?.fontSize, 11);
      expect(light.labelSmall?.fontWeight, FontWeight.w500);
      expect(light.labelSmall?.height, closeTo(14 / 11, 0.01));
    });

    test('companion slots exist (titleSmall, bodySmall, labelLarge/Medium)',
        () {
      expect(light.titleSmall?.fontSize, 14);
      expect(light.titleSmall?.fontWeight, FontWeight.w600);
      expect(light.bodySmall?.fontSize, 12);
      expect(light.labelLarge?.fontSize, 14);
      expect(light.labelLarge?.fontWeight, FontWeight.w600);
      expect(light.labelMedium?.fontSize, 12);
      expect(light.labelMedium?.fontWeight, FontWeight.w500);
    });

    test('text colours follow the mode (light onSurface, dark onSurfaceDark)',
        () {
      expect(light.bodyLarge?.color, const Color(0xFF0F172A));
      expect(light.labelSmall?.color, const Color(0xFF64748B));
      expect(dark.bodyLarge?.color, const Color(0xFFF8FAFC));
      expect(dark.labelSmall?.color, const Color(0xFF94A3B8));
    });

    test('every text style carries the Inter family', () {
      final styles = [
        light.displayLarge,
        light.titleLarge,
        light.titleMedium,
        light.titleSmall,
        light.bodyLarge,
        light.bodyMedium,
        light.bodySmall,
        light.labelLarge,
        light.labelMedium,
        light.labelSmall,
      ];
      for (final style in styles) {
        expect(style?.fontFamily, 'Inter');
      }
    });

    test('mobile modules have no ad-hoc fontSize beyond the 40 known leftovers',
        () {
      // Phase A1 migration (2026-11-07): 657 sites moved to theme slots.
      // The 32 that remain are all deliberate — 29 inside private helpers
      // with no BuildContext in scope, 1 invisible splash text
      // (fontSize 0), and 2 sub-scale plate labels. The count must only
      // go down; if it grows, migrate the new sites or justify them here.
      // Phone-test fix batch (2026-11-08): +3 deliberate sites, all
      // spec sizes with no matching theme slot (rulebook §4.5 scale is
      // titleLarge 20 / titleMedium 16 / bodyMedium 13 / labelSmall 11):
      // MinimalAppBar title 18sp w900 white + subtitle 12sp white70
      // (rulebook §4.3 — white-on-navy header, no slot is 18/12) and
      // the AppIconChip badge count at 10sp (sub-scale, same class as
      // the plate labels). New total 35.
      // Audit-impl finish build (2026-11-09): +7 sites in
      // report_pdf_generator.dart — `pdf`-package print point sizes
      // in a generator with no BuildContext, the same class as
      // statement_pdf_generator.dart's 7 already inside the 35. The
      // 5 new UI sites from the same build (customer detail/added
      // views) were migrated to theme slots instead of counting here.
      // New total 40.
      const scopes = [
        'lib/features/auth',
        'lib/features/customer',
        'lib/features/owner',
        'lib/features/bookings',
        'lib/features/discovery',
        'lib/features/trust',
        'lib/features/finance',
        'lib/core/widgets',
      ];
      var count = 0;
      for (final dir in scopes) {
        for (final file in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          count += RegExp(r'fontSize:').allMatches(file.readAsStringSync()).length;
        }
      }
      expect(count, lessThanOrEqualTo(40),
          reason: 'Ad-hoc fontSize sites grew to $count (was 40).');
    });
  });

  group('Phase A2/A3 — inputs and component themes', () {
    test('inputs use radius 16 and a 2px primary focus border (§4.4)', () {
      final light = AppTheme.lightTheme.inputDecorationTheme;
      final border = light.border as OutlineInputBorder;
      expect(border.borderRadius, BorderRadius.circular(16));
      final focused = light.focusedBorder as OutlineInputBorder;
      expect(focused.borderSide.width, 2);
      expect(focused.borderSide.color, const Color(0xFF1B1E5C));
      final dark = AppTheme.darkTheme.inputDecorationTheme;
      final darkFocused = dark.focusedBorder as OutlineInputBorder;
      expect(darkFocused.borderSide.width, 2);
      // Dark fix (2026-11-08): the old #252B7A focused border was
      // invisible against the dark fill (#1E2138) and border (#23274D)
      // — three near-identical navies. The focused border is now the
      // lighter primaryFocusedOnDark token so focus is visible.
      expect(darkFocused.borderSide.color, AppColors.primaryFocusedOnDark);
    });

    test('all button families are themed', () {
      final theme = AppTheme.lightTheme;
      expect(theme.elevatedButtonTheme.style, isNotNull);
      expect(theme.filledButtonTheme.style, isNotNull);
      expect(theme.outlinedButtonTheme.style, isNotNull);
      expect(theme.textButtonTheme.style, isNotNull);
    });

    test('component themes are present in both modes', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.navigationBarTheme.backgroundColor, isNotNull);
        expect(theme.bottomSheetTheme.backgroundColor, isNotNull);
        expect(theme.dialogTheme.backgroundColor, isNotNull);
        expect(theme.snackBarTheme.backgroundColor, isNotNull);
        expect(theme.chipTheme.backgroundColor, isNotNull);
        expect(theme.dividerTheme.color, isNotNull);
        expect(theme.listTileTheme.iconColor, isNotNull);
        expect(theme.floatingActionButtonTheme.backgroundColor, isNotNull);
        expect(theme.progressIndicatorTheme.color, isNotNull);
        expect(theme.segmentedButtonTheme.style, isNotNull);
        expect(theme.cardTheme.color, isNotNull);
        expect(theme.appBarTheme.backgroundColor, isNotNull);
      }
    });
  });
}
