import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/services/booking_cancel_service.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_cancel_booking_view.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Worker B (cancel releases the deposit): a cancelled booking's
// held Security is refunded in full, once, with one ledger entry
// under LEDGER-<id>-deposit-cancel-refund; the owner may cancel
// walk-in approved / paid bookings, never online ones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  var seq = 0;

  BookingEntity entity({
    required String id,
    String status = 'approved',
    String? origin,
    String customerId = 'walkin-cancel-1',
    String shopId = 'shop-cancel-1',
  }) =>
      BookingEntity(
        bookingId: id,
        customerId: customerId,
        shopId: shopId,
        vehicleId: 'veh-cancel-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 21, 9),
        returnTime: DateTime(2026, 11, 22, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        advancePaid: 1000,
        remainingBalance: 8000,
        status: status,
        origin: origin,
        depositPaymentMethod: 'cash',
      );

  /// A real booking in the DS: walk-in by default (origin +
  /// `walkin-…` customer id), at [status] via the advance.
  Future<BookingEntity> seededBooking({
    required String tag,
    String? origin,
    String customerId = 'walkin-cancel-1',
    int advance = 1000,
  }) async {
    seq++;
    final ds = di.sl<BookingRemoteDataSource>();
    final created = await ds.createBookingRequest(
      customerId: '$customerId-$tag-$seq',
      shopId: 'shop-cancel-$tag',
      vehicleId: 'veh-cancel-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime(2026, 11, 21, 9),
      returnTime: DateTime(2026, 11, 22, 9),
      totalAmount: 9000,
      advanceRequired: 3000,
      origin: origin ?? 'walk_in',
      depositPaymentMethod: 'cash',
    );
    return ds.recordAdvancePayment(
      bookingId: created.bookingId,
      advanceAmount: advance,
    );
  }

  Future<List<String>> cancelRefundIds(String shopId) async {
    final transfers = await di
        .sl<FinanceTransferDataSource>()
        .getShopTransfers(shopId);
    return transfers.map((t) => t.transferId).toList();
  }

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  group('BookingCancelService.canOwnerCancel', () {
    test('walk-in approved and paid can be owner-cancelled', () {
      expect(
          BookingCancelService.canOwnerCancel(
              entity(id: 'c-g-1', status: 'approved')),
          isTrue);
      expect(
          BookingCancelService.canOwnerCancel(
              entity(id: 'c-g-2', status: 'paid')),
          isTrue);
    });

    test('online bookings are never owner-cancelled', () {
      expect(
          BookingCancelService.canOwnerCancel(entity(
              id: 'c-g-3',
              status: 'approved',
              origin: 'online',
              customerId: 'cust-online-1')),
          isFalse);
      expect(
          BookingCancelService.canOwnerCancel(entity(
              id: 'c-g-4',
              status: 'paid',
              origin: 'online',
              customerId: 'cust-online-1')),
          isFalse);
    });

    test('other walk-in statuses are not owner-cancellable', () {
      for (final status in [
        'requested',
        'payment_submitted',
        'active',
        'completed',
        'rejected',
        'cancelled',
      ]) {
        expect(
          BookingCancelService.canOwnerCancel(
              entity(id: 'c-g-$status', status: status)),
          isFalse,
          reason: 'walk-in $status',
        );
      }
    });

    test('legacy backfill: null origin + walkin- id is a walk-in', () {
      expect(
          BookingCancelService.isWalkInBooking(
              entity(id: 'c-g-5', status: 'approved', origin: null)),
          isTrue);
      expect(
          BookingCancelService.isWalkInBooking(entity(
              id: 'c-g-6',
              status: 'approved',
              origin: null,
              customerId: 'cust-plain-1')),
          isFalse);
    });
  });

  group('releaseDepositOnCancel', () {
    test('held deposit is released in full with one ledger entry',
        () async {
      final booking = await seededBooking(tag: 'held');
      final deposits = di.sl<SecurityDepositDataSource>();
      await deposits.collect(
        bookingId: booking.bookingId,
        customerId: booking.customerId,
        shopId: booking.shopId,
        amount: 20000,
      );

      final released = await BookingCancelService.releaseDepositOnCancel(
        booking: booking,
      );

      expect(released, isNotNull);
      expect(released!.status, 'released');
      expect(released.netRefund, 20000);
      expect(released.deductedAmount, 0);
      expect(released.releaseReason, 'cancel');
      expect(released.releasedAt, isNotNull);
      final stored = await deposits.getByBookingId(booking.bookingId);
      expect(stored!.status, 'released');
      final ids = await cancelRefundIds(booking.shopId);
      expect(
          ids
              .where((id) =>
                  id ==
                  'LEDGER-${booking.bookingId}-deposit-cancel-refund')
              .length,
          1);
      final entry = (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers(booking.shopId))
          .firstWhere((t) =>
              t.transferId ==
              'LEDGER-${booking.bookingId}-deposit-cancel-refund');
      expect(entry.kind, 'expense');
      expect(entry.category, 'deposit_refund');
      expect(entry.amountPkr, 20000);

      // Wallet-visible: nothing held any more, one Released entry.
      final wallet = await CustomerWalletService(
        bookings: di.sl<BookingRemoteDataSource>(),
        deposits: deposits,
      ).load(booking.customerId);
      expect(wallet.escrowHeld, 0);
      expect(
          wallet.entries
              .where((e) => e.status == 'Released' && e.amount == 20000)
              .length,
          1);
    });

    test('no deposit held: no-op, no ledger entry', () async {
      final booking = await seededBooking(tag: 'none');
      final released = await BookingCancelService.releaseDepositOnCancel(
        booking: booking,
      );
      expect(released, isNull);
      final ids = await cancelRefundIds(booking.shopId);
      expect(
          ids.contains(
              'LEDGER-${booking.bookingId}-deposit-cancel-refund'),
          isFalse);
    });

    test('double release: single release, single ledger entry',
        () async {
      final booking = await seededBooking(tag: 'double');
      final deposits = di.sl<SecurityDepositDataSource>();
      await deposits.collect(
        bookingId: booking.bookingId,
        customerId: booking.customerId,
        shopId: booking.shopId,
        amount: 15000,
      );
      final first =
          await BookingCancelService.releaseDepositOnCancel(booking: booking);
      final second =
          await BookingCancelService.releaseDepositOnCancel(booking: booking);
      expect(first!.status, 'released');
      expect(second!.status, 'released');
      expect(second.netRefund, 15000);
      final ids = await cancelRefundIds(booking.shopId);
      expect(
          ids
              .where((id) =>
                  id ==
                  'LEDGER-${booking.bookingId}-deposit-cancel-refund')
              .length,
          1);
    });
  });

  group('cancelBooking (status first, release best-effort)', () {
    test('owner cancels a walk-in approved booking: deposit released',
        () async {
      final booking = await seededBooking(tag: 'own-appr', advance: 1000);
      expect(booking.status, 'approved');
      await di.sl<SecurityDepositDataSource>().collect(
            bookingId: booking.bookingId,
            customerId: booking.customerId,
            shopId: booking.shopId,
            amount: 20000,
          );
      final updated = await BookingCancelService.cancelBooking(
        booking: booking,
        reason: 'Customer asked to cancel',
      );
      expect(updated.status, 'cancelled');
      expect(updated.rejectionReason, 'Customer asked to cancel');
      expect(updated.advancePaid, 1000,
          reason: 'the advance is untouched by a cancel');
      final record = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      expect(record!.status, 'released');
      expect(record.netRefund, 20000);
    });

    test('owner cancels a walk-in paid booking: deposit released',
        () async {
      final booking = await seededBooking(tag: 'own-paid', advance: 3000);
      expect(booking.status, 'paid');
      await di.sl<SecurityDepositDataSource>().collect(
            bookingId: booking.bookingId,
            customerId: booking.customerId,
            shopId: booking.shopId,
            amount: 20000,
          );
      final updated = await BookingCancelService.cancelBooking(
        booking: booking,
        reason: 'Showroom closed that weekend',
      );
      expect(updated.status, 'cancelled');
      final record = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      expect(record!.status, 'released');
      expect(record.netRefund, 20000);
      final ids = await cancelRefundIds(booking.shopId);
      expect(
          ids.contains(
              'LEDGER-${booking.bookingId}-deposit-cancel-refund'),
          isTrue);
    });

    test('cancel with no deposit still succeeds', () async {
      final booking = await seededBooking(tag: 'own-nodep', advance: 1000);
      final updated = await BookingCancelService.cancelBooking(
        booking: booking,
        reason: 'Customer asked to cancel',
      );
      expect(updated.status, 'cancelled');
      final ids = await cancelRefundIds(booking.shopId);
      expect(
          ids.contains(
              'LEDGER-${booking.bookingId}-deposit-cancel-refund'),
          isFalse);
    });
  });

  group('owner triage card (widget)', () {
    testWidgets('walk-in approved shows Cancel booking', (tester) async {
      var tapped = false;
      await tester.pumpWidget(appFor(RequestTriageCard(
        booking: entity(id: 'c-w-1', status: 'approved'),
        onApprove: () {},
        onReject: () {},
        onCancel: () => tapped = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Cancel booking'), findsOneWidget);
      await tester.tap(find.text('Cancel booking'));
      expect(tapped, isTrue);
    });

    testWidgets('walk-in paid shows Cancel booking', (tester) async {
      await tester.pumpWidget(appFor(RequestTriageCard(
        booking: entity(id: 'c-w-2', status: 'paid'),
        onApprove: () {},
        onReject: () {},
        onCancel: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Cancel booking'), findsOneWidget);
    });

    testWidgets('online approved shows no Cancel booking', (tester) async {
      await tester.pumpWidget(appFor(RequestTriageCard(
        booking: entity(
            id: 'c-w-3',
            status: 'approved',
            origin: 'online',
            customerId: 'cust-online-1'),
        onApprove: () {},
        onReject: () {},
        onCancel: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Cancel booking'), findsNothing);
    });

    testWidgets('online paid shows no Cancel booking', (tester) async {
      await tester.pumpWidget(appFor(RequestTriageCard(
        booking: entity(
            id: 'c-w-4',
            status: 'paid',
            origin: 'online',
            customerId: 'cust-online-1'),
        onApprove: () {},
        onReject: () {},
        onCancel: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Cancel booking'), findsNothing);
    });

    testWidgets('walk-in requested shows approve/decline, not cancel',
        (tester) async {
      await tester.pumpWidget(appFor(RequestTriageCard(
        booking: entity(id: 'c-w-5', status: 'requested'),
        onApprove: () {},
        onReject: () {},
        onCancel: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Cancel booking'), findsNothing);
    });
  });

  group('customer cancel view (widget)', () {
    testWidgets('cancelling a requested booking releases its Security',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'walkin-cancel-view-1',
        shopId: 'shop-cancel-view',
        vehicleId: 'veh-cancel-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 21, 9),
        returnTime: DateTime(2026, 11, 22, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        origin: 'walk_in',
        depositPaymentMethod: 'cash',
      );
      await di.sl<SecurityDepositDataSource>().collect(
            bookingId: created.bookingId,
            customerId: created.customerId,
            shopId: created.shopId,
            amount: 20000,
          );
      var cancelled = false;
      await tester.pumpWidget(appFor(CustomerCancelBookingView(
        booking: created,
        onCancelled: () => cancelled = true,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
      final booking = await ds.getBookingById(created.bookingId);
      expect(booking!.status, 'cancelled');
      final record = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(created.bookingId);
      expect(record!.status, 'released');
      expect(record.netRefund, 20000);
      expect(record.releaseReason, 'cancel');
      final ids = await cancelRefundIds(created.shopId);
      expect(
          ids.contains(
              'LEDGER-${created.bookingId}-deposit-cancel-refund'),
          isTrue);
    });
  });
}
