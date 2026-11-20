import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_account_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/finance/data/services/booking_ledger_service.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_account_entity.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_transfer_entity.dart';
import 'package:rentalhub/features/finance/domain/entities/security_deposit_entity.dart';
import 'package:rentalhub/features/finance/utils/finance_summary.dart';
import 'package:rentalhub/features/handover/data/datasources/handover_local_data_source.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/owner/presentation/services/return_settlement_service.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/finance_deposits_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/return_fare_payment_section.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _booking({
  required String id,
  required String shopId,
  String vehicleId = 'veh-audit',
  int total = 9000,
  int advancePaid = 0,
  String status = 'requested',
  String? advanceMethod,
}) =>
    BookingEntity(
      bookingId: id,
      customerId: 'cust-audit',
      shopId: shopId,
      vehicleId: vehicleId,
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 20, 9),
      returnTime: DateTime(2026, 11, 21, 9),
      totalAmount: total,
      advanceRequired: 3000,
      advancePaid: advancePaid,
      remainingBalance: total - advancePaid,
      status: status,
      advancePaymentMethod: advanceMethod,
    );

/// A valid 1x1 transparent PNG, used as a stand-in signature.
final _tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('BookingLedgerService — exactly-once posting', () {
    late FinanceTransferDataSource transfers;
    late FinanceAccountDataSource accounts;
    late BookingLedgerService ledger;

    setUp(() {
      transfers = FinanceTransferDataSource();
      accounts = FinanceAccountDataSource();
      ledger = BookingLedgerService(transfers: transfers, accounts: accounts);
    });

    test('advance posts once under a deterministic id, to the right account',
        () async {
      await accounts.saveAccount(
          shopId: 'shop-led', name: 'JazzCash', type: 'jazzcash');
      final booking = _booking(id: 'RH-LED-1', shopId: 'shop-led');
      final first = await ledger.postAdvance(
          booking: booking, amount: 3000, method: 'jazzcash');
      expect(first, isNotNull);
      expect(first!.transferId, 'LEDGER-RH-LED-1-advance');
      expect(first.kind, 'income');
      expect(first.category, 'advance');
      expect(first.amountPkr, 3000);
      expect(first.bookingId, 'RH-LED-1');
      expect(first.paymentMethod, 'jazzcash');
      final jazz = (await accounts.getShopAccounts('shop-led'))
          .firstWhere((a) => a.type == 'jazzcash');
      expect(first.accountId, jazz.accountId);

      // A re-post (retry / re-verify) upserts the same entry.
      final second = await ledger.postAdvance(
          booking: booking, amount: 5000, method: 'jazzcash');
      expect(second!.transferId, first.transferId);
      expect(second.amountPkr, 5000);
      final all = await transfers.getShopTransfers('shop-led');
      expect(all.where((t) => t.category == 'advance').length, 1);
    });

    test('postOnce never writes the same cash event twice', () async {
      final booking = _booking(id: 'RH-LED-2', shopId: 'shop-led2');
      final first = await ledger.postOnce(
        booking: booking,
        event: 'balance',
        kind: 'income',
        category: 'rent',
        amount: 6000,
        paymentMethod: 'cash',
      );
      expect(first, isNotNull);
      final second = await ledger.postOnce(
        booking: booking,
        event: 'balance',
        kind: 'income',
        category: 'rent',
        amount: 6000,
        paymentMethod: 'cash',
      );
      expect(second!.transferId, first!.transferId);
      final all = await transfers.getShopTransfers('shop-led2');
      expect(all.length, 1);
    });

    test('zero amounts post nothing; bank normalises to bank_transfer',
        () async {
      final booking = _booking(id: 'RH-LED-3', shopId: 'shop-led3');
      expect(await ledger.postAdvance(booking: booking, amount: 0),
          isNull);
      expect(await ledger.postOnce(
            booking: booking,
            event: 'balance',
            kind: 'income',
            category: 'rent',
            amount: 0,
          ),
          isNull);
      expect(BookingLedgerService.normalizeMethod('bank'), 'bank_transfer');
      expect(BookingLedgerService.normalizeMethod('cash'), 'cash');
      final posted = await ledger.postOnce(
        booking: booking,
        event: 'balance',
        kind: 'income',
        category: 'rent',
        amount: 100,
        paymentMethod: 'bank',
      );
      expect(posted!.paymentMethod, 'bank_transfer');
    });
  });

  group('FinanceSummary — booking revenue counted once', () {
    FinanceTransferEntity transfer({
      required String id,
      required String kind,
      required String category,
      required int amount,
      String? bookingId,
      String? vehicleId,
    }) =>
        FinanceTransferEntity(
          transferId: id,
          shopId: 'shop-sum',
          accountId: 'acc-1',
          kind: kind,
          category: category,
          amountPkr: amount,
          bookingId: bookingId,
          vehicleId: vehicleId,
          createdAt: DateTime(2026, 11, 20, 10),
        );

    test('period totals exclude booking-tagged rent/advance income', () {
      final totals = FinanceSummary.periodTotals([
        transfer(id: 't1', kind: 'income', category: 'advance', amount: 3000, bookingId: 'RH-S-1'),
        transfer(id: 't2', kind: 'income', category: 'rent', amount: 6000, bookingId: 'RH-S-1'),
        transfer(id: 't3', kind: 'income', category: 'rent', amount: 500),
        transfer(id: 't4', kind: 'income', category: 'deposit', amount: 20000, bookingId: 'RH-S-1'),
        transfer(id: 't5', kind: 'expense', category: 'deposit_refund', amount: 15000, bookingId: 'RH-S-1'),
      ]);
      expect(totals.income, 20500);
      expect(totals.expenses, 15000);
      expect(totals.net, 5500);
    });

    test('category totals and vehicle P&L exclude the same entries', () {
      final income = FinanceSummary.categoryTotals([
        transfer(id: 't1', kind: 'income', category: 'advance', amount: 3000, bookingId: 'RH-S-1'),
        transfer(id: 't2', kind: 'income', category: 'rent', amount: 500),
      ], kind: 'income');
      expect(income['advance'], isNull);
      expect(income['rent'], 500);
      final pnl = FinanceSummary.vehiclePnL(
        vehicleId: 'v1',
        bookings: [_booking(id: 'RH-S-1', shopId: 'shop-sum', vehicleId: 'v1', advancePaid: 9000, status: 'completed')],
        transfers: [
          transfer(id: 't1', kind: 'income', category: 'rent', amount: 9000, bookingId: 'RH-S-1', vehicleId: 'v1'),
          transfer(id: 't2', kind: 'income', category: 'other', amount: 400, vehicleId: 'v1'),
          transfer(id: 't3', kind: 'expense', category: 'fuel', amount: 1000, vehicleId: 'v1'),
        ],
      );
      expect(pnl.revenue, 9000);
      expect(pnl.income, 400);
      expect(pnl.net, 8400);
    });

    test('account balances still include booking-tagged cash', () {
      const account = FinanceAccountEntity(
        accountId: 'acc-1',
        shopId: 'shop-sum',
        name: 'Cash in Hand',
        type: 'cash',
      );
      final balance = FinanceSummary.accountBalance(
        account,
        [
          transfer(id: 't1', kind: 'income', category: 'advance', amount: 3000, bookingId: 'RH-S-1'),
        ],
      );
      expect(balance, 3000);
    });
  });

  group('Booking payment methods persist on the booking', () {
    test('methods round-trip through the model', () {
      final model = BookingModel(
        bookingId: 'RH-M-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        remainingBalance: 6000,
        advancePaid: 3000,
        advancePaymentMethod: 'easypaisa',
        depositPaymentMethod: 'cash',
      );
      final restored = BookingModel.fromMap(model.toMap(), 'RH-M-1');
      expect(restored.advancePaymentMethod, 'easypaisa');
      expect(restored.depositPaymentMethod, 'cash');
      // The methods ride the map (not just the entity).
      expect(model.toMap()['advancePaymentMethod'], 'easypaisa');
      expect(model.toMap()['depositPaymentMethod'], 'cash');
      expect(restored.advancePaid, 3000);
      expect(restored.totalAmount, 9000);
      final legacy = BookingModel.fromMap(
          {'bookingId': 'RH-M-2', 'totalAmount': 100}, 'RH-M-2');
      expect(legacy.advancePaymentMethod, isNull);
      expect(legacy.depositPaymentMethod, isNull);
    });

    test('verify + recordAdvance post the advance to the ledger', () async {
      final transfers = FinanceTransferDataSource();
      final accounts = FinanceAccountDataSource();
      final service = BookingLedgerService(
          transfers: transfers, accounts: accounts);
      final ds = BookingRemoteDataSource(ledgerService: service);
      final created = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-vfy',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        advancePaymentMethod: 'cash',
      );
      expect(created.advancePaymentMethod, 'cash');
      final partial = await ds.recordAdvancePayment(
          bookingId: created.bookingId, advanceAmount: 1000);
      expect(partial.status, 'approved');
      var posted = await transfers.getShopTransfers('shop-vfy');
      expect(posted.length, 1);
      expect(posted.first.amountPkr, 1000);
      expect(posted.first.category, 'advance');
      // Re-verifying with the full amount updates the one entry.
      final paid = await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      expect(paid.status, 'paid');
      posted = await transfers.getShopTransfers('shop-vfy');
      expect(posted.length, 1);
      expect(posted.first.amountPkr, 3000);
      // An over-large verification clamps to the booked total.
      final over = await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 999999);
      expect(over.advancePaid, 9000);
    });

    test('recordBalanceCollected is additive, clamped, status-neutral',
        () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-bal',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      final paid = await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      expect(paid.remainingBalance, 6000);
      final after = await ds.recordBalanceCollected(
          bookingId: created.bookingId, amount: 999999);
      expect(after.advancePaid, 9000);
      expect(after.remainingBalance, 0);
      expect(after.status, 'paid');
      final noop = await ds.recordBalanceCollected(
          bookingId: created.bookingId, amount: 100);
      expect(noop.advancePaid, 9000);
    });
  });

  group('Walk-in counter deposit is a held liability', () {
    test('deposit creates a security_deposits record + ledger entry',
        () async {
      final vehicle = _testVehicle();
      final pkg24 =
          vehicle.packages.firstWhere((p) => p.label == '24h');
      final booking = await WalkInBookingService.createWalkInBooking(
        name: 'Counter Customer',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        guarantor: null,
        vehicle: vehicle,
        package: pkg24,
        isWithDriver: false,
        rentAmount: 9000,
        advanceRequired: 3000,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        tripType: 'in_city',
        advanceReceived: 3000,
        depositAmountPkr: 20000,
        paymentMethod: 'jazzcash',
        depositMethod: 'cash',
      );
      expect(booking.advancePaymentMethod, 'jazzcash');
      expect(booking.depositPaymentMethod, 'cash');
      final held = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      expect(held, isNotNull);
      expect(held!.amount, 20000);
      expect(held.status, 'collected');
      final ledgerEntries = (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers(booking.shopId))
          .where((t) => t.bookingId == booking.bookingId)
          .toList();
      expect(
          ledgerEntries.any((t) =>
              t.category == 'deposit' && t.amountPkr == 20000),
          isTrue);
      expect(
          ledgerEntries.any((t) =>
              t.category == 'advance' && t.amountPkr == 3000),
          isTrue);
    });
  });

  group('Handover cash — balance and deposit', () {
    test('collected balance ledgers once and clears the due', () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-ho',
        shopId: 'shop-ho',
        vehicleId: 'veh-ho',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      final cubit = di.sl<HandoverCubit>();
      final entity = await cubit.completeHandoverOfflineFirst(
        bookingId: created.bookingId,
        shopId: 'shop-ho',
        shopName: 'Test Showroom',
        customerName: 'Handover Customer',
        customerId: 'cust-ho',
        vehicleDetails: 'Honda Civic 2021',
        totalAmount: 9000,
        advancePaid: 3000,
        securityDeposit: 20000,
        balanceDuePkr: 6000,
        balancePaymentMethod: 'cash',
        balanceReceived: true,
        depositPaymentMethod: 'easypaisa',
        depositReceivedAt: DateTime(2026, 11, 20, 10),
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignaturePng: _tinyPng,
        ownerSignaturePng: _tinyPng,
        isOnline: false,
      );
      expect(entity.balanceReceived, isTrue);
      final booking = await ds.getBookingById(created.bookingId);
      expect(booking!.advancePaid, 9000);
      expect(booking.remainingBalance, 0);
      final entries = (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers('shop-ho'))
          .where((t) => t.bookingId == created.bookingId)
          .toList();
      expect(
          entries.any((t) =>
              t.category == 'rent' && t.amountPkr == 6000),
          isTrue);
      expect(
          entries.any((t) =>
              t.category == 'deposit' && t.amountPkr == 20000),
          isTrue);
      final held = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(created.bookingId);
      expect(held, isNotNull);
      expect(held!.amount, 20000);
      final stored = await di
          .sl<HandoverLocalDataSource>()
          .getHandover(created.bookingId);
      expect(stored!.balanceReceived, isTrue);
    });

    test('unreceived balance and deposit record nothing', () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-ho2',
        shopId: 'shop-ho2',
        vehicleId: 'veh-ho',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      final cubit = di.sl<HandoverCubit>();
      final entity = await cubit.completeHandoverOfflineFirst(
        bookingId: created.bookingId,
        shopId: 'shop-ho2',
        shopName: 'Test Showroom',
        customerName: 'Handover Customer',
        customerId: 'cust-ho2',
        vehicleDetails: 'Honda Civic 2021',
        totalAmount: 9000,
        advancePaid: 3000,
        securityDeposit: 20000,
        balanceDuePkr: 6000,
        balancePaymentMethod: 'not_yet',
        balanceReceived: false,
        depositPaymentMethod: 'cash',
        depositReceived: false,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignaturePng: _tinyPng,
        ownerSignaturePng: _tinyPng,
        isOnline: false,
      );
      expect(entity.balanceReceived, isFalse);
      final booking = await ds.getBookingById(created.bookingId);
      expect(booking!.advancePaid, 3000);
      expect(booking.remainingBalance, 6000);
      final entries = (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers('shop-ho2'))
          .where((t) => t.bookingId == created.bookingId)
          .toList();
      expect(entries.where((t) => t.category == 'rent'), isEmpty);
      expect(entries.where((t) => t.category == 'deposit'), isEmpty);
      expect(
          await di
              .sl<SecurityDepositDataSource>()
              .getByBookingId(created.bookingId),
          isNull);
    });
  });

  group('Deposits summary — partial refunds are not lost', () {
    testWidgets('deducted deposit with a net refund counts as refunded',
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
                deposit(id: 'd1', status: 'collected', amount: 21000),
                deposit(
                    id: 'd2',
                    status: 'released',
                    amount: 22000,
                    netRefund: 22000),
                deposit(
                    id: 'd3',
                    status: 'deducted',
                    amount: 23000,
                    deductedAmount: 5000,
                    netRefund: 18000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Refunded = 22,000 released + 18,000 partial refund.
      expect(find.text('Rs. 40,000'), findsOneWidget);
      // Deducted = only the kept 5,000.
      expect(find.text('Rs. 5,000'), findsOneWidget);
      // Held = the one still collected (released money only shows
      // inside the refunded total — there is no separate row).
      expect(find.text('Rs. 21,000'), findsOneWidget);
    });
  });

  group('Return settlement — cash lands in the ledger, dues clear', () {
    test('finalize applies collected rent and ledgers refund + owed',
        () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-ret',
        shopId: 'shop-ret',
        vehicleId: 'veh-ret',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 19, 9),
        returnTime: DateTime(2026, 11, 20, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      await ReturnSettlementService.recordRefund(
          bookingId: created.bookingId, amount: 15000);
      await ReturnSettlementService.recordOwedCollected(
          bookingId: created.bookingId, amount: 2000, method: 'jazzcash');
      final booking = (await ds.getBookingById(created.bookingId))!;
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
        remainingRentCollected: 6000,
        paymentMethod: 'cash',
      );
      expect(breakdown.netRefund, 15000);
      expect(breakdown.amountOwed, 0);
      final settled = await ds.getBookingById(created.bookingId);
      expect(settled!.status, 'completed');
      expect(settled.advancePaid, 9000);
      expect(settled.remainingBalance, 0);
      final entries = (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers('shop-ret'))
          .where((t) => t.bookingId == created.bookingId)
          .toList();
      expect(
          entries.any((t) =>
              t.category == 'rent' &&
              t.amountPkr == 6000 &&
              t.paymentMethod == 'cash'),
          isTrue);
      expect(
          entries.any((t) =>
              t.kind == 'expense' &&
              t.category == 'deposit_refund' &&
              t.amountPkr == 15000),
          isTrue);
      expect(
          entries.any((t) =>
              t.category == 'other' &&
              t.amountPkr == 2000 &&
              t.paymentMethod == 'jazzcash'),
          isTrue);
    });

    test('unreceived deposit settles against Rs 0, not phantom money',
        () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-ret2',
        shopId: 'shop-ret2',
        vehicleId: 'veh-ret',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 19, 9),
        returnTime: DateTime(2026, 11, 20, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      // A handover that picked a deposit method but never received it.
      final cubit = di.sl<HandoverCubit>();
      await cubit.completeHandoverOfflineFirst(
        bookingId: created.bookingId,
        shopId: 'shop-ret2',
        shopName: 'Test Showroom',
        customerName: 'Return Customer',
        customerId: 'cust-ret2',
        vehicleDetails: 'Honda Civic 2021',
        totalAmount: 9000,
        advancePaid: 3000,
        securityDeposit: 20000,
        balanceDuePkr: 6000,
        balancePaymentMethod: 'not_yet',
        balanceReceived: false,
        depositPaymentMethod: 'cash',
        depositReceived: false,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignaturePng: _tinyPng,
        ownerSignaturePng: _tinyPng,
        isOnline: false,
      );
      final booking = (await ds.getBookingById(created.bookingId))!;
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
        remainingRentCollected: 0,
      );
      // Nothing was held: the Rs 5,000 damage is owed, not deducted.
      expect(breakdown.netRefund, 0);
      expect(breakdown.amountOwed, 5000);
      final held = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(created.bookingId);
      expect(held!.amount, 0);
    });
  });

  group('Per-km extra fare — collect at return, remainder to dues', () {
    Future<BookingEntity> perKmBooking({
      required String shopId,
      int total = 9000,
      int advance = 3000,
    }) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-xf',
        shopId: shopId,
        vehicleId: 'veh-xf',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 19, 9),
        returnTime: DateTime(2026, 11, 20, 9),
        totalAmount: total,
        advanceRequired: 3000,
        tripType: 'out_of_city',
        outCityMode: 'perKm',
        outCityPerKmPkr: 100,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: advance);
      return (await ds.getBookingById(created.bookingId))!;
    }

    Future<List<FinanceTransferEntity>> bookingEntries(
        String shopId, String bookingId) async {
      return (await di
              .sl<FinanceTransferDataSource>()
              .getShopTransfers(shopId))
          .where((t) => t.bookingId == bookingId)
          .toList();
    }

    Future<BookingEntity> finalizePerKm({
      required BookingEntity booking,
      required int totalKmDriven,
      int rentCollected = 6000,
      String? rentMethod = 'cash',
      int extraCollected = 0,
      String? extraMethod,
    }) async {
      final perKm = ReturnSettlementService.perKmSettlementFor(
        booking: booking,
        totalKmDriven: totalKmDriven,
        pricing: const PerKmPricing(),
      );
      await ReturnSettlementService.finalizeReturn(
        booking: booking,
        returnOdometer: 45200 + totalKmDriven,
        initialOdometer: 45200,
        kmAllowance: 250,
        extraKmPkr: 100,
        extraHourPkr: 0,
        deposit: 0,
        fuelLevel: '4/4 (Full)',
        returnDamageNotes: const [],
        damageCharge: 0,
        remainingRentCollected: rentCollected,
        paymentMethod: rentMethod,
        perKmSettlement: perKm,
        extraFareCollected: extraCollected,
        extraFarePaymentMethod: extraMethod,
      );
      return (await di
          .sl<BookingRemoteDataSource>()
          .getBookingById(booking.bookingId))!;
    }

    test('recordExtraFare grows the total, remainder stays due', () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-xf1',
        shopId: 'shop-xf1',
        vehicleId: 'veh-xf',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 19, 9),
        returnTime: DateTime(2026, 11, 20, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      final updated = await ds.recordExtraFare(
          bookingId: created.bookingId, extraDue: 6000, collected: 2500);
      expect(updated.totalAmount, 15000);
      expect(updated.advancePaid, 5500);
      expect(updated.remainingBalance, 9500);
      expect(updated.status, 'paid');
      // Zero extra is a no-op.
      final noop = await ds.recordExtraFare(
          bookingId: created.bookingId, extraDue: 0, collected: 0);
      expect(noop.totalAmount, 15000);
      expect(noop.remainingBalance, 9500);
    });

    test('recordExtraFare clamps an over-collection to the extra due',
        () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-xf1b',
        shopId: 'shop-xf1b',
        vehicleId: 'veh-xf',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 19, 9),
        returnTime: DateTime(2026, 11, 20, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.verifyPayment(
          bookingId: created.bookingId, advanceAmount: 3000);
      final updated = await ds.recordExtraFare(
          bookingId: created.bookingId, extraDue: 6000, collected: 999999);
      expect(updated.totalAmount, 15000);
      expect(updated.advancePaid, 9000);
      expect(updated.remainingBalance, 6000);
    });

    test('fully collected extra fare ledgers once and clears the due',
        () async {
      const shopId = 'shop-xf-full';
      final booking = await perKmBooking(shopId: shopId);
      // 150 km at Rs 100/km = Rs 15,000 actual vs Rs 9,000 booked.
      final perKm = ReturnSettlementService.perKmSettlementFor(
        booking: booking,
        totalKmDriven: 150,
        pricing: const PerKmPricing(),
      );
      expect(perKm!.extraDue, 6000);
      final settled = await finalizePerKm(
        booking: booking,
        totalKmDriven: 150,
        extraCollected: 6000,
        extraMethod: 'jazzcash',
      );
      expect(settled.status, 'completed');
      expect(settled.totalAmount, 15000);
      expect(settled.advancePaid, 15000);
      expect(settled.remainingBalance, 0);
      final entries =
          await bookingEntries(shopId, booking.bookingId);
      expect(entries.length, 3);
      final extra = entries.firstWhere(
          (t) => t.transferId == 'LEDGER-${booking.bookingId}-extra-fare');
      expect(extra.kind, 'income');
      expect(extra.category, 'rent');
      expect(extra.amountPkr, 6000);
      expect(extra.paymentMethod, 'jazzcash');
      final rent = entries.firstWhere(
          (t) => t.transferId == 'LEDGER-${booking.bookingId}-rent-return');
      expect(rent.amountPkr, 6000);
      expect(rent.transferId, isNot(extra.transferId));
      // The cash really arrived: advance + rent + extra fare.
      final cash = entries.fold<int>(
          0, (s, t) => s + (t.kind == 'income' ? t.amountPkr : -t.amountPkr));
      expect(cash, 15000);
      // P&L counts the fare exactly once, as booking revenue: the
      // three tagged postings are excluded from ledger income, and
      // the grown total carries the extra fare in revenue.
      final pnl = FinanceSummary.vehiclePnL(
        vehicleId: 'veh-xf',
        bookings: [settled],
        transfers: entries,
      );
      expect(pnl.revenue, 15000);
      expect(pnl.income, 0);
      expect(pnl.net, 15000);
    });

    test('partially collected extra fare: collected ledgers, rest is dues',
        () async {
      const shopId = 'shop-xf-part';
      final booking = await perKmBooking(shopId: shopId);
      final settled = await finalizePerKm(
        booking: booking,
        totalKmDriven: 150,
        extraCollected: 2500,
        extraMethod: 'cash',
      );
      expect(settled.status, 'completed');
      expect(settled.totalAmount, 15000);
      expect(settled.advancePaid, 11500);
      // The uncollected Rs 3,500 stays in the balance on a
      // completed booking — the dues list picks it up.
      expect(settled.remainingBalance, 3500);
      final entries =
          await bookingEntries(shopId, booking.bookingId);
      final extra = entries.where((t) =>
          t.transferId == 'LEDGER-${booking.bookingId}-extra-fare');
      expect(extra.length, 1);
      expect(extra.first.amountPkr, 2500);
    });

    test('uncollected extra fare: full amount in dues, no ledger post',
        () async {
      const shopId = 'shop-xf-none';
      final booking = await perKmBooking(shopId: shopId);
      final settled = await finalizePerKm(
        booking: booking,
        totalKmDriven: 150,
        extraCollected: 0,
      );
      expect(settled.totalAmount, 15000);
      expect(settled.advancePaid, 9000);
      expect(settled.remainingBalance, 6000);
      expect(settled.status, 'completed');
      final entries =
          await bookingEntries(shopId, booking.bookingId);
      expect(
          entries.where((t) =>
              t.transferId == 'LEDGER-${booking.bookingId}-extra-fare'),
          isEmpty);
    });

    test('over-collection at return clamps to the extra due', () async {
      const shopId = 'shop-xf-clamp';
      final booking = await perKmBooking(shopId: shopId);
      final settled = await finalizePerKm(
        booking: booking,
        totalKmDriven: 150,
        extraCollected: 999999,
        extraMethod: 'cash',
      );
      expect(settled.advancePaid, 15000);
      expect(settled.remainingBalance, 0);
      final entries =
          await bookingEntries(shopId, booking.bookingId);
      final extra = entries.firstWhere((t) =>
          t.transferId == 'LEDGER-${booking.bookingId}-extra-fare');
      expect(extra.amountPkr, 6000);
    });

    test('zero extra fare: no post, no dues change', () async {
      const shopId = 'shop-xf-zero';
      final booking = await perKmBooking(shopId: shopId);
      // 50 km at Rs 100/km = Rs 5,000 actual vs Rs 9,000 booked:
      // a refund is due, no extra fare.
      final perKm = ReturnSettlementService.perKmSettlementFor(
        booking: booking,
        totalKmDriven: 50,
        pricing: const PerKmPricing(),
      );
      expect(perKm!.extraDue, 0);
      expect(perKm.refundDue, 4000);
      final settled = await finalizePerKm(
        booking: booking,
        totalKmDriven: 50,
      );
      expect(settled.totalAmount, 9000);
      expect(settled.advancePaid, 9000);
      expect(settled.remainingBalance, 0);
      final entries =
          await bookingEntries(shopId, booking.bookingId);
      expect(
          entries.where((t) =>
              t.transferId == 'LEDGER-${booking.bookingId}-extra-fare'),
          isEmpty);
    });
  });

  group('ReturnFarePaymentSection — extra fare row', () {
    Future<void> pumpSection(
      WidgetTester tester, {
      required int extraFareDue,
      required void Function(int amount, String? method) onExtra,
    }) async {
      final booking = _booking(
          id: 'RH-XF-W',
          shopId: 'shop-xf-w',
          total: 9000,
          advancePaid: 3000,
          status: 'paid');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReturnFarePaymentSection(
                booking: booking,
                onCollected: (_, __) {},
                extraFareDue: extraFareDue,
                onExtraFareCollected: onExtra,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the extra-fare row and counts it in Total Due',
        (tester) async {
      await pumpSection(tester, extraFareDue: 5000, onExtra: (_, __) {});
      expect(find.text('Extra Fare (per-km)'), findsOneWidget);
      expect(find.text('Extra fare due'), findsOneWidget);
      expect(find.text('Rs. 5,000'), findsOneWidget);
      expect(find.text('Rs. 11,000'), findsOneWidget);
    });

    testWidgets('marking the extra fare received reports it and updates due',
        (tester) async {
      var reported = (amount: 0, method: '');
      await pumpSection(tester,
          extraFareDue: 5000,
          onExtra: (amount, method) =>
              reported = (amount: amount, method: method ?? ''));
      await tester.ensureVisible(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      expect(reported.amount, 5000);
      expect(reported.method, 'cash');
      expect(find.text('Extra Fare Received'), findsOneWidget);
      // Total Due is now just the uncollected remaining rent — the
      // same Rs. 6,000 also shows in the Remaining row.
      expect(find.text('Rs. 6,000'), findsNWidgets(2));
    });

    testWidgets('the picked method is reported with the collection',
        (tester) async {
      var reported = (amount: 0, method: '');
      await pumpSection(tester,
          extraFareDue: 5000,
          onExtra: (amount, method) =>
              reported = (amount: amount, method: method ?? ''));
      await tester.ensureVisible(find.text('JazzCash').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('JazzCash').last);
      await tester.pump();
      await tester.ensureVisible(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      expect(reported, (amount: 5000, method: 'jazzcash'));
    });

    testWidgets('an amount over the due clamps to the due', (tester) async {
      var reported = (amount: 0, method: '');
      await pumpSection(tester,
          extraFareDue: 5000,
          onExtra: (amount, method) =>
              reported = (amount: amount, method: method ?? ''));
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '999999');
      await tester.ensureVisible(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      expect(reported.amount, 5000);
    });

    testWidgets('undo clears the extra-fare collection', (tester) async {
      final calls = <(int, String?)>[];
      await pumpSection(tester,
          extraFareDue: 5000, onExtra: (a, m) => calls.add((a, m)));
      await tester.ensureVisible(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Payment Received').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Undo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo').last);
      await tester.pumpAndSettle();
      expect(calls, [(5000, 'cash'), (0, null)]);
      expect(find.text('Rs. 11,000'), findsOneWidget);
    });

    testWidgets('zero extra fare shows no row', (tester) async {
      await pumpSection(tester, extraFareDue: 0, onExtra: (_, __) {});
      expect(find.text('Extra Fare (per-km)'), findsNothing);
      expect(find.text('Extra fare due'), findsNothing);
      expect(find.text('Rs. 6,000'), findsNWidgets(2));
    });
  });
}

VehicleEntity _testVehicle() => const VehicleEntity(
      vehicleId: 'veh-walkin-audit',
      shopId: 'shop-1',
      make: 'Toyota',
      model: 'Corolla',
      year: 2022,
      plateNumber: 'LEA-22-0001',
      rates: VehicleRatesEntity(daily24: 9000),
      status: 'available',
      securityDepositPkr: 20000,
      advanceRequiredPkr: 3000,
      packages: [
        VehiclePackageEntity(
          label: '24h',
          hours: 24,
          pricePkr: 9000,
          kmIncluded: 250,
        ),
      ],
    );
