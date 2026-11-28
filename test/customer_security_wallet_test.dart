import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/customer_detail_body.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_security_wallet_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Worker C (customer Security wallet): the derived wallet's Security
// section totals (held / released / deducted / refunded / owed),
// the localized Security entry wording (cancel-releases worded
// distinctly from return-releases), the live watch, and the owner
// per-customer Security view for walk-in customers only.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  tearDownAll(() {
    SignedInUser.override = null;
  });

  var seq = 0;

  /// Lets the async* fallback streams deliver their next emission.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 100));

  /// Fresh, isolated data sources per test. The DI singletons share
  /// one OfflineSyncQueue, and `getCustomerBookings` merges every
  /// pending queued booking into every result — a wallet `load()`
  /// through the singletons would see every booking any earlier
  /// test created. Fresh instances (no sync queue) have an empty
  /// in-memory store and no pending merge, so each test sees only
  /// its own bookings.
  (BookingRemoteDataSource, SecurityDepositDataSource) freshDs() =>
      (BookingRemoteDataSource(), SecurityDepositDataSource());

  CustomerWalletService walletService({
    required BookingRemoteDataSource bookings,
    required SecurityDepositDataSource deposits,
    WalletEntryTitles titles = WalletEntryTitles.english,
  }) =>
      CustomerWalletService(
        bookings: bookings,
        deposits: deposits,
        titles: titles,
      );

  /// A real booking in [ds], unique per call so tests never share
  /// a customer, a shop, or a booking id.
  Future<BookingEntity> seededBooking(
    BookingRemoteDataSource ds, {
    required String tag,
    int advance = 0,
    String vehicleName = 'Honda Civic',
  }) async {
    seq++;
    final created = await ds.createBookingRequest(
      customerId: 'cust-secwal-$tag-$seq',
      shopId: 'shop-secwal-$tag',
      vehicleId: 'veh-secwal-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime(2026, 11, 21, 9),
      returnTime: DateTime(2026, 11, 22, 9),
      totalAmount: 9000,
      advanceRequired: 3000,
      origin: 'walk_in',
      vehicleName: vehicleName,
    );
    if (advance > 0) {
      return ds.recordAdvancePayment(
        bookingId: created.bookingId,
        advanceAmount: advance,
      );
    }
    return (await ds.getBookingById(created.bookingId))!;
  }

  Future<void> collect(
    SecurityDepositDataSource deposits,
    BookingEntity booking,
    int amount,
  ) =>
      deposits.collect(
        bookingId: booking.bookingId,
        customerId: booking.customerId,
        shopId: booking.shopId,
        amount: amount,
      );

  /// Settles a deposit with [deducted] kept by the shop and
  /// [netRefund] returned; the excess over the held amount lands
  /// in amountOwed.
  Future<void> settleDeposit(
    SecurityDepositDataSource deposits,
    BookingEntity booking, {
    required int deducted,
    required int netRefund,
  }) =>
      deposits.settle(
        bookingId: booking.bookingId,
        totalKmDriven: 350,
        excessKm: 0,
        excessKmCharge: 0,
        fuelDeficit: 0,
        damageCharge: 0,
        overtimeFee: 0,
        deductedAmount: deducted,
        netRefund: netRefund,
      );

  group('Security totals per deposit status', () {
    test('collected → held total + Security held entry', () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'held');
      await collect(deposits, booking, 10000);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(summary.escrowHeld, 10000);
      expect(summary.security.held, 10000);
      expect(summary.security.released, 0);
      expect(summary.security.deducted, 0);
      expect(summary.security.refunded, 0);
      expect(summary.security.owed, 0);
      expect(summary.security.hasActivity, isTrue);
      final held = summary.entries
          .where((e) => e.status == 'Held')
          .toList();
      expect(held.length, 1);
      expect(held.single.title,
          'Security held — Honda Civic (${booking.bookingId})');
      expect(held.single.amount, 10000);
      expect(held.single.isDebit, isTrue);
      // The old wording is gone.
      expect(
          summary.entries
              .any((e) => e.title.contains('Security deposit held')),
          isFalse);
    });

    test('released at return → released total + return wording',
        () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'return');
      await collect(deposits, booking, 20000);
      await settleDeposit(deposits, booking,
          deducted: 0, netRefund: 20000);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(summary.escrowHeld, 0);
      expect(summary.security.held, 0);
      expect(summary.security.released, 20000);
      final released = summary.entries
          .where((e) => e.status == 'Released')
          .toList();
      expect(released.length, 1);
      expect(released.single.title,
          'Security released — Honda Civic (${booking.bookingId})');
      expect(released.single.amount, 20000);
      expect(released.single.isDebit, isFalse);
    });

    test('cancel-release → Released entry worded distinctly from '
        'return-release', () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'cancel');
      await collect(deposits, booking, 20000);
      final released = await deposits.releaseOnCancel(
          bookingId: booking.bookingId);
      expect(released!.releaseReason, 'cancel');

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(summary.escrowHeld, 0);
      expect(summary.security.released, 20000);
      final entries = summary.entries
          .where((e) => e.status == 'Released')
          .toList();
      expect(entries.length, 1);
      expect(
          entries.single.title,
          'Security released on cancellation — '
          'Honda Civic (${booking.bookingId})');
      // And it is NOT the return wording.
      expect(
          entries.single.title,
          isNot('Security released — '
              'Honda Civic (${booking.bookingId})'));
    });

    test('older released records without releaseReason take the '
        'return wording', () async {
      // A return-settlement never writes releaseReason (null) —
      // the wallet treats it as a return-release.
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'legacy');
      await collect(deposits, booking, 15000);
      final stored =
          await deposits.getByBookingId(booking.bookingId);
      expect(stored!.releaseReason, isNull);
      await settleDeposit(deposits, booking,
          deducted: 0, netRefund: 15000);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(
          summary.entries.single.title,
          'Security released — Honda Civic (${booking.bookingId})');
    });

    test('deducted over the held amount → deducted + owed entries, '
        'no refund entry', () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'owed');
      await collect(deposits, booking, 10000);
      await settleDeposit(deposits, booking,
          deducted: 12000, netRefund: 0);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(summary.security.deducted, 10000);
      expect(summary.security.refunded, 0);
      expect(summary.security.owed, 2000);
      final deducted = summary.entries
          .where((e) => e.status == 'Deducted')
          .toList();
      expect(deducted.length, 1);
      expect(deducted.single.title,
          'Security deduction — Honda Civic (${booking.bookingId})');
      expect(deducted.single.amount, 10000);
      // The deduction never exceeds the amount actually held.
      final owed = summary.entries
          .where((e) => e.status == 'Owed')
          .toList();
      expect(owed.length, 1);
      expect(owed.single.title,
          'Security still owed — Honda Civic (${booking.bookingId})');
      expect(owed.single.amount, 2000);
      expect(owed.single.isDebit, isTrue);
      expect(
          summary.entries.any((e) => e.status == 'Refunded'), isFalse);
    });

    test('partial deduction → deducted + refund entries, nothing '
        'owed', () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'partial');
      await collect(deposits, booking, 20000);
      await settleDeposit(deposits, booking,
          deducted: 5000, netRefund: 15000);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(summary.security.deducted, 5000);
      expect(summary.security.refunded, 15000);
      expect(summary.security.owed, 0);
      expect(
          summary.entries
              .where((e) => e.status == 'Deducted')
              .single
              .title,
          'Security deduction — Honda Civic (${booking.bookingId})');
      expect(
          summary.entries
              .where((e) => e.status == 'Refunded')
              .single
              .title,
          'Security refund — Honda Civic (${booking.bookingId})');
      expect(summary.entries.any((e) => e.status == 'Owed'), isFalse);
    });

    test('localized titles are used when supplied', () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'l10n');
      await collect(deposits, booking, 10000);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
        titles: WalletEntryTitles(
          securityHeld: (v, b) => 'UR-HELD $v $b',
          securityReleased: (v, b) => 'UR-REL $v $b',
          securityReleasedOnCancel: (v, b) => 'UR-CANCEL $v $b',
          securityDeducted: (v, b) => 'UR-DED $v $b',
          securityRefunded: (v, b) => 'UR-REF $v $b',
          securityOwed: (v, b) => 'UR-OWED $v $b',
        ),
      ).load(booking.customerId);

      expect(summary.entries.single.title,
          'UR-HELD Honda Civic ${booking.bookingId}');
    });

    test('no deposits → zero Security totals, no activity', () async {
      final (bookings, deposits) = freshDs();
      final booking =
          await seededBooking(bookings, tag: 'none', advance: 3000);

      final summary = await walletService(
        bookings: bookings,
        deposits: deposits,
      ).load(booking.customerId);

      expect(summary.advancesPaid, 3000);
      expect(summary.security.hasActivity, isFalse);
      expect(summary.security.held, 0);
      expect(summary.entries.length, 1);
    });
  });

  group('wallet watch', () {
    test('watch emits the updated summary when a deposit flips '
        'collected → released', () async {
      final (bookings, deposits) = freshDs();
      final booking = await seededBooking(bookings, tag: 'watch');
      await collect(deposits, booking, 15000);
      final service = walletService(
        bookings: bookings,
        deposits: deposits,
      );
      final seen = <CustomerWalletSummary>[];
      final sub = service.watch(booking.customerId).listen(seen.add);
      await settle();
      expect(seen.last.escrowHeld, 15000);
      expect(seen.last.security.held, 15000);

      // The deposit flips on cancel; the booking status change is
      // what re-emits the watch (deposits have no live feed of
      // their own) and the new emission re-reads the deposit.
      await deposits.releaseOnCancel(bookingId: booking.bookingId);
      await bookings.updateBookingStatus(
          bookingId: booking.bookingId, status: 'cancelled');
      await settle();

      expect(seen.last.escrowHeld, 0);
      expect(seen.last.security.held, 0);
      expect(seen.last.security.released, 15000);
      expect(
          seen.last.entries.any((e) => e.title
              .contains('Security released on cancellation')),
          isTrue);
      await sub.cancel();
    });
  });

  group('customer wallet view Security section', () {
    testWidgets('shows the Security totals + held entry', (tester) async {
      SignedInUser.override = const SignedInUserData(
        uid: 'cust-secwal-view',
        displayName: 'Wallet Viewer',
        phoneNumber: '03001234567',
      );
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-secwal-view',
        shopId: 'shop-secwal-view',
        vehicleId: 'veh-secwal-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 21, 9),
        returnTime: DateTime(2026, 11, 22, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        origin: 'walk_in',
        vehicleName: 'Honda Civic',
      );
      await collect(
          di.sl<SecurityDepositDataSource>(), booking, 10000);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerWalletView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Held'), findsAtLeastNWidgets(1));
      expect(find.text('Rs. 10,000'), findsOneWidget);
      expect(find.textContaining('Security held — Honda Civic'),
          findsOneWidget);
      SignedInUser.override = null;
    });
  });

  group('owner per-customer Security wallet view', () {
    CustomerEntity walkInCustomer(String id) => CustomerEntity(
          customerId: id,
          shopId: 'shop-secwal-owner',
          name: 'Walk-in Customer',
          phone: '03001234567',
          createdAt: DateTime(2026, 1, 1),
        );

    Future<void> pumpOwnerView(
      WidgetTester tester, {
      required String customerId,
      CustomerEntity? customer,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerCustomerSecurityWalletView(
            customerId: customerId,
            shopId: 'shop-secwal-owner',
            customer: customer,
            deposits: di.sl<SecurityDepositDataSource>(),
            bookings: di.sl<BookingRemoteDataSource>(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('walk-in customer: same Security totals + entries',
        (tester) async {
      final booking = await seededBooking(
          di.sl<BookingRemoteDataSource>(), tag: 'owner');
      await collect(
          di.sl<SecurityDepositDataSource>(), booking, 20000);
      await settleDeposit(di.sl<SecurityDepositDataSource>(), booking,
          deducted: 5000, netRefund: 15000);

      await pumpOwnerView(tester,
          customerId: booking.customerId,
          customer: walkInCustomer(booking.customerId));

      expect(find.text('Security wallet'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Deducted'), findsAtLeastNWidgets(1));
      expect(find.text('Refunded'), findsAtLeastNWidgets(1));
      expect(find.text('Rs. 5,000'), findsOneWidget);
      expect(find.text('Rs. 15,000'), findsOneWidget);
      expect(find.textContaining('Security deduction — Honda Civic'),
          findsOneWidget);
      expect(find.textContaining('Security refund — Honda Civic'),
          findsOneWidget);
    });

    testWidgets('online customer: refused, no totals shown',
        (tester) async {
      final customer = walkInCustomer('cust-secwal-online')
          .copyWith(source: 'online');

      await pumpOwnerView(tester,
          customerId: customer.customerId, customer: customer);

      expect(
          find.text(
              'Online customers manage their own Security wallet.'),
          findsOneWidget);
      expect(find.text('Security'), findsNothing);
      expect(find.text('Held'), findsNothing);
    });

    testWidgets('walk-in customer with no deposits: empty state',
        (tester) async {
      final customer = walkInCustomer('cust-secwal-empty');

      await pumpOwnerView(tester,
          customerId: customer.customerId, customer: customer);

      expect(
          find.text('No Security activity for this customer yet.'),
          findsOneWidget);
    });
  });

  group('customer detail entry point', () {
    CustomerEntity entity({required String source}) => CustomerEntity(
          customerId: 'cust-secwal-body',
          shopId: 'shop-secwal-body',
          name: 'Body Customer',
          phone: '03001234567',
          source: source,
          createdAt: DateTime(2026, 1, 1),
        );

    Future<void> pumpBody(WidgetTester tester, CustomerEntity c) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomerDetailBody(
              customer: c,
              bookings: const [],
              blacklisted: false,
              shopId: 'shop-secwal-body',
              acting: false,
              onApprove: () {},
              onReject: () {},
              onBlockToggle: () {},
              onEdit: () {},
              onArchive: () {},
              onReplaceSlot: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('walk-in customers are offered the Security wallet',
        (tester) async {
      await pumpBody(tester, entity(source: 'walk_in'));
      await tester.ensureVisible(
          find.byKey(const ValueKey('customer_detail_tab_1')));
      await tester.tap(find.byKey(const ValueKey('customer_detail_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('Security wallet'), findsOneWidget);
    });

    testWidgets('online customers are not offered the Security wallet',
        (tester) async {
      await pumpBody(tester, entity(source: 'online'));
      await tester.ensureVisible(
          find.byKey(const ValueKey('customer_detail_tab_1')));
      await tester.tap(find.byKey(const ValueKey('customer_detail_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('Security wallet'), findsNothing);
    });
  });

  group('security wallet route', () {
    testWidgets('the route pattern resolves to the owner view '
        '(customer resolved from bookings)', (tester) async {
      final booking = await seededBooking(
          di.sl<BookingRemoteDataSource>(), tag: 'route');
      await collect(
          di.sl<SecurityDepositDataSource>(), booking, 10000);
      // No `extra` here on purpose: this is the deep-link path,
      // where the view resolves the walk-in record from the
      // customer's bookings instead of receiving it.
      final router = GoRouter(
        initialLocation:
            '/owner/customers/${booking.customerId}/security-wallet',
        routes: [
          GoRoute(
            path: RouteNames.ownerCustomerSecurityWallet,
            builder: (context, state) =>
                OwnerCustomerSecurityWalletView(
              customerId: state.pathParameters['id']!,
              shopId: booking.shopId,
              customer: state.extra as CustomerEntity?,
              deposits: di.sl<SecurityDepositDataSource>(),
              bookings: di.sl<BookingRemoteDataSource>(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates:
              AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Security wallet'), findsOneWidget);
      expect(find.text('Held'), findsAtLeastNWidgets(1));
      expect(find.text('Rs. 10,000'), findsOneWidget);
    });
  });
}
