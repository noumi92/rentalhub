import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/theme/card_decoration.dart';
import 'package:rentalhub/core/widgets/app_card.dart';
import 'package:rentalhub/core/widgets/boarding_pass_card.dart';
import 'package:rentalhub/features/customer/presentation/widgets/settings_section_card.dart';

/// Card rework (2026-11-10), showroom redesign Phase 0 (2026-11-16):
/// the canonical card look is now elevation 1.5, radius 16, and a 1 px
/// hairline border in `borderSubtle` (`#E2E8F0` light / `#23274D` dark)
/// — the 2026-11-10 borderless look is superseded deliberately (the old
/// 1 px `dividerColor` side read as a dark outline because it resolved
/// to M3 `outline`, a mid-grey; the hairline uses the subtle token).
/// These tests pin the canonical look (`CardThemeData` +
/// `AppCardDecoration.of`) in BOTH themes: 1 px hairline, card
/// background distinct from the screen background, and a real
/// elevation/shadow present.
///
/// Showroom redesign Phase 5 (2026-11-16) migrated the last local
/// decorations to the canonical look: `BoardingPassCard` (was a local
/// radius-20 borderless decoration) and `SettingsSectionCard` (was a
/// local shadow-only decoration) now use `AppCardDecoration.of`, and
/// `AppCard`'s explicit shape now carries the 1 px hairline side (an
/// explicit shape otherwise overrides the theme's `CardThemeData`
/// side). All three tests below pin the guide look.
///
/// The pumped widgets need no localizations (none of them calls
/// `AppLocalizations.of`), so no delegates are required here.
void main() {
  /// The theme-level contract: 1 px hairline, elevation 1.5, radius 16,
  /// distinct surface.
  void checkCardTheme(ThemeData theme) {
    final cardTheme = theme.cardTheme;
    expect(cardTheme.elevation, 1.5,
        reason: 'cards lift with elevation 1.5 (showroom guide)');
    final shape = cardTheme.shape as RoundedRectangleBorder?;
    expect(shape, isNotNull);
    final borderColor = theme.brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderSubtle;
    expect(shape!.side, BorderSide(color: borderColor, width: 1),
        reason: 'CardTheme draws the 1px borderSubtle hairline');
    expect(cardTheme.color, isNot(theme.scaffoldBackgroundColor),
        reason: 'card background must differ from the screen background');
    expect(cardTheme.color, theme.colorScheme.surface);
    expect(theme.colorScheme.onSurface, isNot(theme.cardTheme.color),
        reason: 'theme text must stay readable on the card fill');
  }

  group('CardTheme', () {
    test('light: 1px hairline, elevation 1.5, distinct card surface', () {
      checkCardTheme(AppTheme.lightTheme);
    });

    test('dark: 1px hairline, elevation 1.5, distinct card surface', () {
      checkCardTheme(AppTheme.darkTheme);
    });
  });

  Future<void> pumpThemed(
    WidgetTester tester,
    Widget child,
    ThemeMode mode,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  /// A Container decoration is a card decoration when it is rounded
  /// and carries a shadow; [radius] pins which card is meant.
  BoxDecoration cardDecorationOf(WidgetTester tester, double radius) {
    final container = tester.widget<Container>(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(radius),
      ),
    );
    return container.decoration as BoxDecoration;
  }

  void checkGuideCardDecoration(BoxDecoration decoration, ThemeData theme) {
    final border = decoration.border as Border?;
    expect(border, isNotNull,
        reason: 'canonical card decoration draws the 1px hairline');
    final borderColor = theme.brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderSubtle;
    expect(border!.top, BorderSide(color: borderColor, width: 1));
    expect(decoration.color, theme.colorScheme.surface);
    expect(decoration.color, isNot(theme.scaffoldBackgroundColor),
        reason: 'card background must differ from the screen background');
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty,
        reason: 'card must lift with a shadow');
  }

  group('AppCardDecoration.of', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('1px hairline, distinct bg, shadow ($mode)',
          (tester) async {
        await pumpThemed(tester, const _CardProbe(), mode);
        final theme = Theme.of(tester.element(find.byType(_CardProbe)));
        checkGuideCardDecoration(cardDecorationOf(tester, 16), theme);
      });
    }
  });

  group('representative cards', () {
    testWidgets('AppCard: theme elevation, explicit rounded shape',
        (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpThemed(
          tester,
          const AppCard(child: Text('card')),
          mode,
        );
        final card = tester.widget<Card>(find.byType(Card));
        // Null elevation lets the CardTheme apply (elevation 1.5).
        // Phase 5: AppCard's explicit shape now carries the guide
        // 1px hairline side (an explicit shape otherwise overrides
        // the theme's CardThemeData side), so the side is the
        // border token, not none.
        expect(card.elevation, isNull);
        final theme = Theme.of(tester.element(find.byType(AppCard)));
        final borderColor = theme.brightness == Brightness.dark
            ? AppColors.borderDark
            : AppColors.borderSubtle;
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side, BorderSide(color: borderColor, width: 1));
      }
    });

    testWidgets('BoardingPassCard (customer): canonical decoration',
        (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpThemed(
          tester,
          const BoardingPassCard(
            topSection: Text('top'),
            bottomSection: Text('bottom'),
          ),
          mode,
        );
        final theme = Theme.of(tester.element(find.byType(BoardingPassCard)));
        // Phase 5: the outer card is the canonical
        // AppCardDecoration.of (radius 16, 1px hairline) — the old
        // local radius-20 borderless decoration is gone. The
        // tear-line notches are borderless bg-coloured circles, not
        // borders.
        checkGuideCardDecoration(cardDecorationOf(tester, 16), theme);
      }
    });

    testWidgets('SettingsSectionCard (customer): canonical decoration',
        (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpThemed(
          tester,
          const SettingsSectionCard(title: 'Section', child: Text('body')),
          mode,
        );
        final theme =
            Theme.of(tester.element(find.byType(SettingsSectionCard)));
        // The card IS a Material (surface, radius 16, 1px hairline
        // side, elevation 1.5): the rows inside are ListTiles, and a
        // ListTile paints its ink on the nearest Material ancestor.
        // A Container with a coloured decoration under an outer
        // Material hides the ink and Flutter throws, so the shape
        // lives on the Material itself (fix-up 2026-11-16, after the
        // Phase 5 decoration migration tripped the assertion in
        // CustomerSettingsView).
        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(SettingsSectionCard),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, theme.colorScheme.surface);
        expect(material.color, isNot(theme.scaffoldBackgroundColor),
            reason: 'card background must differ from the screen background');
        expect(material.elevation, 1.5);
        final borderColor = theme.brightness == Brightness.dark
            ? AppColors.borderDark
            : AppColors.borderSubtle;
        final shape = material.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
        expect(shape.side, BorderSide(color: borderColor, width: 1));
      }
    });

    testWidgets('shadow alpha is 0.08 in light mode', (tester) async {
      late Color shadow;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: _ShadowProbe(onShadow: (color) => shadow = color),
          ),
        ),
      );
      expect(shadow.a, moreOrLessEquals(0.08));
    });

    testWidgets('shadow alpha is 0.45 in dark mode', (tester) async {
      late Color shadow;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: _ShadowProbe(onShadow: (color) => shadow = color),
          ),
        ),
      );
      expect(shadow.a, moreOrLessEquals(0.45),
          reason: 'dark shadow needs a stronger alpha on near-black');
    });
  });
}

/// Probe that builds a Container with the canonical card decoration,
/// so the test can read the decoration back from the widget tree.
class _CardProbe extends StatelessWidget {
  const _CardProbe();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardDecoration.of(context),
      child: const Text('probe'),
    );
  }
}

/// Probe that reports the shadow colour for the ambient theme.
class _ShadowProbe extends StatelessWidget {
  const _ShadowProbe({required this.onShadow});

  final void Function(Color color) onShadow;

  @override
  Widget build(BuildContext context) {
    onShadow(AppCardDecoration.shadow(context).first.color);
    return const SizedBox();
  }
}
