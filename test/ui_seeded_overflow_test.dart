// Seeded overflow tests — the proof the audit asked for.
//
// test/multi_screen_overflow_test.dart only pumps EMPTY states (in-memory
// data sources), so data-driven overflow was invisible: the dashboard KPI
// cards, the ledger rows, the wallet balance and the triage/ticket rows
// only overflow with real data (7-digit amounts, long names, 2–3 digit
// counts). These tests seed realistic data and run the multi-viewport
// harness (320px @ 1.25x, 360px @ 1.35x, 412px @ 1.5x) — the harness the
// skipped rulebook test D11 demands be actually used.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_support_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/booking_ticket_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_kpis.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_ledger_item.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/revenue_kpi_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

BookingEntity _seededBooking({String status = 'payment_submitted'}) =>
    BookingEntity(
      bookingId: 'RH-1762574400123-0042',
      customerId: 'cust-101',
      shopId: 'shop-1',
      vehicleId: 'v-1',
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 8, 10),
      returnTime: DateTime(2026, 11, 9, 10),
      totalAmount: 1250000,
      remainingBalance: 1250000,
      status: status,
      vehicleName: 'Toyota Corolla Grande 1.8',
      vehiclePlate: 'LEA-21-4820',
      shopName: 'Al-Madina Rent a Car',
      customerName: 'Muhammad Ahmed Khan Butt',
      customerPhone: '0300-1234567',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
    // AC-8: the wallet reads the signed-in user's records — stand
    // in as 'cust-101' via the SignedInUser test override.
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDown(() async {
    SignedInUser.override = null;
    await sl.reset();
  });

  group('Seeded overflow: the fixed widgets at 3 viewports', () {
    testWidgets('RevenueKpiCard with a 7-digit amount', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const RevenueKpiCard(
          title: 'Completed Trips',
          amount: 'Rs. 1,234,567',
          changeLabel: '87% deposits settled',
          icon: Icons.task_alt_rounded,
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Rs. 1,234,567'), findsWidgets);
    });

    testWidgets('DashboardKpis with 7-digit revenue and 2–3 digit counts',
        (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const DashboardKpis(
          totalRevenue: 1234567,
          growthLabel: '+12% vs last month',
          activeCount: 87,
          completedCount: 1234,
          settleLabel: '87% deposits settled',
          waitingCount: 42,
          fleetAvailable: 18,
          fleetTotal: 24,
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Rs. 1,234,567'), findsWidgets);
      expect(find.text('42'), findsWidgets);
    });

    testWidgets('DashboardLedgerItem with a long id, name and 6-digit amount',
        (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const DashboardLedgerItem(
          bookingId: 'RH-1762574400123-0042',
          vehicleName: 'Toyota Corolla Grande 1.8',
          customerName: 'Muhammad Ahmed Khan Butt',
          amount: 125000,
          status: 'active',
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Rs. 125,000'), findsWidgets);
      expect(find.text('Toyota Corolla Grande 1.8'), findsWidgets);
    });

    testWidgets('RequestTriageCard with a long vehicle name and 7-digit total',
        (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: RequestTriageCard(
          booking: _seededBooking(),
          onApprove: () {},
          onReject: () {},
          onVerifyProof: () {},
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Toyota Corolla Grande 1.8'), findsWidgets);
      expect(find.text('Rs. 1,250,000'), findsWidgets);
    });

    testWidgets('BookingTicketCard with a 7-digit total', (tester) async {
      // The card lives in a bookings ListView in the app, so pump it in a
      // scrollable like the real usage — its own height is not bounded by
      // the screen.
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: SingleChildScrollView(
          child: BookingTicketCard(
            booking: _seededBooking(status: 'active'),
            onTap: () {},
          ),
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Total: Rs. 1,250,000'), findsWidgets);
    });
  });

  group('Seeded overflow: the wallet balance with real money', () {
    testWidgets('6-digit wallet total fits at every viewport',
        (tester) async {
      // Seed the in-memory data sources the wallet service reads: a paid
      // booking (Rs. 450,000 advance) plus a collected deposit
      // (Rs. 150,000 escrow) for the test uid the service falls back to.
      final bookings = sl<BookingRemoteDataSource>();
      final created = await bookings.createBookingRequest(
        customerId: 'cust-101',
        shopId: 'shop-1',
        vehicleId: 'v-1',
        packageType: '24h',
        isWithDriver: true,
        pickupTime: DateTime(2026, 11, 8, 10),
        returnTime: DateTime(2026, 11, 9, 10),
        totalAmount: 600000,
        advanceRequired: 450000,
        vehicleName: 'Toyota Corolla Grande 1.8',
        customerName: 'Muhammad Ahmed Khan Butt',
      );
      await bookings.verifyPayment(
        bookingId: created.bookingId,
        advanceAmount: 450000,
      );
      await sl<SecurityDepositDataSource>().collect(
        bookingId: created.bookingId,
        customerId: 'cust-101',
        shopId: 'shop-1',
        amount: 150000,
      );

      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerWalletView(),
        theme: AppTheme.lightTheme,
      );
      // E1: the balance is masked by default — reveal it so the long
      // real-money value is visible for the overflow check.
      await tester.tap(find.byTooltip('Show balance'));
      await tester.pump();
      expect(find.text('Rs. 600,000'), findsOneWidget);
    });
  });

  group('Multi-viewport: all 10 tab screens (empty state)', () {
    const l10nDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    testWidgets('Customer Home', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerHomeView(),
        theme: AppTheme.lightTheme,
      );
      // Home redesign (2026-11-24): the greeting is the header now,
      // no "Home" title above it.
      expect(find.text('Assalam-o-Alaikum, Ahmed'), findsOneWidget);
    });

    testWidgets('Customer Bookings', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerBookingsView(),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('My Reservations'), findsOneWidget);
    });

    testWidgets('Customer Wallet (empty)', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerWalletView(),
        theme: AppTheme.lightTheme,
      );
      // E1: the balance is masked by default — reveal it through the
      // one eye toggle so the 'Rs. 0' value is visible. CU-m6: the
      // escrow pills carry no eye of their own any more and stay
      // masked ('Rs. •'), so only the balance reads 'Rs. 0'.
      await tester.tap(find.byTooltip('Show balance'));
      await tester.pump();
      expect(find.text('Rs. 0'), findsOneWidget); // balance only
    });

    testWidgets('Customer Support', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerSupportView(),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Help & Support Center'), findsOneWidget);
    });

    testWidgets('Customer Profile', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerProfileView(),
        theme: AppTheme.lightTheme,
      );
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Owner Dashboard (empty)', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerDashboardView(shopId: 'shop-1'),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Showroom Revenue & Operations'), findsOneWidget);
    });

    testWidgets('Owner Fleet (empty)', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerFleetView(),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Fleet Management'), findsOneWidget);
    });

    testWidgets('Owner Requests (empty)', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerBookingRequestsView(shopId: 'shop-1'),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Bookings Management'), findsOneWidget);
    });

    testWidgets('Owner Customers (empty)', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        tester: tester,
        screen: const OwnerCustomersListView(),
        theme: AppTheme.lightTheme,
        localizationsDelegates: l10nDelegates,
      );
      expect(find.text('Customers Management'), findsOneWidget);
    });

    testWidgets('Owner Settings (empty)', (tester) async {
      await TestHarness.pumpScreenMultiViewport(
        tester: tester,
        screen: const OwnerSettingsView(),
        theme: AppTheme.lightTheme,
        localizationsDelegates: l10nDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
