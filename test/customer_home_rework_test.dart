import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/services/customer_home_service.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/trust/data/datasources/kyc_remote_data_source.dart';
import 'package:rentalhub/features/trust/domain/entities/kyc_document_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Customer rework (Worker C): the rebuilt Home screen — KPIs, KYC
// status, quick actions, recent bookings and upcoming events — all
// rendered from the real repositories through CustomerHomeService,
// with in-memory data sources standing in for Firestore.

class _FakeKycDataSource extends KycRemoteDataSource {
  _FakeKycDataSource(this._doc)
      : super(storageClient: CPanelStorageClient(apiSecretKey: 'test'));

  final KycDocumentEntity? _doc;

  @override
  Future<KycDocumentEntity?> getKyc(String userUid) async => _doc;
}

class _ThrowingBookingsDataSource extends BookingRemoteDataSource {
  @override
  Future<List<BookingEntity>> getCustomerBookings(String customerId) async {
    throw Exception('offline');
  }
}

Future<BookingEntity> _makeBooking(
  BookingRemoteDataSource ds, {
  required String vehicle,
  required DateTime pickup,
  int total = 18000,
  int advanceRequired = 4500,
  String status = 'requested',
  int advancePaid = 0,
}) async {
  var booking = await ds.createBookingRequest(
    customerId: 'cust-101',
    shopId: 'shop-gulberg',
    vehicleId: 'veh-$vehicle',
    packageType: '24h',
    isWithDriver: true,
    pickupTime: pickup,
    returnTime: pickup.add(const Duration(days: 2)),
    totalAmount: total,
    advanceRequired: advanceRequired,
    vehicleName: vehicle,
    vehiclePlate: 'LEA-24-900',
    shopName: 'Al-Falah Rent a Car',
  );
  // createBookingRequest returns a BookingModel; the transitions
  // below return the BookingEntity supertype, so hold the wider
  // type from the start.
  BookingEntity current = booking;
  if (advancePaid > 0) {
    current = await ds.verifyPayment(
      bookingId: current.bookingId,
      advanceAmount: advancePaid,
    );
  }
  if (status != 'requested' && current.status != status) {
    current = await ds.updateBookingStatus(
      bookingId: current.bookingId,
      status: status,
    );
  }
  return current;
}

Future<CustomerHomeService> _buildService({
  BookingRemoteDataSource? bookings,
  SecurityDepositDataSource? deposits,
  KycDocumentEntity? kycDoc,
  double? trustScore,
}) async {
  final bookingsDs = bookings ?? BookingRemoteDataSource();
  final depositsDs = deposits ?? SecurityDepositDataSource();
  final users = FirestoreService();
  if (trustScore != null) {
    await users.setDocument(
      'users',
      'cust-101',
      {'trust_score': trustScore},
    );
  }
  return CustomerHomeService(
    bookings: bookingsDs,
    wallet: CustomerWalletService(bookings: bookingsDs, deposits: depositsDs),
    kyc: _FakeKycDataSource(kycDoc),
    users: users,
  );
}

const _verifiedKyc = KycDocumentEntity(
  userUid: 'cust-101',
  cnicNumber: '35202-1234567-1',
  cnicFrontKey: 'kyc/front',
  cnicBackKey: 'kyc/back',
  licenseKey: 'kyc/license',
  status: 'verified',
);

GoRouter _buildRouter(CustomerHomeService service) {
  // Title and body differ, so find.text on the body is unambiguous.
  Widget stub(String text) => Scaffold(
        appBar: AppBar(title: Text(text)),
        body: Center(child: Text('$text body')),
      );
  return GoRouter(
    initialLocation: '/customer/home',
    routes: [
      GoRoute(
        path: '/customer/home',
        builder: (context, state) =>
            CustomerHomeView(homeService: service),
      ),
      GoRoute(path: '/customer/shops', builder: (context, state) => stub('Shops stub')),
      GoRoute(path: '/customer/wallet', builder: (context, state) => stub('Wallet stub')),
      GoRoute(path: '/customer/support', builder: (context, state) => stub('Support inbox')),
      GoRoute(path: '/customer/sos', builder: (context, state) => stub('SOS stub')),
      GoRoute(path: '/customer/kyc', builder: (context, state) => stub('KYC stub')),
      GoRoute(path: '/customer/bookings', builder: (context, state) => stub('Bookings stub')),
      GoRoute(path: '/customer/bookings/:id', builder: (context, state) => stub('Booking detail stub')),
      GoRoute(path: '/customer/payment/:id', builder: (context, state) => stub('Payment stub')),
      GoRoute(path: '/customer/approved/:id', builder: (context, state) => stub('Approved stub')),
      GoRoute(path: '/customer/pass/:id', builder: (context, state) => stub('Pass stub')),
      GoRoute(path: '/customer/rate/:id', builder: (context, state) => stub('Rate stub')),
      GoRoute(path: '/customer/reputation', builder: (context, state) => stub('Reputation stub')),
    ],
  );
}

