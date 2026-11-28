// Owner-deck finish (worker A): customer detail (#35), O13 success
// screen, O11 list chips + badges. Widget tests only — the registrar
// adds the routes/keys first; the integration worker runs this file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_added_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Future<BookingRemoteDataSource> bookings() async =>
      di.sl<BookingRemoteDataSource>();
  Future<CustomerRemoteDataSource> customers() async =>
      di.sl<CustomerRemoteDataSource>();

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  Future<void> seedBooking({
    required String customerId,
    required String shopId,
    required String name,
    required String phone,
    required String cnic,
    required int totalAmount,
    required DateTime pickup,
  }) async {
    await (await bookings()).createBookingRequest(
      customerId: customerId,
      shopId: shopId,
      vehicleId: 'veh-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: pickup,
      returnTime: pickup.add(const Duration(days: 1)),
      totalAmount: totalAmount,
      advanceRequired: 1000,
      customerName: name,
      customerPhone: phone,
      customerCnic: cnic,
    );
  }

  group('customer detail (#35)', () {
    testWidgets('shows header, totals, history and pending status',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-det-1',
        shopId: 'shop-det-1',
        name: 'Ayesha Khan',
        phone: '0300-1111111',
        cnic: '35202-1111111-1',
        createdAt: DateTime(2026, 11, 9),
        profilePhotoUrl: 'https://example.invalid/kyc/face.jpg',
        signatureUrl: 'https://example.invalid/kyc/sig.png',
      ));
      await seedBooking(
          customerId: 'cust-det-1',
          shopId: 'shop-det-1',
          name: 'Ayesha Khan',
          phone: '0300-1111111',
          cnic: '35202-1111111-1',
          totalAmount: 9000,
          pickup: DateTime(2026, 11, 3, 9));
      await seedBooking(
          customerId: 'cust-det-1',
          shopId: 'shop-det-1',
          name: 'Ayesha Khan',
          phone: '0300-1111111',
          cnic: '35202-1111111-1',
          totalAmount: 11500,
          pickup: DateTime(2026, 11, 5, 9));

      await tester.pumpWidget(wrap(const OwnerCustomerDetailView(
          customerId: 'cust-det-1', shopId: 'shop-det-1')));
      await tester.pumpAndSettle();

      expect(find.text('Ayesha Khan'), findsWidgets);
      expect(find.text('0300-1111111 • 35202-1111111-1'), findsOneWidget);
      expect(find.text('Rs. 20,500'), findsOneWidget);
      // Walk-in CRM: shop-managed Active badge, Edit + overflow menu in AppBar.
      expect(find.text('Active'), findsOneWidget);
      expect(find.byKey(const ValueKey('customer_detail_appbar_edit')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('customer_detail_appbar_menu')),
          findsOneWidget);
      expect(find.text('Approve profile'), findsNothing);
      expect(find.text('Reject profile'), findsNothing);
    });

    testWidgets('approve flips the stored status to approved',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-det-2',
        shopId: 'shop-det-2',
        name: 'Bilal Ahmed',
        phone: '0300-2222222',
        cnic: '35202-2222222-2',
        // Walk-in CRM: Approve/Reject is the ONLINE flow now — a
        // walk-in record shows Block/Edit/Archive instead.
        source: 'online',
        createdAt: DateTime(2026, 11, 9),
      ));
      await tester.pumpWidget(wrap(const OwnerCustomerDetailView(
          customerId: 'cust-det-2', shopId: 'shop-det-2')));
      await tester.pumpAndSettle();

      // The detail view is taller than the 600px test viewport; the
      // action row sits below the fold until scrolled into view.
      await tester.ensureVisible(find.text('Approve profile'));
      await tester.tap(find.text('Approve profile'));
      await tester.pumpAndSettle();

      expect(find.text('Approved'), findsOneWidget);
      final stored = await ds.getCustomerById('cust-det-2');
      expect(stored?.approvalStatus, 'approved');
      expect(stored?.reviewedAt, isNotNull);
    });

    testWidgets('reject requires a reason, then stores it',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-det-3',
        shopId: 'shop-det-3',
        name: 'Sara Malik',
        phone: '0300-3333333',
        cnic: '35202-3333333-3',
        // Walk-in CRM: Reject is the ONLINE flow now (see above).
        source: 'online',
        createdAt: DateTime(2026, 11, 9),
      ));
      await tester.pumpWidget(wrap(const OwnerCustomerDetailView(
          customerId: 'cust-det-3', shopId: 'shop-det-3')));
      await tester.pumpAndSettle();

      // The detail view is taller than the 600px test viewport; the
      // action row sits below the fold until scrolled into view.
      await tester.ensureVisible(find.text('Reject profile'));
      await tester.tap(find.text('Reject profile'));
      await tester.pumpAndSettle();
      expect(find.text('Reason for rejection'), findsOneWidget);

      await tester.tap(find.text('Reject'));
      await tester.pump();
      expect(
          find.text('A reason is required to reject a profile'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Fake documents');
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Fake documents'), findsOneWidget);
      final stored = await ds.getCustomerById('cust-det-3');
      expect(stored?.approvalStatus, 'rejected');
      expect(stored?.rejectionReason, 'Fake documents');
    });

    testWidgets('approval fields round-trip through the model',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-det-4',
        shopId: 'shop-det-4',
        name: 'Omar Farooq',
        phone: '0300-4444444',
        createdAt: DateTime(2026, 11, 9),
      ));
      await ds.updateApprovalStatus(
          customerId: 'cust-det-4',
          status: 'rejected',
          rejectionReason: 'Unclear photo');
      final stored = await ds.getCustomerById('cust-det-4');
      expect(stored?.approvalStatus, 'rejected');
      expect(stored?.rejectionReason, 'Unclear photo');
      // Approving afterwards clears the rejection reason.
      await ds.updateApprovalStatus(
          customerId: 'cust-det-4', status: 'approved');
      final approved = await ds.getCustomerById('cust-det-4');
      expect(approved?.approvalStatus, 'approved');
      expect(approved?.rejectionReason, isNull);
    });
  });

  group('O13 success screen', () {
    testWidgets('start booking navigates prefilled, view profile opens detail',
        (tester) async {
      final saved = CustomerEntity(
        customerId: 'cust-added-1',
        shopId: 'shop-added-1',
        name: 'Ayesha Khan',
        phone: '0300-1111111',
        cnic: '35202-1111111-1',
        createdAt: DateTime(2026, 11, 9),
      );
      final router = GoRouter(
        initialLocation: '/added',
        routes: [
          GoRoute(
            path: '/added',
            builder: (_, __) => OwnerCustomerAddedView(
                customerId: 'cust-added-1', customer: saved),
          ),
          GoRoute(
            path: '/owner/manual-booking',
            builder: (_, state) => Scaffold(
                body: Text(
                    'manual-booking ${state.uri.queryParameters['name'] ?? ''}')),
          ),
          GoRoute(
            path: '/owner/customers/:id',
            builder: (_, __) =>
                const Scaffold(body: Text('detail-stub')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.textContaining('profile is ready'), findsOneWidget);

      await tester.tap(find.text('Start Booking'));
      await tester.pumpAndSettle();
      expect(find.text('manual-booking Ayesha Khan'), findsOneWidget);
    });

    testWidgets('view profile navigates to the detail route',
        (tester) async {
      final saved = CustomerEntity(
        customerId: 'cust-added-1',
        shopId: 'shop-added-1',
        name: 'Ayesha Khan',
        phone: '0300-1111111',
        cnic: '35202-1111111-1',
        createdAt: DateTime(2026, 11, 9),
      );
      final router = GoRouter(
        initialLocation: '/added',
        routes: [
          GoRoute(
            path: '/added',
            builder: (_, __) => OwnerCustomerAddedView(
                customerId: 'cust-added-1', customer: saved),
          ),
          GoRoute(
            path: '/owner/manual-booking',
            builder: (_, __) =>
                const Scaffold(body: Text('manual-booking-stub')),
          ),
          GoRoute(
            path: '/owner/customers/:id',
            builder: (_, state) => Scaffold(
                body: Text('detail-stub ${state.pathParameters['id']}')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();
      expect(find.text('detail-stub cust-added-1'), findsOneWidget);
    });
  });

  group('O11 list chips + badges', () {
    testWidgets('chips filter and rows carry Regular / New badges',
        (tester) async {
      // Tall viewport (repo pattern): the shared in-memory queue
      // merges earlier tests' bookings into this shop's list, so a
      // fourth row sits below the fold at the default 600px height
      // and ListView.builder never builds it.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const shopId = 'shop-list-1';
      final bookingDs = await bookings();
      // Regular: 2 rentals.
      await seedBooking(
          customerId: 'cust-reg',
          shopId: shopId,
          name: 'Regular Rana',
          phone: '0300-5555555',
          cnic: '35202-5555555-5',
          totalAmount: 9000,
          pickup: DateTime(2026, 11, 3, 9));
      await seedBooking(
          customerId: 'cust-reg',
          shopId: shopId,
          name: 'Regular Rana',
          phone: '0300-5555555',
          cnic: '35202-5555555-5',
          totalAmount: 9000,
          pickup: DateTime(2026, 11, 4, 9));
      // New: 1 rental, still only requested (no dues).
      await seedBooking(
          customerId: 'cust-new',
          shopId: shopId,
          name: 'New Nadia',
          phone: '0300-6666666',
          cnic: '35202-6666666-6',
          totalAmount: 8000,
          pickup: DateTime(2026, 11, 5, 9));
      // Flagged by dues: 1 rental moved to approved with the full
      // balance still outstanding.
      final due = await bookingDs.createBookingRequest(
        customerId: 'cust-due',
        shopId: shopId,
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 12000,
        advanceRequired: 1000,
        customerName: 'Due Daniyal',
        customerPhone: '0300-7777777',
        customerCnic: '35202-7777777-7',
      );
      await bookingDs.updateBookingStatus(
          bookingId: due.bookingId, status: 'approved');

      await tester.pumpWidget(
          wrap(const OwnerCustomersListView(shopId: shopId)));
      await tester.pumpAndSettle();

      expect(find.text('Regular'), findsWidgets);
      expect(find.text('New'), findsWidgets);
      expect(find.text('Regular Rana'), findsOneWidget);
      expect(find.text('New Nadia'), findsOneWidget);
      expect(find.text('Due Daniyal'), findsOneWidget);

      // Item 5 (2026-11-21): chips carry counts ("Regular (1)"),
      // so the chip text no longer equals the row badge — tap the
      // counted label. The old single 'Flagged' chip is split into
      // Blacklisted / With Dues; nobody here is blacklisted and no
      // saved record is pending approval, so those alert segments
      // stay hidden at zero count.
      expect(find.textContaining('Blacklisted ('), findsNothing);
      expect(find.textContaining('Pending review ('), findsNothing);
      await tester.tap(find.textContaining('Regular ('));
      await tester.pumpAndSettle();
      expect(find.text('Regular Rana'), findsOneWidget);
      expect(find.text('New Nadia'), findsNothing);
      expect(find.text('Due Daniyal'), findsNothing);

      await tester.tap(find.textContaining('New ('));
      await tester.pumpAndSettle();
      expect(find.text('Regular Rana'), findsNothing);
      expect(find.text('New Nadia'), findsOneWidget);
      expect(find.text('Due Daniyal'), findsOneWidget);

      await tester.tap(find.textContaining('With Dues ('));
      await tester.pumpAndSettle();
      expect(find.text('Regular Rana'), findsNothing);
      expect(find.text('New Nadia'), findsNothing);
      expect(find.text('Due Daniyal'), findsOneWidget);

      // Simple customer rows show Profile & Book a Car directly.
      await tester.tap(find.textContaining('All ('));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsNWidgets(3));
      expect(find.text('Book a Car'), findsNWidgets(3));
    });
  });
}
