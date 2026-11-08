import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/finance/data/datasources/cash_closing_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_account_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/partner_share_data_source.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_account_entity.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_transfer_entity.dart';
import 'package:rentalhub/features/finance/utils/finance_summary.dart';
import 'package:rentalhub/features/finance/utils/pnl_csv.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_car_pnl_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_cash_closing_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dues_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_finance_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase H — finance arithmetic', () {
    const account = FinanceAccountEntity(
      accountId: 'acc-1',
      shopId: 'shop-h',
      name: 'Cash in Hand',
      type: 'cash',
      openingBalancePkr: 10000,
    );
    FinanceTransferEntity transfer({
      required String id,
      required String kind,
      required int amount,
      String? vehicleId,
      DateTime? at,
    }) =>
        FinanceTransferEntity(
          transferId: id,
          shopId: 'shop-h',
          accountId: 'acc-1',
          kind: kind,
          category: 'rent',
          amountPkr: amount,
          vehicleId: vehicleId,
          createdAt: at ?? DateTime(2026, 11, 6, 10),
        );

    test('account balance is opening plus transfers', () {
      final balance = FinanceSummary.accountBalance(account, [
        transfer(id: 't1', kind: 'income', amount: 9000),
        transfer(id: 't2', kind: 'expense', amount: 2000),
      ]);
      expect(balance, 17000);
    });

    test('period totals respect the date range', () {
      final totals = FinanceSummary.periodTotals(
        [
          transfer(
              id: 't1', kind: 'income', amount: 9000, at: DateTime(2026, 11, 5)),
          transfer(
              id: 't2', kind: 'expense', amount: 2000, at: DateTime(2026, 10, 5)),
        ],
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 12, 1),
      );
      expect(totals.income, 9000);
      expect(totals.expenses, 0);
      expect(totals.net, 9000);
    });

    test('vehicle P&L mixes booking revenue and tagged transfers', () {
      final pnl = FinanceSummary.vehiclePnL(
        vehicleId: 'v1',
        bookings: [
          BookingEntity(
            bookingId: 'RH-H-1',
            customerId: 'c1',
            shopId: 'shop-h',
            vehicleId: 'v1',
            packageType: '24h',
            isWithDriver: false,
            pickupTime: DateTime(2026, 11, 5),
            returnTime: DateTime(2026, 11, 6),
            totalAmount: 9000,
            advanceRequired: 3000,
            advancePaid: 9000,
            remainingBalance: 0,
            status: 'completed',
          ),
        ],
        transfers: [
          transfer(id: 't1', kind: 'expense', amount: 1500, vehicleId: 'v1'),
          transfer(id: 't2', kind: 'income', amount: 500, vehicleId: 'v1'),
          transfer(id: 't3', kind: 'expense', amount: 9999, vehicleId: 'v2'),
        ],
      );
      expect(pnl.revenue, 9000);
      expect(pnl.income, 500);
      expect(pnl.expenses, 1500);
      expect(pnl.net, 8000);
    });

    test('P&L CSV carries the totals and the ledger lines', () {
      final csv = PnLCsv.build(
        shopName: 'Test Shop',
        periodLabel: 'This month',
        bookingRevenue: 9000,
        ledgerIncome: 500,
        expenses: 1500,
        transfers: [
          transfer(id: 't1', kind: 'expense', amount: 1500),
        ],
      );
      expect(csv, contains('RentalHub P&L Statement,Test Shop,This month'));
      expect(csv, contains('Net profit,8000'));
      expect(csv, contains('expense,rent,1500'));
    });
  });

  group('Phase H — finance data layer', () {
    test('accounts seed cash, transfers validate, partners and closings save',
        () async {
      final accounts = FinanceAccountDataSource();
      final mine = await accounts.getShopAccounts('shop-h2');
      expect(mine.length, 1);
      expect(mine.first.name, 'Cash in Hand');
      expect(mine.first.isDefault, isTrue);

      final saved = await accounts.saveAccount(
        shopId: 'shop-h2',
        name: 'Meezan 1234',
        type: 'bank',
        openingBalancePkr: 50000,
      );
      expect(saved.type, 'bank');
      expect((await accounts.getShopAccounts('shop-h2')).length, 2);
      expect(
        () => accounts.saveAccount(
            shopId: 'shop-h2', name: 'X', type: 'crypto'),
        throwsArgumentError,
      );

      final transfers = FinanceTransferDataSource();
      expect(
        () => transfers.addTransfer(
          shopId: 'shop-h2',
          accountId: mine.first.accountId,
          kind: 'income',
          category: 'rent',
          amountPkr: 0,
        ),
        throwsArgumentError,
      );
      await transfers.addTransfer(
        shopId: 'shop-h2',
        accountId: mine.first.accountId,
        kind: 'income',
        category: 'rent',
        amountPkr: 9000,
        vehicleId: 'v1',
      );
      expect((await transfers.getShopTransfers('shop-h2')).length, 1);
      expect((await transfers.getVehicleTransfers('v1')).length, 1);
      expect((await transfers.getVehicleTransfers('v2')).length, 0);

      final partners = PartnerShareDataSource();
      await partners.savePartner(
          shopId: 'shop-h2', partnerName: 'Bilal', sharePercent: 30);
      expect((await partners.getShopPartners('shop-h2')).length, 1);
      expect(
        () => partners.savePartner(
            shopId: 'shop-h2', partnerName: 'X', sharePercent: 150),
        throwsArgumentError,
      );

      final closings = CashClosingDataSource();
      final first = await closings.saveClosing(
        shopId: 'shop-h2',
        date: DateTime(2026, 11, 6),
        openingCash: 10000,
        expectedCash: 19000,
        countedCash: 18500,
      );
      expect(first.difference, -500);
      // A second close on the same day replaces the first.
      await closings.saveClosing(
        shopId: 'shop-h2',
        date: DateTime(2026, 11, 6),
        openingCash: 10000,
        expectedCash: 19000,
        countedCash: 19000,
      );
      final list = await closings.getShopClosings('shop-h2');
      expect(list.length, 1);
      expect(list.first.difference, 0);
    });
  });

  group('Phase H — finance views', () {
    testWidgets('finance hub shows the seeded cash account and ledger',
        (tester) async {
      final accountsDs = di.sl<FinanceAccountDataSource>();
      final accounts = await accountsDs.getShopAccounts('shop-1');
      final cash =
          accounts.where((a) => a.type == 'cash').first;
      await di.sl<FinanceTransferDataSource>().addTransfer(
        shopId: 'shop-1',
        accountId: cash.accountId,
        kind: 'income',
        category: 'rent',
        amountPkr: 7777,
        note: 'H-test',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerFinanceView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Cash in Hand'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Rs. 7777'), findsWidgets);
    });

    testWidgets('dues view lists unpaid balances', (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-h-dues',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic',
        customerName: 'Dues Customer',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.updateBookingStatus(
          bookingId: booking.bookingId, status: 'paid');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerDuesView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dues Customer'), findsOneWidget);
      expect(find.text('Rs. 9000'), findsWidgets);
    });

    testWidgets('cash closing saves the counted cash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerCashClosingView(shopId: 'shop-h3'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Expected in till today'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Counted cash (Rs.)'), '5000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close the day'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Diff Rs. 5000'), findsWidgets);
    });

    testWidgets('car P&L picks a vehicle and shows its net', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerCarPnLView(shopId: 'shop-basic'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.textContaining('Net Rs.'), findsOneWidget);
    });
  });

  group('Phase H — routing', () {
    test('finance routes are wired', () {
      final router =
          File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(router, contains('OwnerFinanceView'));
      expect(router, contains('OwnerDuesView'));
      expect(router, contains('OwnerCashClosingView'));
      expect(router, contains('OwnerCarPnLView'));
      final names =
          File('lib/core/routing/route_names.dart').readAsStringSync();
      expect(names, contains("ownerFinance = '/owner/finance'"));
      expect(names, contains("ownerDues = '/owner/finance/dues'"));
      expect(names,
          contains("ownerCashClosing = '/owner/finance/closing'"));
      expect(names, contains("ownerCarPnL = '/owner/finance/car'"));
    });
  });
}
