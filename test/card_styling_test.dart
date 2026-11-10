import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/theme/card_decoration.dart';
import 'package:rentalhub/core/widgets/app_card.dart';
import 'package:rentalhub/core/widgets/boarding_pass_card.dart';
import 'package:rentalhub/features/customer/presentation/widgets/settings_section_card.dart';

/// Card rework (2026-11-10): cards in both modules lift off the screen
/// on a different background with a soft shadow — never a dark/grey
/// border. The old look drew `Border.all(color: dividerColor)` around
/// every card; in the M3 defaults that resolves to `colorScheme.outline`,
/// a mid-grey that read as a dark outline. These tests pin the new look
/// in BOTH themes: no dark BorderSide anywhere on cards, the card
/// background distinct from the screen background, and a real
/// elevation/shadow present.
///
/// The pumped widgets need no localizations (none of them calls
/// `AppLocalizations.of`), so no delegates are required here.
void main() {
  /// The theme-level contract: borderless, elevated, distinct surface.
  void checkCardTheme(ThemeData theme) {
    final cardTheme = theme.cardTheme;
    expect(cardTheme.elevation, greaterThanOrEqualTo(2),
        reason: 'cards must lift with elevation');
    final shape = cardTheme.shape as RoundedRectangleBorder?;
    expect(shape, isNotNull);
    expect(shape!.side, BorderSide.none,
        reason: 'CardTheme must not draw a border side');
    expect(cardTheme.color, isNot(theme.scaffoldBackgroundColor),
        reason: 'card background must differ from the screen background');
    expect(cardTheme.color, theme.colorScheme.surface);
    expect(theme.colorScheme.onSurface, isNot(theme.cardTheme.color),
        reason: 'theme text must stay readable on the card fill');
  }

  group('CardTheme', () {
    test('light: borderless, elevated, distinct card surface', () {
      checkCardTheme(AppTheme.lightTheme);
    });

    test('dark: borderless, elevated, distinct card surface', () {
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

  void checkCardDecoration(BoxDecoration decoration, ThemeData theme) {
    expect(decoration.border, isNull,
        reason: 'card decoration must have no border');
    expect(decoration.color, theme.colorScheme.surface);
    expect(decoration.color, isNot(theme.scaffoldBackgroundColor),
        reason: 'card background must differ from the screen background');
    expect(decoration.boxShadow, isNotNull);
    expect(decoration.boxShadow, isNotEmpty,
        reason: 'card must lift with a shadow');
  }

  group('AppCardDecoration.of', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('no dark border, distinct bg, shadow ($mode)',
          (tester) async {
        await pumpThemed(tester, const _CardProbe(), mode);
        final theme = Theme.of(tester.element(find.byType(_CardProbe)));
        checkCardDecoration(cardDecorationOf(tester, 20), theme);
      });
    }
  });

  group('representative cards', () {
    testWidgets('AppCard: theme-driven, borderless, elevated',
        (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpThemed(
          tester,
          const AppCard(child: Text('card')),
          mode,
        );
        final card = tester.widget<Card>(find.byType(Card));
        // Null elevation lets the CardTheme apply (elevation 3,
        // borderless rounded shape) — the shared component must not
        // reintroduce its own border.
        expect(card.elevation, isNull);
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.side, BorderSide.none);
      }
    });

    testWidgets('BoardingPassCard (customer): no border, has shadow',
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
        // The outer card is the 20-radius decoration; the tear-line
        // notches are borderless bg-coloured circles, not borders.
        checkCardDecoration(cardDecorationOf(tester, 20), theme);
      }
    });

    testWidgets('SettingsSectionCard (customer): no border, has shadow',
        (tester) async {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpThemed(
          tester,
          const SettingsSectionCard(title: 'Section', child: Text('body')),
          mode,
        );
        final theme =
            Theme.of(tester.element(find.byType(SettingsSectionCard)));
        // The card fill lives on the Material (surface, distinct from
        // the screen); the inner Container carries the shadow.
        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(SettingsSectionCard),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, theme.colorScheme.surface);
        expect(material.color, isNot(theme.scaffoldBackgroundColor),
            reason: 'card background must differ from the screen background');
        final decoration = cardDecorationOf(tester, 16);
        expect(decoration.border, isNull,
            reason: 'card decoration must have no border');
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, isNotEmpty,
            reason: 'card must lift with a shadow');
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
