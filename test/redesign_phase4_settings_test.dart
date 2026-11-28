// Showroom redesign Phase 4 (2026-11-16): owner settings rebuild —
// the "Showroom Owner" card with a shortcut pill to the shop
// editor, language + theme as side-by-side cards, and the other 15
// rows grouped into Operations and Account & Alerts. All 17 rows
// keep their targets; theme keeps its System option; the five
// notification toggles stay in the Notifications bottom sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: OwnerSettingsView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder circleBadges(WidgetTester tester) {
    return find.byWidgetPredicate((w) {
      if (w is! Container || w.decoration is! BoxDecoration) return false;
      if ((w.decoration as BoxDecoration).shape != BoxShape.circle) {
        return false;
      }
      // The 36x36 row badges only — the profile avatar fallback is
      // a 52x52 circle and must not be counted.
      return w.constraints?.maxWidth == 36.0;
    });
  }

  group('Redesign Phase 4 — owner settings', () {
    testWidgets('all 16 items present, grouped under two headings',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('Showroom Owner'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('Account & Alerts'), findsOneWidget);
      // Language + theme are cards, not rows; the other 14 are rows.
      for (final label in [
        'Language',
        'Theme',
        'Shop Settings',
        'Fixed Routes',
        'Finance',
        'Finance Settings',
        'Booking Settings',
        'Income & Expense Categories',
        'Blacklist Reports',
        'Staff & Roles',
        'Disputes',
        'Notifications',
        'Sync details',
        'Subscription',
        'WhatsApp Packages',
        'Reset Options',
      ]) {
        expect(find.text(label), findsWidgets, reason: '$label missing');
      }
      // 'Shop Settings' renders twice by design: the app-bar title
      // and the Operations row. The pill reads 'Set Up Shop'.
      expect(find.text('Shop Settings'), findsNWidgets(2));
      // 'Booking Settings' sits under Operations, not Account &
      // Alerts: in tree order it follows the Operations heading and
      // precedes the Account & Alerts heading.
      expect(find.text('Booking Settings'), findsOneWidget);
      final texts = tester
          .widgetList(find.byType(Text))
          .map((w) => (w as Text).data)
          .toList();
      final ops = texts.indexOf('Operations');
      final booking = texts.indexOf('Booking Settings');
      final account = texts.indexOf('Account & Alerts');
      expect(ops, isNot(-1));
      expect(booking, greaterThan(ops));
      expect(account, greaterThan(booking));
      expect(find.text('Sign Out'), findsOneWidget);
      // Every link row carries a 36x36 pastel circular icon badge.
      expect(circleBadges(tester), findsNWidgets(14));
    });

    testWidgets('theme options include System and it persists',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getString('app_theme_mode'), 'system');
      expect(sl<AppSettingsCubit>().state.themeMode, ThemeMode.system);
      // Restore Light so later tests see a clean preference.
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getString('app_theme_mode'), 'light');
    });

    testWidgets('Set Up Shop pill navigates to the shop editor',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
              path: '/settings',
              builder: (_, __) => const OwnerSettingsView()),
          GoRoute(
              path: RouteNames.ownerShopSettings,
              builder: (_, __) =>
                  const Scaffold(body: Text('shop-page'))),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      // The pill reads the dedicated `settingsSetUpShop` key
      // ("Set Up Shop", Phase 5); the target is /owner/settings/shop.
      expect(find.text('Set Up Shop'), findsOneWidget);
      await tester.tap(find.text('Set Up Shop'));
      await tester.pumpAndSettle();
      expect(find.text('shop-page'), findsOneWidget);
    });
  });
}
