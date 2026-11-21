import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_account_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/finance/data/services/booking_ledger_service.dart';
import 'package:rentalhub/features/finance/domain/entities/security_deposit_entity.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/owner/presentation/services/return_settlement_service.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/finance_deposits_section.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// A valid 1x1 transparent PNG, used as a stand-in signature.
final _tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

Future<BookingEntity> _paidBooking({
  required String shopId,
  int total = 9000,
  int advance = 3000,
}) async {
  final ds = di.sl<BookingRemoteDataSource>();
  final created = await ds.createBookingRequest(
    customerId: 'cust-dep2',
    shopId: shopId,
    vehicleId: 'veh-dep2',
    packageType: '24h',
    isWithDriver: false,
    pickupTime: DateTime(2026, 11, 19, 9),
    returnTime: DateTime(2026, 11, 20, 9),
    totalAmount: total,
    advanceRequired: 3000,
  );
  await ds.verifyPayment(bookingId: created.bookingId, advanceAmount: advance);
  return (await ds.getBookingById(created.bookingId))!;
}

/// A handover that picked a deposit method but never received the
/// deposit ([received] false), mirroring the financial-audit test.
Future<void> _handover({
  required String bookingId,
  required String shopId,
  required bool received,
}) async {
  await di.sl<HandoverCubit>().completeHandoverOfflineFirst(
        bookingId: bookingId,
        shopId: shopId,
        shopName: 'Test Showroom',
        customerName: 'Deposit Customer',
        customerId: 'cust-dep2',
        vehicleDetails: 'Honda Civic 2021',
        totalAmount: 9000,
        advancePaid: 3000,
        securityDeposit: 20000,
        balanceDuePkr: 6000,
        balancePaymentMethod: 'not_yet',
        balanceReceived: false,
        depositPaymentMethod: 'cash',
        depositReceived: received,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignaturePng: _tinyPng,
        ownerSignaturePng: _tinyPng,
        isOnline: false,
      );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Item 2 (a) — a deposit is never collected twice', () {
    test('second collect keeps the first record and amount', () async {
      final ds = SecurityDepositDataSource();
      final first = await ds.collect(
        bookingId: 'dep2-double-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 10000,
      );
      expect(first.amount, 10000);
      expect(first.status, 'collected');
      // The handover passes the vehicle's full deposit; the
      // walk-in's smaller collected amount must win.
      final second = await ds.collect(
        bookingId: 'dep2-double-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 25000,
      );
      expect(second.amount, 10000);
      expect((await ds.getByBookingId('dep2-double-1'))!.amount, 10000);
    });

    test('deposit ledger posts once even when handover re-posts',
        () async {
      final transfers = FinanceTransferDataSource();
      final accounts = FinanceAccountDataSource();
      final ledger =
          BookingLedgerService(transfers: transfers, accounts: accounts);
      final booking = BookingEntity(
        bookingId: 'dep2-double-2',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        remainingBalance: 9000,
      );
      // Walk-in posts the amount actually taken at the counter.
      await ledger.postOnce(
        booking: booking,
        event: 'deposit',
        kind: 'income',
        category: 'deposit',
        amount: 10000,
        paymentMethod: 'cash',
      );
      // Handover re-posts the vehicle's full deposit — same id.
      await ledger.postOnce(
        booking: booking,
        event: 'deposit',
        kind: 'income',
        category: 'deposit',
        amount: 25000,
        paymentMethod: 'cash',
      );
      final entries = (await transfers.getShopTransfers('shop-1'))
          .where((t) => t.category == 'deposit')
          .toList();
      expect(entries.length, 1);
      expect(entries.single.amountPkr, 10000);
      expect(entries.single.transferId, 'LEDGER-dep2-double-2-deposit');
    });
  });

  group('Item 2 (d) — the return screen uses the deposit held', () {
    test('unreceived deposit loads as Rs 0, not the vehicle deposit',
        () async {
      final booking = await _paidBooking(shopId: 'shop-lrv-1');
      await _handover(
          bookingId: booking.bookingId,
          shopId: 'shop-lrv-1',
          received: false);
      final values = await ReturnSettlementService.loadRealValues(
        booking,
        fallbackOdometer: 45200,
        fallbackDeposit: 20000,
      );
      expect(values.deposit, 0);
    });

    test('received deposit loads the held amount', () async {
      final booking = await _paidBooking(shopId: 'shop-lrv-2');
      await _handover(
          bookingId: booking.bookingId,
          shopId: 'shop-lrv-2',
          received: true);
      final values = await ReturnSettlementService.loadRealValues(
        booking,
        fallbackOdometer: 45200,
        fallbackDeposit: 20000,
      );
      expect(values.deposit, 20000);
    });
  });

  group('Item 2 (c) — deductions above the deposit are owed, not deducted',
      () {
    test('deductions cap at the held amount, excess is owed', () async {
      final booking = await _paidBooking(shopId: 'shop-cap-1');
      final breakdown = await ReturnSettlementService.finalizeReturn(
        booking: booking,
        returnOdometer: 45450,
        initialOdometer: 45200,
        kmAllowance: 250,
        extraKmPkr: 100,
        extraHourPkr: 0,
        deposit: 20000,
        fuelLevel: '4/4 (Full)',
        returnDamageNotes: const [],
        damageCharge: 25000,
      );
      expect(breakdown.totalDeductions, 25000);
      expect(breakdown.netRefund, 0);
      expect(breakdown.amountOwed, 5000);
      final held = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      expect(held!.amount, 20000);
      expect(held.status, 'deducted');
      // Only the held deposit was deducted; the Rs 5,000 excess
      // is recorded as owed, not as a deduction.
      expect(held.deductedAmount, 20000);
      expect(held.amountOwed, 5000);
      expect(held.netRefund, 0);
    });

    test('Rs 0 deposit: every rupee of deductions is owed', () async {
      final booking = await _paidBooking(shopId: 'shop-cap-2');
      await _handover(
          bookingId: booking.bookingId,
          shopId: 'shop-cap-2',
          received: false);
      final breakdown = await ReturnSettlementService.finalizeReturn(
        booking: booking,
        returnOdometer: 45450,
        initialOdometer: 45200,
        kmAllowance: 250,
        extraKmPkr: 100,
        extraHourPkr: 0,
        deposit: 20000,
        fuelLevel: '4/4 (Full)',
        returnDamageNotes: const [],
        damageCharge: 5000,
      );
      expect(breakdown.netRefund, 0);
      expect(breakdown.amountOwed, 5000);
      final held = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      expect(held!.amount, 0);
      expect(held.deductedAmount, 0);
      expect(held.amountOwed, 5000);
      expect(held.netRefund, 0);
    });
  });

  group('Item 2 (e) — the deposit refund reaches the ledger once', () {
    test('recordRefund posts immediately; finalize never doubles it',
        () async {
      final booking = await _paidBooking(shopId: 'shop-ref-1');
      await ReturnSettlementService.recordRefund(
          bookingId: booking.bookingId, amount: 15000);
      Future<List<int>> refundEntries() async => (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers('shop-ref-1'))
          .where((t) =>
              t.bookingId == booking.bookingId &&
              t.category == 'deposit_refund')
          .map((t) => t.amountPkr)
          .toList();
      // Posted at record time — no longer dependent on the
      // finalize-time read-back.
      expect(await refundEntries(), [15000]);
      await ReturnSettlementService.finalizeReturn(
        booking: booking,
        returnOdometer: 45450,
        initialOdometer: 45200,
        kmAllowance: 250,
        extraKmPkr: 100,
        extraHourPkr: 0,
        deposit: 20000,
        fuelLevel: '4/4 (Full)',
        returnDamageNotes: const [],
        damageCharge: 5000,
      );
      expect(await refundEntries(), [15000]);
    });

    test('recordRefund for an unknown booking never throws', () async {
      await ReturnSettlementService.recordRefund(
          bookingId: 'dep2-ref-missing', amount: 5000);
    });
  });

  group('Item 2 (6) — deposits summary counts partial refunds', () {
    testWidgets('refunded count includes deducted-with-refund rows',
        (tester) async {
      SecurityDepositEntity deposit({
        required String id,
        required String status,
        required int amount,
        int? deductedAmount,
        int? netRefund,
      }) =>
          SecurityDepositEntity(
            depositId: id,
            bookingId: id,
            customerId: 'cust-1',
            shopId: 'shop-1',
            amount: amount,
            status: status,
            deductedAmount: deductedAmount,
            netRefund: netRefund,
          );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FinanceDepositsSection(
              deposits: [
                deposit(
                    id: 'd1',
                    status: 'released',
                    amount: 22000,
                    netRefund: 22000),
                deposit(
                    id: 'd2',
                    status: 'deducted',
                    amount: 23000,
                    deductedAmount: 5000,
                    netRefund: 18000),
                // Fully kept: deducted, nothing refunded — counts
                // as deducted only, never as refunded.
                deposit(
                    id: 'd3',
                    status: 'deducted',
                    amount: 10000,
                    deductedAmount: 10000,
                    netRefund: 0),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Refunded = 22,000 released + 18,000 partial refund.
      expect(find.text('Rs. 40,000'), findsOneWidget);
      // Deducted = 5,000 kept + 10,000 fully kept.
      expect(find.text('Rs. 15,000'), findsOneWidget);
      // Refunded count = 1 released + 1 partial refund = 2;
      // deducted count = 2 — the same "2 Security" label appears
      // on both rows, and nothing is held.
      expect(find.text('2 Security'), findsNWidgets(2));
      expect(find.text('0 Security'), findsOneWidget);
    });
  });
}
