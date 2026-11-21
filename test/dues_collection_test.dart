import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_account_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/services/booking_ledger_service.dart';
import 'package:rentalhub/features/owner/presentation/services/dues_collection_service.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dues_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _booking({
  required String id,
  required String shopId,
  int total = 9000,
  int advancePaid = 0,
}) =>
    BookingEntity(
      bookingId: id,
      customerId: 'cust-dues',
      shopId: shopId,
      vehicleId: 'veh-dues',
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 21, 9),
      returnTime: DateTime(2026, 11, 22, 9),
      totalAmount: total,
      advanceRequired: 3000,
      advancePaid: advancePaid,
      remainingBalance: total - advancePaid,
      status: 'paid',
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('DuesCollectionService — dues paid later', () {
    late BookingRemoteDataSource ds;
    late FinanceTransferDataSource transfers;
    late FinanceAccountDataSource accounts;
    late BookingLedgerService ledger;

    setUp(() {
      ds = BookingRemoteDataSource();
      transfers = FinanceTransferDataSource();
      accounts = FinanceAccountDataSource();
      ledger = BookingLedgerService(transfers: transfers, accounts: accounts);
    });

    /// A booking with Rs. 6,000 still due (Rs. 9,000 total, Rs. 3,000
    /// advance verified) in [shopId].
    Future<BookingEntity> dueBooking(String shopId) async {
      final created = await ds.createBookingRequest(
        customerId: 'cust-dues',
        shopId: shopId,
        vehicleId: 'veh-dues',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 21, 9),
        returnTime: DateTime(2026, 11, 22, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Dues Customer',
        customerPhone: '03001234567',
      );
      final paid = await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      expect(paid.remainingBalance, 6000);
      return paid;
    }

    Future<BookingEntity> collect(BookingEntity booking, int amount,
            [String method = 'cash']) =>
        DuesCollectionService.collectDue(
          booking: booking,
          amount: amount,
          paymentMethod: method,
          bookingDataSource: ds,
          ledgerService: ledger,
        );

    test('full payment clears the due + exactly one ledger entry',
        () async {
      final booking = await dueBooking('shop-dues-full');
      final updated = await collect(booking, 6000);
      expect(updated.remainingBalance, 0);
      expect(updated.advancePaid, 9000);
      final posted = await transfers.getShopTransfers('shop-dues-full');
      expect(posted.length, 1);
      final entry = posted.first;
      expect(entry.transferId, 'LEDGER-${booking.bookingId}-dues');
      expect(entry.kind, 'income');
      expect(entry.category, 'rent');
      expect(entry.amountPkr, 6000);
      expect(entry.bookingId, booking.bookingId);
      expect(entry.paymentMethod, 'cash');
    });

    test('partial payment reduces the due and posts only the paid part',
        () async {
      final booking = await dueBooking('shop-dues-part');
      final updated = await collect(booking, 2000);
      expect(updated.remainingBalance, 4000);
      final posted = await transfers.getShopTransfers('shop-dues-part');
      expect(posted.length, 1);
      expect(posted.first.amountPkr, 2000);
    });

    test('a second partial completes the due with one cumulative entry',
        () async {
      final booking = await dueBooking('shop-dues-split');
      await collect(booking, 2000);
      final updated = await collect(booking, 4000);
      expect(updated.remainingBalance, 0);
      final posted = await transfers.getShopTransfers('shop-dues-split');
      expect(posted.length, 1);
      expect(posted.first.transferId, 'LEDGER-${booking.bookingId}-dues');
      expect(posted.first.amountPkr, 6000);
    });

    test('overpayment clamps to the due', () async {
      final booking = await dueBooking('shop-dues-over');
      final updated = await collect(booking, 999999);
      expect(updated.remainingBalance, 0);
      expect(updated.advancePaid, 9000);
      final posted = await transfers.getShopTransfers('shop-dues-over');
      expect(posted.length, 1);
      expect(posted.first.amountPkr, 6000);
    });

    test('a second collection of a cleared due does not double-post',
        () async {
      final booking = await dueBooking('shop-dues-retry');
      await collect(booking, 6000);
      final again = await collect(booking, 100);
      expect(again.remainingBalance, 0);
      expect(again.advancePaid, 9000);
      final posted = await transfers.getShopTransfers('shop-dues-retry');
      expect(posted.length, 1);
      expect(posted.first.amountPkr, 6000);
    });

    test('zero amount collects nothing and posts nothing', () async {
      final booking = await dueBooking('shop-dues-zero');
      final updated = await collect(booking, 0);
      expect(updated.remainingBalance, 6000);
      expect(await transfers.getShopTransfers('shop-dues-zero'), isEmpty);
    });

    test('dues post to the method account', () async {
      await accounts.saveAccount(
          shopId: 'shop-dues-acct', name: 'JazzCash', type: 'jazzcash');
      final jazz = (await accounts.getShopAccounts('shop-dues-acct'))
          .firstWhere((a) => a.type == 'jazzcash');
      final booking = await dueBooking('shop-dues-acct');
      await collect(booking, 6000, 'jazzcash');
      final posted = await transfers.getShopTransfers('shop-dues-acct');
      expect(posted.length, 1);
      expect(posted.first.accountId, jazz.accountId);
      expect(posted.first.paymentMethod, 'jazzcash');
    });
  });

  group('BookingLedgerService.postDues', () {
    late FinanceTransferDataSource transfers;
    late FinanceAccountDataSource accounts;
    late BookingLedgerService ledger;

    setUp(() {
      transfers = FinanceTransferDataSource();
      accounts = FinanceAccountDataSource();
      ledger = BookingLedgerService(transfers: transfers, accounts: accounts);
    });

    test('dues id cannot collide with the other booking events', () async {
      final booking = _booking(id: 'RH-DUES-ID', shopId: 'shop-dues-id');
      await ledger.postOnce(
          booking: booking,
          event: 'balance',
          kind: 'income',
          category: 'rent',
          amount: 1000,
          paymentMethod: 'cash');
      await ledger.postOnce(
          booking: booking,
          event: 'rent-return',
          kind: 'income',
          category: 'rent',
          amount: 1000,
          paymentMethod: 'cash');
      await ledger.postOnce(
          booking: booking,
          event: 'extra-fare',
          kind: 'income',
          category: 'rent',
          amount: 1000,
          paymentMethod: 'cash');
      await ledger.postAdvance(booking: booking, amount: 3000, method: 'cash');
      final dues = await ledger.postDues(
          booking: booking, amount: 2000, paymentMethod: 'cash');
      expect(dues!.transferId, 'LEDGER-RH-DUES-ID-dues');
      expect(dues.amountPkr, 2000);
      final all = await transfers.getShopTransfers('shop-dues-id');
      expect(all.length, 5);
      expect(all.map((t) => t.transferId).toSet().length, 5);
    });

    test('zero amount posts nothing', () async {
      final booking = _booking(id: 'RH-DUES-Z', shopId: 'shop-dues-z');
      expect(await ledger.postDues(booking: booking, amount: 0), isNull);
      expect(await transfers.getShopTransfers('shop-dues-z'), isEmpty);
    });
  });

  group('Dues screen updates after collection', () {
    testWidgets('full collection clears the due without a manual refresh',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-dues-widget',
        shopId: 'shop-dues-widget',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic',
        customerName: 'Widget Dues',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.updateBookingStatus(
          bookingId: created.bookingId, status: 'paid');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerDuesView(shopId: 'shop-dues-widget'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Widget Dues'), findsOneWidget);
      expect(find.text('Rs. 9,000'), findsWidgets);

      await tester.tap(find.text('Record payment'));
      await tester.pumpAndSettle();
      // The amount defaults to the full remaining due.
      final field = tester.widget<TextField>(
          find.byKey(const Key('dues-collect-amount')));
      expect(field.controller!.text, '9000');

      await tester.tap(find.text('Mark Payment Received'));
      await tester.pumpAndSettle();
      expect(find.text('Widget Dues'), findsNothing);
      expect(find.text('No outstanding dues. All clear.'), findsOneWidget);
      expect(find.text('Payment of Rs. 9,000 recorded.'), findsOneWidget);

      final posted = await di
          .sl<FinanceTransferDataSource>()
          .getShopTransfers('shop-dues-widget');
      final dues =
          posted.where((t) => t.transferId == 'LEDGER-${created.bookingId}-dues');
      expect(dues.length, 1);
      expect(dues.first.amountPkr, 9000);
    });
  });
}
