import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_category_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_settings_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/staff_data_source.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_account_entity.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_settings_entity.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_transfer_entity.dart';
import 'package:rentalhub/features/finance/utils/finance_summary.dart';
import 'package:rentalhub/features/finance/utils/statement_pdf_generator.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_statement_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_finance_categories_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_finance_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_reports_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_reset_options_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_signed_out_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_staff_roles_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/add_transfer_sheet.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_kpis.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/bars_chart_widget.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/finance_summary_cards.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Audit impl (worker C): dashboard + finance + reports +
// categories / reset / staff. Run by the integration worker after
// the registrar adds the routes and .arb keys this build needs.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('category totals', () {
    test('sums per category code inside a kind', () {
      FinanceTransferEntity transfer(String id, String kind, String cat,
              int amount) =>
          FinanceTransferEntity(
            transferId: id,
            shopId: 'shop-c',
            accountId: 'acc-1',
            kind: kind,
            category: cat,
            amountPkr: amount,
            createdAt: DateTime(2026, 11, 9, 10),
          );
      final totals = FinanceSummary.categoryTotals([
        transfer('t1', 'income', 'rent', 10000),
        transfer('t2', 'income', 'advance', 5000),
        transfer('t3', 'income', 'rent', 2000),
        transfer('t4', 'expense', 'wash', 1500),
        transfer('t5', 'expense', 'fuel', 3000),
      ], kind: 'income');
      expect(totals['rent'], 12000);
      expect(totals['advance'], 5000);
      expect(totals.containsKey('wash'), isFalse);
      final expenses = FinanceSummary.categoryTotals([
        transfer('t4', 'expense', 'wash', 1500),
        transfer('t5', 'expense', 'fuel', 3000),
      ], kind: 'expense');
      expect(expenses['wash'], 1500);
      expect(expenses['fuel'], 3000);
    });
  });

  group('finance categories data source', () {
    test('seeds the old hardcoded lists, including advance and wash',
        () async {
      final ds = FinanceCategoryDataSource();
      final income =
          await ds.getShopCategories('shop-cat', kind: 'income');
      final expense =
          await ds.getShopCategories('shop-cat', kind: 'expense');
      expect(income.map((c) => c.code), contains('advance'));
      expect(expense.map((c) => c.code), contains('wash'));
      expect(income.map((c) => c.code), contains('rent'));
      expect(expense.map((c) => c.code), contains('fuel'));
    });

    test('add, rename and delete round-trip', () async {
      final ds = FinanceCategoryDataSource();
      final added = await ds.addCategory(
          shopId: 'shop-cat2', kind: 'expense', name: 'Tyres');
      expect(added.code, 'tyres');
      await ds.renameCategory(added.categoryId, 'Tires');
      final afterRename = await ds.getShopCategories('shop-cat2',
          kind: 'expense');
      expect(afterRename.map((c) => c.name), contains('Tires'));
      await ds.deleteCategory(added.categoryId);
      final afterDelete = await ds.getShopCategories('shop-cat2',
          kind: 'expense');
      expect(afterDelete.map((c) => c.code), isNot(contains('tyres')));
    });
  });

  group('finance settings data source', () {
    test('defaults are PKR with cash and bank on', () async {
      final ds = FinanceSettingsDataSource();
      final settings = await ds.getSettings('shop-set');
      expect(settings.currency, 'PKR');
      expect(settings.paymentCash, isTrue);
      expect(settings.paymentBankTransfer, isTrue);
      expect(settings.autoSendReceipt, isFalse);
    });

    test('save round-trips tax and toggles', () async {
      final ds = FinanceSettingsDataSource();
      await ds.saveSettings(const FinanceSettingsEntity(
        shopId: 'shop-set2',
        taxPercent: 5,
        paymentJazzCash: true,
        autoSendReceipt: true,
      ));
      final saved = await ds.getSettings('shop-set2');
      expect(saved.taxPercent, 5);
      expect(saved.paymentJazzCash, isTrue);
      expect(saved.autoSendReceipt, isTrue);
    });
  });

  group('staff data source', () {
    test('add, list and permission toggles round-trip', () async {
      final ds = StaffDataSource();
      final added = await ds.addStaff(
        shopId: 'shop-staff',
        name: 'Bilal',
        role: 'Manager',
        phone: '03001234567',
        manageFinance: true,
      );
      final staff = await ds.getShopStaff('shop-staff');
      expect(staff.map((s) => s.name), contains('Bilal'));
      expect(staff.first.manageFinance, isTrue);
      expect(staff.first.viewBookings, isTrue);
      await ds.updatePermissions(
        staffId: added.staffId,
        viewBookings: false,
        addCars: true,
        manageFinance: true,
      );
      final updated = await ds.getShopStaff('shop-staff');
      expect(updated.first.viewBookings, isFalse);
      expect(updated.first.addCars, isTrue);
      await ds.deleteStaff(added.staffId);
      expect(await ds.getShopStaff('shop-staff'), isEmpty);
    });
  });

  group('ledger entry with payment method and booking link', () {
    test('addTransfer stores paymentMethod, bookingId and date',
        () async {
      final ds = di.sl<FinanceTransferDataSource>();
      final saved = await ds.addTransfer(
        shopId: 'shop-pay',
        accountId: 'acc-1',
        kind: 'income',
        category: 'advance',
        amountPkr: 5000,
        bookingId: 'BK-1',
        paymentMethod: 'jazzcash',
        createdAt: DateTime(2026, 11, 9, 9),
      );
      expect(saved.paymentMethod, 'jazzcash');
      expect(saved.bookingId, 'BK-1');
      final all = await ds.getShopTransfers('shop-pay');
      expect(all.map((t) => t.transferId), contains(saved.transferId));
    });
  });

  group('statement PDF', () {
    test('generates non-empty A4 bytes for a customer', () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-stmt',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic',
        customerName: 'Statement Customer',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      final bytes = await StatementPdfGenerator.generateCustomerStatement(
        shopName: 'Test Shop',
        customerName: 'Statement Customer',
        customerPhone: '03001234567',
        bookings: [booking],
      );
      expect(bytes.isNotEmpty, isTrue);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('dashboard and finance widgets', () {
    testWidgets('dashboard KPIs show today earnings', (tester) async {
      await tester.pumpWidget(wrap(const DashboardKpis(
        totalRevenue: 100000,
        todayEarnings: 21000,
        growthLabel: 'No revenue last month',
        activeCount: 2,
        completedCount: 3,
        settleLabel: 'No completed trips yet',
        waitingCount: 1,
        fleetAvailable: 4,
        fleetTotal: 5,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 21,000'), findsOneWidget);
      expect(find.text('Rs. 100,000'), findsOneWidget);
    });

    testWidgets('summary cards show earnings, expenses and net',
        (tester) async {
      await tester.pumpWidget(
          wrap(const FinanceSummaryCards(earnings: 185000, expenses: 45000)));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 185,000'), findsOneWidget);
      expect(find.text('Rs. 45,000'), findsOneWidget);
      expect(find.text('Rs. 140,000'), findsOneWidget);
    });

    testWidgets('bars chart renders values', (tester) async {
      await tester.pumpWidget(wrap(const BarsChartWidget(
        labels: ['Jan', 'Feb'],
        values: [10000, 20000],
      )));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 10,000'), findsOneWidget);
      expect(find.text('Rs. 20,000'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
    });

    testWidgets('categories view lists seeded categories', (tester) async {
      await tester.pumpWidget(
          wrap(const OwnerFinanceCategoriesView(shopId: 'shop-cat3')));
      await tester.pumpAndSettle();
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Wash'), findsOneWidget);
      expect(find.text('Advance'), findsOneWidget);
    });

    testWidgets('finance settings view shows PKR currency',
        (tester) async {
      await tester.pumpWidget(
          wrap(const OwnerFinanceSettingsView(shopId: 'shop-set3')));
      await tester.pumpAndSettle();
      expect(find.text('PKR'), findsOneWidget);
    });

    testWidgets('staff view shows empty state', (tester) async {
      await tester.pumpWidget(
          wrap(const OwnerStaffRolesView(shopId: 'shop-staff2')));
      await tester.pumpAndSettle();
      expect(find.text('No staff yet — add your first team member.'),
          findsOneWidget);
    });

    testWidgets('reset view lists all four options', (tester) async {
      await tester.pumpWidget(
          wrap(const OwnerResetOptionsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      expect(find.text('Reset Bookings'), findsOneWidget);
      expect(find.text('Reset Customers'), findsOneWidget);
      expect(find.text('Reset Cars'), findsOneWidget);
      expect(find.text('Reset All Data'), findsOneWidget);
    });

    testWidgets('signed-out view offers sign in again', (tester) async {
      await tester.pumpWidget(wrap(const OwnerSignedOutView()));
      await tester.pumpAndSettle();
      // The title renders twice by design: MinimalAppBar title + the
      // centred body heading.
      expect(find.text('You have been signed out'), findsNWidgets(2));
      expect(find.text('Sign In Again'), findsOneWidget);
    });

    testWidgets('reports view shows report cards', (tester) async {
      await tester.pumpWidget(wrap(const OwnerReportsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Earnings Report'), findsOneWidget);
      expect(find.text('Car-wise Earnings'), findsOneWidget);
      expect(find.text('Customer History'), findsOneWidget);
    });

    testWidgets('statement view shows the customer total due',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-stmt2',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic',
        customerName: 'Statement Customer 2',
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
      await tester.pumpWidget(wrap(OwnerCustomerStatementView(
        shopId: 'shop-1',
        customerId: 'cust-stmt2',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Statement Customer 2'), findsWidgets);
      expect(find.text('Rs. 9,000'), findsWidgets);
    });
  });

  group('add transfer sheet', () {
    testWidgets('shows date, payment method and booking number fields',
        (tester) async {
      const account = FinanceAccountEntity(
        accountId: 'acc-1',
        shopId: 'shop-1',
        name: 'Cash in Hand',
        type: 'cash',
        isDefault: true,
      );
      await tester.pumpWidget(wrap(const AddTransferSheetTestHost(
        account: account,
      )));
      await tester.pumpAndSettle();
      // The sheet opens from the host button, like the finance hub does.
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Add ledger entry'), findsOneWidget);
      expect(find.text('Booking #'), findsOneWidget);
      expect(find.text('Payment method'), findsOneWidget);
    });
  });
}

/// The add-entry sheet is a dialog; host it behind a button so the
/// test pumps it the way the finance hub does.
class AddTransferSheetTestHost extends StatelessWidget {
  final FinanceAccountEntity account;

  const AddTransferSheetTestHost({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddTransferSheet(
                shopId: 'shop-1',
                accounts: [account],
                vehicles: const [],
                onSaved: () {},
              ),
            );
          },
          child: const Text('Open sheet'),
        ),
      ),
    );
  }
}
