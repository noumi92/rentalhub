// UI/UX audit fix (Team J): owner settings consolidation —
// language, theme, notifications and sync are rows in one flat
// list (no section cards, no "Quick links" heading). Language and
// theme pick from a bottom sheet and persist via AppSettingsCubit;
// notifications opens a sheet with the five persisted toggles plus
// a link to the notifications list; sync opens sync details.
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

  group('Owner settings — consolidated flat list', () {
    testWidgets('four rows present; heading and section cards gone',
        (tester) async {
      await pumpSettings(tester);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Sync details'), findsOneWidget);
      // The current values ride on the language/theme rows.
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      // No heading, no language/theme chips, no sync card title.
      expect(find.text('Quick links'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Sync'), findsNothing);
      // The other links are untouched (app-bar title + shop link).
      expect(find.text('Shop Settings'), findsNWidgets(2));
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('language sheet changes the persisted setting',
        (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsNWidgets(2));
      expect(find.text('Urdu'), findsOneWidget);
      await tester.tap(find.text('Urdu'));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getString('app_locale'), 'ur');
      expect(sl<AppSettingsCubit>().state.localeCode, 'ur');
      expect(find.text('Urdu'), findsOneWidget);
      expect(find.text('English'), findsNothing);
      // Restore the default so later tests see a clean preference.
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getString('app_locale'), 'en');
    });

    testWidgets('theme sheet changes the persisted setting',
        (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsNWidgets(2));
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getString('app_theme_mode'), 'dark');
      expect(sl<AppSettingsCubit>().state.themeMode, ThemeMode.dark);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsNothing);
      // Restore the default so later tests see a clean preference.
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getString('app_theme_mode'), 'light');
    });

    testWidgets('notifications sheet shows the toggles; one persists',
        (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      for (final label in [
        'Booking requests',
        'Payment proofs',
        'Handover',
        'Returns',
        'Maintenance reminders',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(SwitchListTile), findsNWidgets(5));
      final tile = find.widgetWithText(SwitchListTile, 'Booking requests');
      await tester.tap(find.descendant(
          of: tile, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getBool('notif_booking_requests'),
          isFalse);
      final reloaded = AppSettingsCubit(prefs: sl<SharedPreferences>());
      expect(reloaded.state.notifyBookingRequests, isFalse);
      // Restore the default so later tests see a clean preference.
      await tester.tap(find.descendant(
          of: tile, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getBool('notif_booking_requests'),
          isTrue);
    });

    testWidgets('sync row opens sync details; sheet links to the list',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
              path: '/settings',
              builder: (_, __) => const OwnerSettingsView()),
          GoRoute(
              path: RouteNames.ownerNotifications,
              builder: (_, __) =>
                  const Scaffold(body: Text('notifications-page'))),
          GoRoute(
              path: RouteNames.syncDetails,
              builder: (_, __) => const Scaffold(body: Text('sync-page'))),
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
      await tester.tap(find.text('Sync details'));
      await tester.pumpAndSettle();
      expect(find.text('sync-page'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Sync details'), findsOneWidget);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Booking requests'), findsOneWidget);
      final sheetLink = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(ListTile, 'Notifications'));
      expect(sheetLink, findsOneWidget);
      await tester.tap(sheetLink);
      await tester.pumpAndSettle();
      expect(find.text('notifications-page'), findsOneWidget);
    });
  });
}
