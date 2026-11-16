import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_booking_stats.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_greeting_header.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_kpis.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_quick_actions.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/revenue_kpi_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _booking({
  required String id,
  required DateTime pickup,
  required int amount,
  String status = 'completed',
}) {
  return BookingEntity(
    bookingId: id,
    customerId: 'cust-1',
    shopId: 'shop-1',
    vehicleId: 'veh-1',
    packageType: '24h',
    pickupTime: pickup,
    returnTime: pickup.add(const Duration(days: 1)),
    totalAmount: amount,
    remainingBalance: 0,
    vehicleName: 'Honda Civic',
    customerName: 'Ayesha Khan',
    status: status,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('Phase 1 — monthly revenue is the real month figure', () {
    test('monthRevenue sums this month only, not the all-time total', () {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 10, 10);
      final lastMonth = DateTime(now.year, now.month - 1, 10, 10);
      final bookings = [
        _booking(id: 'RH-1', pickup: thisMonth, amount: 2700),
        _booking(id: 'RH-2', pickup: thisMonth, amount: 9000, status: 'paid'),
        // Last month's completed trip must not count towards this month.
        _booking(id: 'RH-3', pickup: lastMonth, amount: 50000),
        // Awaiting requests are not revenue at all.
        _booking(id: 'RH-4', pickup: thisMonth, amount: 7000, status: 'requested'),
      ];
      expect(monthRevenue(bookings), 11700);
      // The all-time total is much larger — the old label showed this
      // number under a monthly name. (The requested booking is not
      // revenue at all, so it counts towards neither figure.)
      expect(totalRevenue(bookings), 61700);
      expect(monthRevenue(bookings), isNot(totalRevenue(bookings)));
    });

    test('monthRevenue is zero with no revenue bookings this month', () {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 10, 10);
      expect(monthRevenue([_booking(id: 'RH-9', pickup: lastMonth, amount: 50000)]), 0);
      expect(monthRevenue([]), 0);
    });
  });

  group('Phase 1 — unified dual-metric revenue card', () {
    testWidgets('shows Today and Monthly side by side with the growth label',
        (tester) async {
      await tester.pumpWidget(_wrap(const DualMetricRevenueCard(
        todayAmount: 'Rs. 0',
        monthAmount: 'Rs. 2,700',
        growthLabel: 'No revenue last month',
      )));
      await tester.pumpAndSettle();
      expect(find.text("Today's Earnings"), findsOneWidget);
      expect(find.text('Monthly Revenue'), findsOneWidget);
      expect(find.text('Rs. 0'), findsOneWidget);
      expect(find.text('Rs. 2,700'), findsOneWidget);
      expect(find.text('No revenue last month'), findsOneWidget);
      expect(find.text('Gross Revenue (This Month)'), findsNothing);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('DashboardKpis labels the month figure Monthly Revenue',
        (tester) async {
      await tester.pumpWidget(_wrap(const DashboardKpis(
        totalRevenue: 2700,
        todayEarnings: 0,
        growthLabel: 'No revenue last month',
        activeCount: 1,
        completedCount: 2,
        settleLabel: 'No completed trips yet',
        waitingCount: 0,
        fleetAvailable: 3,
        fleetTotal: 4,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Revenue'), findsOneWidget);
      expect(find.text('Rs. 2,700'), findsOneWidget);
      expect(find.text('Gross Revenue (This Month)'), findsNothing);
      expect(find.text('Rs. 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 1 — Active Rentals Today card', () {
    testWidgets('shows the live active count under the new label',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const ActiveRentalsTodayCard(activeCount: 3)));
      await tester.pumpAndSettle();
      expect(find.text('Active Rentals Today'), findsOneWidget);
      expect(find.text('3 Cars'), findsOneWidget);
      expect(find.text('On the road'), findsOneWidget);
      expect(find.text('Active on Rent'), findsNothing);
    });
  });

  group('Phase 1 — greeting with a short locale-aware date', () {
    testWidgets('single line: real owner name plus Mon, 16 Nov style date',
        (tester) async {
      await tester.pumpWidget(_wrap(const DashboardGreetingHeader(
        ownerName: 'Ahmed Raza',
        shopName: 'Meezan Rent a Car',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Assalam-o-Alaikum, Ahmed Raza'), findsOneWidget);
      expect(
        find.text(DateFormat('EEE, d MMM', 'en').format(DateTime.now())),
        findsOneWidget,
      );
      // The old long form ("Monday, 16 November 2026") is gone.
      expect(
        find.text(DateFormat('EEEE, d MMMM y', 'en').format(DateTime.now())),
        findsNothing,
      );
    });

    testWidgets('falls back to the shop name when no owner name is saved',
        (tester) async {
      await tester.pumpWidget(_wrap(const DashboardGreetingHeader(
        ownerName: '',
        shopName: 'Meezan Rent a Car',
      )));
      await tester.pumpAndSettle();
      expect(
        find.text('Assalam-o-Alaikum, Meezan Rent a Car'),
        findsOneWidget,
      );
    });
  });

  group('Phase 1 — 4+3 quick actions with a live Requests badge', () {
    testWidgets('shows all seven actions; badge only while work waits',
        (tester) async {
      await tester.pumpWidget(_wrap(const DashboardQuickActions(waitingCount: 3)));
      await tester.pumpAndSettle();
      for (final label in [
        'Add Car',
        'Scan QR',
        'New Booking',
        'Add Customer',
        'Finance',
        'View Reports',
        'Requests',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byKey(const Key('requests-waiting-badge')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // Badge labels are weight 500, never bold.
      expect(tester.widget<Text>(find.text('3')).style?.fontWeight,
          FontWeight.w500);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no badge when nothing is waiting', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardQuickActions(waitingCount: 0)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('requests-waiting-badge')), findsNothing);
      expect(find.text('Requests'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Requests opens the triage tab', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: DashboardQuickActions(waitingCount: 2),
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
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('requests-waiting-badge')), findsOneWidget);
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Add Car'), findsNothing);
    });
  });
}
