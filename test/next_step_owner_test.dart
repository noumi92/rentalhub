import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/utils/booking_next_step.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_confirmed_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_summary_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_disputes_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rental_started_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_settlement_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_actions.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Item 2 — owner next-step buttons (shared resolver) and the
// navigate-back rule (every booking-flow save lands on All
// Bookings, `?filter=all`).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  BookingEntity entity({
    String id = 'B1',
    String status = 'requested',
    String? origin,
    String customerId = 'cust-1',
    DateTime? paymentDeadline,
  }) =>
      BookingEntity(
        bookingId: id,
        customerId: customerId,
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime.now().add(const Duration(hours: 5)),
        returnTime: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 21000,
        advanceRequired: 5000,
        advancePaid: status == 'paid' || status == 'active' ? 5000 : 0,
        remainingBalance: 16000,
        status: status,
        origin: origin,
        customerName: 'Test Customer',
        customerPhone: '03001234567',
        vehicleName: 'Honda Civic Oriel',
        paymentDeadline: paymentDeadline,
      );

  GoRouter routerFor({
    required Widget home,
    String initialLocation = '/',
    Widget Function(GoRouterState state)? requestsBuilder,
    Widget Function(GoRouterState state)? disputesBuilder,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
          path: '/owner/requests',
          builder: (_, state) =>
              requestsBuilder?.call(state) ??
              const Scaffold(body: Text('requests')),
        ),
        GoRoute(
          path: '/owner/handover/:id',
          builder: (_, state) => Scaffold(
              body: Text('handover ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/owner/return-landing/:id',
          builder: (_, state) =>
              Scaffold(body: Text('return ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/owner/disputes',
          builder: (_, state) =>
              disputesBuilder?.call(state) ??
              Scaffold(
                  body: Text(
                      'disputes ${state.uri.queryParameters['bookingId'] ?? ''}')),
        ),
        GoRoute(
          path: '/owner/rate-customer/:id',
          builder: (_, state) => Scaffold(
              body: Text('rate-customer ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/owner/contract/:id',
          builder: (_, __) => const Scaffold(body: Text('contract')),
        ),
      ],
    );
  }

  Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
  }

  String location(GoRouter router) =>
      router.routeInformationProvider.value.uri.toString();

  /// A real booking in the in-memory data source, at [status].
  Future<BookingEntity> seedBooking({
    required String customerId,
    required String shopId,
    String customerName = 'View Customer',
    String status = 'requested',
  }) async {
    final ds = sl<BookingRemoteDataSource>();
    final created = await ds.createBookingRequest(
      customerId: customerId,
      shopId: shopId,
      vehicleId: 'veh-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime.now().add(const Duration(hours: 5)),
      returnTime: DateTime.now().add(const Duration(days: 2)),
      totalAmount: 9000,
      advanceRequired: 3000,
      customerName: customerName,
    );
    if (status == 'requested') return created;
    return ds.updateBookingStatus(
        bookingId: created.bookingId, status: status);
  }

  group('resolver — owner next step', () {
    test('paid -> handover, active -> return, disputed -> disputes', () {
      final paid = entity(status: 'paid');
      expect(resolveOwnerNextStep(paid).kind,
          BookingNextStepKind.startHandover);
      expect(resolveOwnerNextStep(paid).destination(paid),
          '/owner/handover/B1');

      final active = entity(status: 'active');
      expect(resolveOwnerNextStep(active).kind,
          BookingNextStepKind.returnSettlement);
      expect(resolveOwnerNextStep(active).destination(active),
          '/owner/return-landing/B1');

      final disputed = entity(status: 'disputed');
      expect(resolveOwnerNextStep(disputed).kind,
          BookingNextStepKind.viewDispute);
      expect(resolveOwnerNextStep(disputed).destination(disputed),
          '/owner/disputes');
    });

    test('completed -> Rate customer, to the owner rating view', () {
      final completed = entity(status: 'completed');
      expect(resolveOwnerNextStep(completed).kind,
          BookingNextStepKind.rateCustomer);
      expect(resolveOwnerNextStep(completed).destination(completed),
          '/owner/rate-customer/B1');
      // The rendered label ('Rate customer') is asserted in the
      // triage-card and summary-view widget tests below.
    });

    test('approved / rejected / cancelled have no route', () {
      for (final status in ['approved', 'rejected', 'cancelled']) {
        final b = entity(status: status);
        expect(resolveOwnerNextStep(b).destination(b), isNull);
      }
      final requested = entity(status: 'requested');
      expect(resolveOwnerNextStep(requested).kind,
          BookingNextStepKind.approve);
      expect(resolveOwnerNextStep(requested).destination(requested), isNull);
    });

    testWidgets('goToAllOwnerBookings targets the list with filter=all',
        (tester) async {
      final router = routerFor(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => goToAllOwnerBookings(context),
            child: const Text('Go'),
          ),
        ),
      );
      await pumpRouter(tester, router);
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });
  });

  group('triage actions — per status', () {
    testWidgets('paid walk-in: Start Handover + Cancel, navigates',
        (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(
                status: 'paid',
                customerId: 'walkin-ns-1',
                origin: 'walk_in'),
            onApprove: () {},
            onReject: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      await tester.tap(find.text('Start Handover'));
      await tester.pumpAndSettle();
      expect(find.text('handover B1'), findsOneWidget);
    });

    testWidgets('paid online: Start Handover, no Cancel', (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking:
                entity(status: 'paid', customerId: 'cust-1', origin: 'online'),
            onApprove: () {},
            onReject: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Cancel booking'), findsNothing);
    });

    testWidgets('active: Proceed to Return & Settlement, navigates',
        (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(status: 'active'),
            onApprove: () {},
            onReject: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Proceed to Return & Settlement'), findsOneWidget);
      expect(find.text('Cancel booking'), findsNothing);
      await tester.tap(find.text('Proceed to Return & Settlement'));
      await tester.pumpAndSettle();
      expect(find.text('return B1'), findsOneWidget);
    });

    testWidgets('disputed: View / Resolve Dispute deep-links the centre',
        (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(status: 'disputed'),
            onApprove: () {},
            onReject: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('View / Resolve Dispute'), findsOneWidget);
      await tester.tap(find.text('View / Resolve Dispute'));
      await tester.pumpAndSettle();
      expect(find.text('disputes B1'), findsOneWidget);
    });

    testWidgets('approved walk-in: Add Payment + Start Handover + Cancel',
        (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(
              status: 'approved',
              customerId: 'walkin-ns-1',
              origin: 'walk_in',
              paymentDeadline: DateTime(2026, 11, 21, 18, 30),
            ),
            onApprove: () {},
            onReject: () {},
            onRecordPayment: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Add Payment'), findsOneWidget);
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.textContaining('Waiting for payment'), findsNothing);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('approved online: waiting line, no Cancel', (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(
                status: 'approved', customerId: 'cust-1', origin: 'online'),
            onApprove: () {},
            onReject: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.textContaining('Waiting for payment'), findsOneWidget);
      expect(find.text('Cancel booking'), findsNothing);
    });

    testWidgets('requested: Approve / Decline unchanged', (tester) async {
      var approved = false;
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(status: 'requested'),
            onApprove: () => approved = true,
            onReject: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      await tester.tap(find.text('Approve'));
      expect(approved, isTrue);
    });

    testWidgets('payment_submitted: Verify Payment Proof unchanged',
        (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(status: 'payment_submitted'),
            onApprove: () {},
            onReject: () {},
            onVerifyProof: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Verify Payment Proof'), findsOneWidget);
    });

    testWidgets('completed: Rate customer, navigates to the rating view',
        (tester) async {
      final router = routerFor(
        home: Scaffold(
          body: RequestTriageActions(
            booking: entity(status: 'completed'),
            onApprove: () {},
            onReject: () {},
            onCancel: () {},
          ),
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Rate customer'), findsOneWidget);
      await tester.tap(find.text('Rate customer'));
      await tester.pumpAndSettle();
      expect(find.text('rate-customer B1'), findsOneWidget);
    });

    testWidgets('terminal statuses render no actions', (tester) async {
      for (final status in ['rejected', 'cancelled']) {
        final router = routerFor(
          home: Scaffold(
            body: RequestTriageActions(
              booking: entity(status: status),
              onApprove: () {},
              onReject: () {},
              onCancel: () {},
            ),
          ),
        );
        await pumpRouter(tester, router);
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
      }
    });
  });

  group('summary view — completed booking rate step', () {
    testWidgets('completed: Rate customer, navigates to the rating view',
        (tester) async {
      final router = routerFor(
        home: OwnerBookingSummaryView(
            booking: entity(id: 'RH-NS-RC', status: 'completed')),
      );
      await pumpRouter(tester, router);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Rate customer'), findsOneWidget);
      await tester.ensureVisible(find.text('Rate customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rate customer'));
      await tester.pumpAndSettle();
      expect(find.text('rate-customer RH-NS-RC'), findsOneWidget);
    });

    testWidgets('rejected / cancelled / disputed show no Rate customer',
        (tester) async {
      for (final status in ['rejected', 'cancelled', 'disputed']) {
        final router = routerFor(
          home: OwnerBookingSummaryView(
              booking: entity(status: status)),
        );
        await pumpRouter(tester, router);
        expect(find.text('Rate customer'), findsNothing);
      }
    });
  });

  group('confirmed view — resolver primary + no View Booking loop', () {
    testWidgets('paid: Start Handover, no View Booking, navigates',
        (tester) async {
      final router = routerFor(
        home: OwnerBookingConfirmedView(
            booking: entity(id: 'RH-NS-C1', status: 'paid')),
      );
      await pumpRouter(tester, router);
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('View Booking'), findsNothing);
      await tester.ensureVisible(find.text('Start Handover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Handover'));
      await tester.pumpAndSettle();
      expect(find.text('handover RH-NS-C1'), findsOneWidget);
    });

    testWidgets('active: Return & Settlement, no View Booking, navigates',
        (tester) async {
      final router = routerFor(
        home: OwnerBookingConfirmedView(
            booking: entity(id: 'RH-NS-C2', status: 'active')),
      );
      await pumpRouter(tester, router);
      expect(find.text('Proceed to Return & Settlement'), findsOneWidget);
      expect(find.text('View Booking'), findsNothing);
      await tester.ensureVisible(find.text('Proceed to Return & Settlement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proceed to Return & Settlement'));
      await tester.pumpAndSettle();
      expect(find.text('return RH-NS-C2'), findsOneWidget);
    });

    testWidgets('approved: waiting line, no primary, View Booking kept',
        (tester) async {
      final router = routerFor(
        home: OwnerBookingConfirmedView(
            booking: entity(
          status: 'approved',
          paymentDeadline: DateTime(2026, 11, 21, 18, 30),
        )),
      );
      await pumpRouter(tester, router);
      expect(find.textContaining('Waiting for payment'), findsOneWidget);
      expect(find.textContaining('21 Nov 2026, 6:30 PM'), findsOneWidget);
      expect(find.text('Start Handover'), findsNothing);
      expect(find.text('View Booking'), findsOneWidget);
    });
  });

  group('requests view — saves land on All Bookings', () {
    testWidgets('decline from the triage list lands on All Bookings',
        (tester) async {
      await seedBooking(
        customerId: 'cust-ns-dec',
        shopId: 'shop-ns-dec',
        customerName: 'Decline Customer',
      );
      final router = routerFor(
        home: const Scaffold(body: Text('home')),
        initialLocation: '/owner/requests?filter=all',
        requestsBuilder: (state) => OwnerBookingRequestsView(
          shopId: 'shop-ns-dec',
          initialFilter:
              state.uri.queryParameters['filter'] ?? 'payment_submitted',
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Decline Customer'), findsOneWidget);
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'No cars available',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Request'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });

    testWidgets('owner cancel of a walk-in lands on All Bookings',
        (tester) async {
      await seedBooking(
        customerId: 'walkin-ns-can-1',
        shopId: 'shop-ns-can',
        customerName: 'Cancel Customer',
        status: 'approved',
      );
      final router = routerFor(
        home: const Scaffold(body: Text('home')),
        initialLocation: '/owner/requests?filter=all',
        requestsBuilder: (state) => OwnerBookingRequestsView(
          shopId: 'shop-ns-can',
          initialFilter:
              state.uri.queryParameters['filter'] ?? 'payment_submitted',
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Cancel Customer'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Customer asked to cancel',
      );
      await tester
          .tap(find.widgetWithText(FilledButton, 'Confirm Cancellation'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });

    testWidgets('approve from the triage list lands on All Bookings',
        (tester) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop-ns-apr').set({
        'bank_accounts': [
          {
            'type': 'jazzcash',
            'account': '0300-1111111',
            'title': 'Shop JazzCash',
          },
        ],
      });
      await seedBooking(
        customerId: 'cust-ns-apr',
        shopId: 'shop-ns-apr',
        customerName: 'Approve Customer',
      );
      final router = routerFor(
        home: const Scaffold(body: Text('home')),
        initialLocation: '/owner/requests?filter=all',
        requestsBuilder: (state) => OwnerBookingRequestsView(
          shopId: 'shop-ns-apr',
          firestore: fake,
          initialFilter:
              state.uri.queryParameters['filter'] ?? 'payment_submitted',
        ),
      );
      await pumpRouter(tester, router);
      expect(find.text('Approve Customer'), findsOneWidget);
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('JazzCash'));
      await tester.pump();
      await tester.tap(find.text('Approve & assign account'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });
  });

  group('disputes centre — deep link + resolve navigates away', () {
    testWidgets('?bookingId= opens that booking dispute sheet',
        (tester) async {
      final ds = sl<DisputeRemoteDataSource>();
      await ds.fileDispute(
        bookingId: 'RH-NS-DSP',
        customerId: 'cust-ns-dsp',
        category: 'Late return',
        description: 'Car came back late.',
        shopId: 'shop-ns-auto',
      );
      final router = routerFor(
        home: const Scaffold(body: Text('home')),
        initialLocation: '/owner/disputes?bookingId=RH-NS-DSP',
        disputesBuilder: (_) =>
            const OwnerDisputesView(shopId: 'shop-ns-auto'),
      );
      await pumpRouter(tester, router);
      expect(find.text('Car came back late.'), findsOneWidget);
    });

    testWidgets('Mark in review leaves the centre for All Bookings',
        (tester) async {
      final ds = sl<DisputeRemoteDataSource>();
      await ds.fileDispute(
        bookingId: 'RH-NS-RES',
        customerId: 'cust-ns-res',
        category: 'Late return',
        description: 'Deposit not returned.',
        shopId: 'shop-ns-resolve',
      );
      final router = routerFor(
        home: const Scaffold(body: Text('home')),
        initialLocation: '/owner/disputes',
        disputesBuilder: (_) =>
            const OwnerDisputesView(shopId: 'shop-ns-resolve'),
      );
      await pumpRouter(tester, router);
      expect(find.text('Late return'), findsOneWidget);
      await tester.tap(find.text('Late return'));
      await tester.pumpAndSettle();
      expect(find.text('Deposit not returned.'), findsOneWidget);
      await tester.tap(find.text('Mark in review'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });
  });

  group('chain ends — rental started + return finalize', () {
    testWidgets('rental-started Done lands on All Bookings',
        (tester) async {
      final router = routerFor(
        home: OwnerRentalStartedView(
            booking: entity(id: 'RH-NS-RS', status: 'active')),
      );
      await pumpRouter(tester, router);
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });

    testWidgets('return finalize lands on All Bookings, not rate-customer',
        (tester) async {
      final seeded = await seedBooking(
        customerId: 'cust-ns-ret',
        shopId: 'shop-ns-ret',
        customerName: 'Return Customer',
        status: 'active',
      );
      final router = routerFor(
        home: OwnerReturnSettlementView(booking: seeded),
      );
      await pumpRouter(tester, router);
      expect(find.text('Vehicle Return & Settlement'), findsOneWidget);
      final refundButton =
          find.widgetWithText(ElevatedButton, 'Refund Security');
      await tester.ensureVisible(refundButton);
      await tester.pumpAndSettle();
      await tester.tap(refundButton);
      await tester.pumpAndSettle();
      expect(find.text('Complete & Close Booking'), findsOneWidget);
      // The refund success SnackBar floats over the bottom of the
      // screen (and the Close button with it) — pump past its 3s
      // duration before tapping Close, or the tap lands on it.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final closeButton =
          find.widgetWithText(ElevatedButton, 'Complete & Close Booking');
      await tester.ensureVisible(closeButton);
      await tester.pumpAndSettle();
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(location(router), '/owner/requests?filter=all');
    });
  });
}