Future<GoRouter> _pumpHome(
  WidgetTester tester,
  CustomerHomeService service,
) async {
  final router = _buildRouter(service);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Home is a scrolling dashboard: tap targets below the fold (KYC
/// card, quick actions, recent cards) must be scrolled into view
/// first, or the tap misses with a hit-test warning.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('customer home rework: KPIs', () {
    testWidgets('KPIs render from real data', (tester) async {
      final bookingsDs = BookingRemoteDataSource();
      final depositsDs = SecurityDepositDataSource();
      final now = DateTime.now();
      final paid = await _makeBooking(
        bookingsDs,
        vehicle: 'Honda Civic RS',
        pickup: now.add(const Duration(days: 1)),
        status: 'paid',
        advancePaid: 5000,
      );
      await depositsDs.collect(
        bookingId: paid.bookingId,
        customerId: 'cust-101',
        shopId: 'shop-gulberg',
        amount: 10000,
      );
      await _makeBooking(
        bookingsDs,
        vehicle: 'Toyota Yaris',
        pickup: now.subtract(const Duration(days: 5)),
        status: 'completed',
        advancePaid: 2000,
      );
      await _makeBooking(
        bookingsDs,
        vehicle: 'Suzuki Alto',
        pickup: now.subtract(const Duration(days: 9)),
        status: 'completed',
        advancePaid: 2000,
      );
      final service = await _buildService(
        bookings: bookingsDs,
        deposits: depositsDs,
        kycDoc: _verifiedKyc,
        trustScore: 4.2,
      );
      await _pumpHome(tester, service);

      expect(find.text('Active bookings'), findsOneWidget);
      expect(find.text('Total Trips'), findsOneWidget);
      expect(find.text('Wallet balance'), findsOneWidget);
      expect(find.text('Trust Score'), findsOneWidget);
      // 1 active booking, 2 completed trips.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      // Advances (5000 + 2000 + 2000) + escrow held (10000).
      expect(find.text('Rs. 19,000'), findsOneWidget);
      expect(find.text('4.2 ★'), findsOneWidget);

      // The trust tile opens the reputation screen.
      await _tapVisible(tester, find.text('4.2 ★'));
      expect(find.text('Reputation stub body'), findsOneWidget);
    });

    testWidgets('honest zeros and dashes when nothing is loaded',
        (tester) async {
      final service = await _buildService();
      await _pumpHome(tester, service);

      // Wallet loads fine with no activity, so Rs. 0 is a real sum.
      expect(find.text('Rs. 0'), findsOneWidget);
      // No bookings at all: both counts are 0.
      expect(find.text('0'), findsNWidgets(2));
      // No users doc, so no trust score — a dash, never 5.0.
      expect(find.text('—'), findsOneWidget);
      // No KYC submission yet.
      expect(find.text('Not started'), findsOneWidget);
      expect(find.text('0 of 4 documents ready'), findsOneWidget);
      expect(find.text('No bookings yet'), findsOneWidget);
      expect(find.text('Nothing coming up'), findsOneWidget);
    });
  });

  group('customer home rework: KYC card', () {
    testWidgets('submitted KYC shows the real state and progress',
        (tester) async {
      final service = await _buildService(
        kycDoc: const KycDocumentEntity(
          userUid: 'cust-101',
          cnicNumber: '35202-1234567-1',
          cnicFrontKey: 'kyc/front',
          cnicBackKey: 'kyc/back',
          licenseKey: 'kyc/license',
          status: 'submitted',
        ),
      );
      await _pumpHome(tester, service);

      expect(find.text('Submitted — pending verification'), findsOneWidget);
      expect(find.text('4 of 4 documents ready'), findsOneWidget);
      expect(find.text('View documents'), findsOneWidget);
    });

    testWidgets('rejected KYC shows the rejection and a resubmit CTA',
        (tester) async {
      final service = await _buildService(
        kycDoc: const KycDocumentEntity(
          userUid: 'cust-101',
          cnicNumber: '35202-1234567-1',
          cnicFrontKey: 'kyc/front',
          cnicBackKey: 'kyc/back',
          licenseKey: 'kyc/license',
          status: 'rejected',
        ),
      );
      await _pumpHome(tester, service);

      expect(find.text('Rejected — please resubmit'), findsOneWidget);
      expect(find.text('Submit KYC Documents'), findsOneWidget);
    });

    testWidgets('KYC CTA opens the real KYC flow', (tester) async {
      final service = await _buildService();
      await _pumpHome(tester, service);

      await _tapVisible(tester, find.text('Submit KYC Documents'));
      expect(find.text('KYC stub body'), findsOneWidget);
    });
  });

  group('customer home rework: quick actions', () {
    testWidgets('quick actions navigate to real screens', (tester) async {
      final service = await _buildService();
      final router = await _pumpHome(tester, service);

      Future<void> goHome() async {
        router.go('/customer/home');
        await tester.pumpAndSettle();
      }

      // The tile's InkWell key: the recent-bookings empty state has
      // a second 'Book a Car' button, so the text finder is ambiguous.
      await _tapVisible(
          tester, find.byKey(const ValueKey('quick-action-Book a Car')));
      expect(find.text('Shops stub body'), findsOneWidget);
      await goHome();

      await _tapVisible(tester, find.text('Wallet'));
      expect(find.text('Wallet stub body'), findsOneWidget);
      await goHome();

      await _tapVisible(tester, find.text('Support'));
      expect(find.text('Support inbox body'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Quick links'), findsOneWidget);

      await _tapVisible(tester, find.text('SOS'));
      expect(find.text('SOS stub body'), findsOneWidget);
    });

    testWidgets('bell still opens the support inbox as a sub-screen',
        (tester) async {
      final service = await _buildService();
      final router = await _pumpHome(tester, service);

      await _tapVisible(tester, find.byIcon(Icons.notifications_none_rounded));
      expect(find.text('Support inbox body'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Quick links'), findsOneWidget);
    });
  });

  group('customer home rework: bookings', () {
    testWidgets('recent bookings render with their actions',
        (tester) async {
      final bookingsDs = BookingRemoteDataSource();
      final now = DateTime.now();
      await _makeBooking(
        bookingsDs,
        vehicle: 'Honda Civic RS',
        pickup: now.add(const Duration(days: 1)),
        status: 'paid',
        advancePaid: 5000,
      );
      await _makeBooking(
        bookingsDs,
        vehicle: 'Toyota Yaris',
        pickup: now.subtract(const Duration(days: 3)),
        status: 'completed',
        advancePaid: 2000,
      );
      final service = await _buildService(bookings: bookingsDs);
      final router = await _pumpHome(tester, service);

      expect(find.text('Recent bookings'), findsOneWidget);
      expect(find.text('Honda Civic RS'), findsWidgets);
      expect(find.text('Toyota Yaris'), findsWidgets);

      await _tapVisible(tester, find.text('View Pass'));
      // "View Pass" opens the booking detail, like the bookings list
      // does — the detail is where the pickup pass lives.
      expect(find.text('Booking detail stub body'), findsOneWidget);

      router.go('/customer/home');
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Rate Trip'));
      expect(find.text('Rate stub body'), findsOneWidget);
    });

    testWidgets('upcoming handover renders', (tester) async {
      final bookingsDs = BookingRemoteDataSource();
      final now = DateTime.now();
      await _makeBooking(
        bookingsDs,
        vehicle: 'Honda Civic RS',
        pickup: now.add(const Duration(days: 1)),
        status: 'paid',
        advancePaid: 5000,
      );
      final service = await _buildService(bookings: bookingsDs);
      await _pumpHome(tester, service);

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Handover'), findsOneWidget);
      expect(find.text('Honda Civic RS'), findsWidgets);
    });

    testWidgets('overdue payments are flagged, due payments are due',
        (tester) async {
      final bookingsDs = BookingRemoteDataSource();
      final now = DateTime.now();
      await _makeBooking(
        bookingsDs,
        vehicle: 'Honda Civic RS',
        pickup: now.subtract(const Duration(days: 1)),
        status: 'approved',
      );
      await _makeBooking(
        bookingsDs,
        vehicle: 'Toyota Yaris',
        pickup: now.add(const Duration(days: 2)),
        status: 'approved',
      );
      final service = await _buildService(bookings: bookingsDs);
      await _pumpHome(tester, service);

      // Upcoming rows carry the exact labels.
      expect(find.text('Payment overdue'), findsOneWidget);
      expect(find.text('Payment due'), findsOneWidget);
      // The overdue booking also carries a banner above its recent
      // card, with the amount owed — nothing is hidden.
      expect(find.textContaining('Payment overdue'), findsNWidgets(2));
      expect(find.textContaining('Rs. 18,000'), findsWidgets);
      // Both approved bookings offer the Pay Advance action (upcoming
      // rows + recent card actions).
      expect(find.text('Pay Advance'), findsNWidgets(4));

      // Pay Advance follows the bookings list's flow: the approved
      // screen first.
      await _tapVisible(tester, find.text('Pay Advance').first);
      expect(find.text('Approved stub body'), findsOneWidget);
    });

    testWidgets('bookings load failure shows an error with retry',
        (tester) async {
      final service = await _buildService(
        bookings: _ThrowingBookingsDataSource(),
      );
      await _pumpHome(tester, service);

      expect(find.text('Could not load your bookings. Check your connection and try again.'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No bookings yet'), findsNothing);
    });

    testWidgets('recent bookings do not overflow at 200% text scale',
        (tester) async {
      // Pins the ticket-card status/action flex: at 200% the long
      // status chip plus the action button overflowed the card.
      final bookingsDs = BookingRemoteDataSource();
      final now = DateTime.now();
      await _makeBooking(
        bookingsDs,
        vehicle: 'Honda Civic RS',
        pickup: now.add(const Duration(days: 1)),
        status: 'paid',
        advancePaid: 5000,
      );
      await _makeBooking(
        bookingsDs,
        vehicle: 'Toyota Yaris',
        pickup: now.add(const Duration(days: 2)),
        status: 'approved',
      );
      final service = await _buildService(bookings: bookingsDs);
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: CustomerHomeView(homeService: service),
        width: 360.0,
        height: 640.0,
        textScale: 2.0,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Recent bookings'), findsOneWidget);
    });
  });
}
