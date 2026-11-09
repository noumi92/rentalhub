// Regression test for the phone-reported "add ledger entry alert text
// overflows" (run #50 APK, fixed 2026-11-09). Pumps AddTransferSheet (an
// AlertDialog) at phone size, switches to expense, opens the dropdowns, and
// fails on any overflow exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_account_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/add_transfer_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  testWidgets('add ledger entry dialog: no overflow (en + expense)',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const accounts = [
      FinanceAccountEntity(
        accountId: 'acc-cash',
        shopId: 'shop-1',
        name: 'Cash in Hand',
        type: 'cash',
        isDefault: true,
        openingBalancePkr: 0,
      ),
    ];
    final vehicles = [
      VehicleEntity(
        vehicleId: 'v-1',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Altis 1.8 Grande CVT-i',
        year: 2023,
        plateNumber: 'LEA-23-4567',
        rates: const VehicleRatesEntity(daily24: 8500),
        status: 'available',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddTransferSheet(
                    shopId: 'shop-1',
                    accounts: accounts,
                    vehicles: vehicles,
                    onSaved: () {},
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER OPEN exception: ${tester.takeException()}');
    expect(find.text('Add ledger entry'), findsOneWidget);

    // Switch to expense (longest category list).
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER EXPENSE exception: ${tester.takeException()}');

    // Open the category dropdown (tap the selected value) and pick the
    // longest label.
    await tester.tap(find.text('Fuel'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER CATEGORY OPEN exception: ${tester.takeException()}');
    await tester.tap(find.text('Partner share').last);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER CATEGORY PICK exception: ${tester.takeException()}');

    // Open the vehicle dropdown (long display name) and pick it.
    // Audit impl (worker C): the taller sheet keeps the dropdown
    // below the fold — scroll it into view before tapping.
    await tester.ensureVisible(find.text('No vehicle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No vehicle'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER VEHICLE OPEN exception: ${tester.takeException()}');
    await tester.tap(find.textContaining('Corolla Altis').last);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER VEHICLE PICK exception: ${tester.takeException()}');

    // Final state: dialog still up, no overflow.
    expect(find.text('Add ledger entry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
