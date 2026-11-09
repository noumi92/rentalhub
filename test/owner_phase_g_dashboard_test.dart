
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/notifications/data/datasources/notification_data_source.dart';
import 'package:rentalhub/features/notifications/data/models/notification_model.dart';
import 'package:rentalhub/features/notifications/domain/entities/notification_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_kpis.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_ledger_item.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_ledger_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_quick_actions.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/revenue_kpi_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase G (G2) — notifications data layer', () {
    test('create, list newest-first, mark read, mark all read', () async {
      final ds = NotificationDataSource();
      await ds.createNotification(
        shopId: 'shop-g2',
        title: 'New booking request',
        body: 'Ayesha requested a Civic',
        type: 'booking_request',
        bookingId: 'RH-G2-1',
      );
      await ds.createNotification(
        shopId: 'shop-g2',
        title: 'Payment proof submitted',
        body: 'Proof for RH-G2-1',
        type: 'payment_proof',
        bookingId: 'RH-G2-1',
      );
      final list = await ds.getShopNotifications('shop-g2');
      expect(list.length, 2);
      expect(list.first.type, 'payment_proof');
      expect(list.where((n) => !n.read).length, 2);

      await ds.markRead(list.first.notificationId);
      final afterOne = await ds.getShopNotifications('shop-g2');
      expect(afterOne.where((n) => !n.read).length, 1);

      await ds.markAllRead('shop-g2');
      final afterAll = await ds.getShopNotifications('shop-g2');
      expect(afterAll.where((n) => !n.read).length, 0);
    });

    test('model round-trips through toMap/fromMap', () {
      final entity = NotificationEntity(
        notificationId: 'NTF-1',
        shopId: 'shop-g2',
        title: 'Hello',
        body: 'World',
        type: 'general',
        createdAt: DateTime(2026, 11, 6),
      );
      final map = NotificationModel.fromEntity(entity).toMap();
      final back = NotificationModel.fromMap(map);
      expect(back.title, 'Hello');
      expect(back.read, isFalse);
    });
  });

  group('Phase G (G2) — booking events notify the shop', () {
    test('online request notifies, walk-in does not, proof notifies',
        () async {
      final notifications = NotificationDataSource();
      final ds = BookingRemoteDataSource(notifications: notifications);
      final online = await ds.createBookingRequest(
        customerId: 'cust-g2',
        shopId: 'shop-g2',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic',
        customerName: 'Ayesha Khan',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      var list = await notifications.getShopNotifications('shop-g2');
      expect(list.length, 1);
      expect(list.first.type, 'booking_request');
      expect(list.first.bookingId, online.bookingId);

      await ds.createBookingRequest(
        customerId: 'walkin-123',
        shopId: 'shop-g2',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      list = await notifications.getShopNotifications('shop-g2');
      expect(list.length, 1);

      await ds.updatePaymentProof(
        bookingId: online.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-G2',
      );
      list = await notifications.getShopNotifications('shop-g2');
      expect(list.length, 2);
      expect(list.first.type, 'payment_proof');
    });
  });

  group('Phase G (G3) — language and theme settings', () {
    test('cubit persists locale and theme, reloads them', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppSettingsCubit.localeKey);
      await prefs.remove(AppSettingsCubit.themeKey);
      final cubit = AppSettingsCubit(prefs: prefs);
      expect(cubit.state.localeCode, 'en');
      expect(cubit.state.themeMode, ThemeMode.light);

      await cubit.setLocale('ur');
      expect(cubit.state.localeCode, 'ur');
      expect(prefs.getString(AppSettingsCubit.localeKey), 'ur');

      await cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(prefs.getString(AppSettingsCubit.themeKey), 'dark');

      final reloaded = AppSettingsCubit(prefs: prefs);
      expect(reloaded.state.localeCode, 'ur');
      expect(reloaded.state.themeMode, ThemeMode.dark);

      await cubit.setLocale('en');
      await cubit.setThemeMode(ThemeMode.system);
    });

    testWidgets('settings screen translates to Urdu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ur'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: OwnerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();
      // The string renders twice by design: the MinimalAppBar title
      // (l10n.settings) and the quick link (l10n.fleetShopSettings).
      expect(find.text('دکان کی ترتیبات'), findsNWidgets(2));
      expect(find.text('زبان'), findsOneWidget);
      expect(find.text('تھیم'), findsOneWidget);
    });

    testWidgets('tapping a language chip persists the choice',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await di.sl<AppSettingsCubit>().setLocale('en');
      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: OwnerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();
      // The string renders twice by design: the MinimalAppBar title
      // (l10n.settings) and the quick link (l10n.fleetShopSettings).
      expect(find.text('Shop Settings'), findsNWidgets(2));

      // In the English locale the chip is labelled 'Urdu' (the .arb
      // English value); tapping it persists 'ur' in the cubit.
      await tester.ensureVisible(find.text('Urdu'));
      await tester.tap(find.text('Urdu'));
      await tester.pumpAndSettle();
      expect(di.sl<AppSettingsCubit>().state.localeCode, 'ur');
      expect(prefs.getString(AppSettingsCubit.localeKey), 'ur');

      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(di.sl<AppSettingsCubit>().state.localeCode, 'en');
    });
  });

  group('Phase G (G1) — dashboard shows real numbers', () {
    testWidgets('revenue and ledger come from the bookings', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-g1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic Oriel 2021',
        customerName: 'Dashboard Customer',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.updateBookingStatus(
          bookingId: booking.bookingId, status: 'paid');

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerDashboardView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      // The amount appears three times: the revenue KPI, the Today's
      // Earnings KPI (the seeded booking's pickup is today), and the
      // ledger row. C5: grouped thousands — "Rs. 9,000", never
      // "Rs. 9000".
      expect(find.text('Rs. 9,000'), findsNWidgets(3));
      expect(find.text('Rs. 9000'), findsNothing);
      expect(find.text('Rs. 148,500'), findsNothing);
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.text('No trips yet — bookings will appear here.'),
          findsNothing);
      expect(find.text('Al-Falah Rent a Car • Executive Telemetry'),
          findsNothing);
    });
  });

  group('Audit fix — dashboard KPI trend, ledger link, quick actions', () {
    testWidgets('down trend shows a down arrow, never an up arrow in green',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RevenueKpiCard(
              title: 'Gross revenue',
              amount: 'Rs. 8,800',
              changeLabel: '-12% vs last month',
              icon: Icons.account_balance_wallet_rounded,
              trend: KpiTrend.down,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsNothing);
    });

    testWidgets('up trend shows the up arrow; neutral shows no trend icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                RevenueKpiCard(
                  title: 'Gross revenue',
                  amount: 'Rs. 10,000',
                  changeLabel: '+12% vs last month',
                  icon: Icons.account_balance_wallet_rounded,
                  trend: KpiTrend.up,
                ),
                RevenueKpiCard(
                  title: 'Requests waiting',
                  amount: '3',
                  changeLabel: 'Needs review',
                  icon: Icons.inbox_rounded,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsNothing);
    });

    testWidgets('DashboardKpis formats a 7-digit revenue with separators',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DashboardKpis(
              totalRevenue: 1234567,
              growthLabel: '+12% vs last month',
              growthTrend: KpiTrend.up,
              activeCount: 87,
              completedCount: 1234,
              settleLabel: '87% deposits settled',
              waitingCount: 42,
              fleetAvailable: 18,
              fleetTotal: 24,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rs. 1,234,567'), findsOneWidget);
      expect(find.text('Rs. 1234567'), findsNothing);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('ledger status colours are brightness-aware, not plain orange',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Column(
              children: [
                DashboardLedgerItem(
                  bookingId: 'RH-1',
                  vehicleName: 'Honda Civic',
                  customerName: 'Ayesha Khan',
                  amount: 125000,
                  status: 'requested',
                ),
                DashboardLedgerItem(
                  bookingId: 'RH-2',
                  vehicleName: 'Honda Civic',
                  customerName: 'Ayesha Khan',
                  amount: 125000,
                  status: 'rejected',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rs. 125,000'), findsNWidgets(2));
      final requested = tester.widget<Text>(find.text('Requested'));
      expect(requested.style?.color,
          AppColors.orangeTextFor(Brightness.light));
      final rejected = tester.widget<Text>(find.text('Rejected'));
      expect(rejected.style?.color,
          AppColors.dangerTextFor(Brightness.light));
    });

    testWidgets('"View all requests" opens the Requests tab',
        (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        remainingBalance: 6000,
        vehicleName: 'Honda Civic',
        customerName: 'Ayesha Khan',
        status: 'paid',
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: DashboardLedgerSection(
                isEmpty: false,
                ledger: [booking],
              ),
            ),
          ),
          GoRoute(
            path: '/owner/requests',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Requests')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View all requests'), findsOneWidget);
      await tester.tap(find.text('View all requests'));
      await tester.pumpAndSettle();
      expect(find.text('Requests'), findsOneWidget);
      router.dispose();
    });

    testWidgets('Scan QR tile icon uses the theme primary in dark mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DashboardQuickActions()),
        ),
      );
      await tester.pumpAndSettle();
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.qr_code_scanner_rounded),
      );
      // Theme primary in dark is lavender — not the navy
      // AppColors.primary (#1B1E5C), which was ~1.2:1 on dark.
      expect(icon.color, AppTheme.darkTheme.colorScheme.primary);
      expect(icon.color, isNot(AppColors.primary));
    });
  });

  group('Phase G — routing', () {
    test('notifications and settings routes are wired', () {
      final router =
          File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(router, contains('OwnerNotificationsView'));
      expect(router, contains('OwnerSettingsView'));
      expect(router, contains("RouteNames.ownerNotifications"));
      expect(router, contains("RouteNames.ownerSettings"));
      final names =
          File('lib/core/routing/route_names.dart').readAsStringSync();
      expect(names, contains("ownerNotifications = '/owner/notifications'"));
      expect(names, contains("ownerSettings = '/owner/settings'"));
    });
  });
}
