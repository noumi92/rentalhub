import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/widgets/app_state_views.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/finance/data/models/security_deposit_model.dart';
import 'package:rentalhub/features/finance/domain/entities/security_deposit_entity.dart';
import 'package:rentalhub/features/finance/utils/settlement_calculator.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_settlement_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase F (F1) — settlement calculator', () {
    test('within allowance and full fuel refunds the whole deposit', () {
      final b = SettlementCalculator.calculate(
        totalKmDriven: 200,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        extraHourPkr: 600,
        securityDeposit: 20000,
      );
      expect(b.excessKm, 0);
      expect(b.excessKmCharge, 0);
      expect(b.fuelDeficit, 0);
      expect(b.totalDeductions, 0);
      expect(b.netRefund, 20000);
    });

    test('excess kilometres charge at the vehicle rate', () {
      final b = SettlementCalculator.calculate(
        totalKmDriven: 350,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        extraHourPkr: 600,
        securityDeposit: 20000,
      );
      expect(b.excessKm, 100);
      expect(b.excessKmCharge, 10000);
      expect(b.netRefund, 10000);
    });

    test('fuel deficit follows the gauge', () {
      int deficit(String fuel) => SettlementCalculator.calculate(
            totalKmDriven: 0,
            kmAllowance: 250,
            extraKmPkr: 100,
            fuelLevel: fuel,
            extraHourPkr: 600,
            securityDeposit: 20000,
          ).fuelDeficit;
      expect(deficit('4/4 (Full)'), 0);
      expect(deficit('3/4 (75%)'), 1500);
      expect(deficit('2/4 (50%)'), 3000);
      expect(deficit('1/4 (25%)'), 4500);
    });

    test('overtime and damage add up, refund never goes below zero', () {
      final b = SettlementCalculator.calculate(
        totalKmDriven: 400,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '2/4 (50%)',
        damageCharge: 5000,
        overtimeHours: 2,
        extraHourPkr: 600,
        securityDeposit: 20000,
      );
      // 15000 excess + 3000 fuel + 5000 damage + 1200 overtime = 24200
      expect(b.totalDeductions, 24200);
      expect(b.netRefund, 0);
    });
  });

  group('Phase F (F2) — security deposits', () {
    test('collect is idempotent, settle releases or deducts', () async {
      final ds = SecurityDepositDataSource();
      final collected = await ds.collect(
        bookingId: 'RH-F2-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 20000,
      );
      expect(collected.status, 'collected');
      expect(collected.collectedAt, isNotNull);

      final again = await ds.collect(
        bookingId: 'RH-F2-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 20000,
      );
      expect(again.collectedAt, collected.collectedAt);

      final settled = await ds.settle(
        bookingId: 'RH-F2-1',
        totalKmDriven: 350,
        excessKm: 100,
        excessKmCharge: 10000,
        fuelDeficit: 0,
        damageCharge: 0,
        overtimeFee: 0,
        deductedAmount: 10000,
        netRefund: 10000,
      );
      expect(settled.status, 'deducted');
      expect(settled.deductedAt, isNotNull);
      expect(settled.releasedAt, isNull);
      expect(settled.netRefund, 10000);
      expect(settled.excessKm, 100);

      final full = await ds.collect(
        bookingId: 'RH-F2-2',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 15000,
      );
      final released = await ds.settle(
        bookingId: 'RH-F2-2',
        totalKmDriven: 100,
        excessKm: 0,
        excessKmCharge: 0,
        fuelDeficit: 0,
        damageCharge: 0,
        overtimeFee: 0,
        deductedAmount: 0,
        netRefund: 15000,
      );
      expect(released.status, 'released');
      expect(released.releasedAt, isNotNull);
      expect(full.status, 'collected');
    });

    test('settling an unknown booking throws', () async {
      final ds = SecurityDepositDataSource();
      expect(
        ds.settle(
          bookingId: 'RH-F2-unknown',
          totalKmDriven: 0,
          excessKm: 0,
          excessKmCharge: 0,
          fuelDeficit: 0,
          damageCharge: 0,
          overtimeFee: 0,
          deductedAmount: 0,
          netRefund: 0,
        ),
        throwsStateError,
      );
    });

    test('model round-trips through toMap/fromMap', () {
      const entity = SecurityDepositEntity(
        depositId: 'RH-F2-3',
        bookingId: 'RH-F2-3',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 20000,
        status: 'deducted',
        deductedAmount: 5000,
        netRefund: 15000,
        returnDamageNotes: ['Scratch on bumper'],
      );
      final map = SecurityDepositModel.fromEntity(entity).toMap();
      final back = SecurityDepositModel.fromMap(map);
      expect(back.status, 'deducted');
      expect(back.deductedAmount, 5000);
      expect(back.netRefund, 15000);
      expect(back.returnDamageNotes, ['Scratch on bumper']);
    });
  });

  group('Phase F (F1/F2) — return view settles for real', () {
    testWidgets('finalizing writes the deposit and completes the booking',
        (tester) async {
      final bookingDs = di.sl<BookingRemoteDataSource>();
      final booking = await bookingDs.createBookingRequest(
        customerId: 'cust-f1',
        shopId: 'shop-basic',
        vehicleId: 'v1',
        vehicleName: 'Honda Civic Oriel 2021',
        customerName: 'Return Me',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now().subtract(const Duration(days: 1)),
        returnTime: DateTime.now().subtract(const Duration(hours: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
        kmLimit: 250,
      );
      await bookingDs.updateBookingStatus(
          bookingId: booking.bookingId, status: 'active');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerReturnSettlementView(
            booking: booking,
            initialOdometer: 45200,
            kmAllowance: 250,
            initialDeposit: 20000,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drive 350 km: 100 excess at the fallback Rs. 100/km.
      await tester.enterText(find.byType(TextField).first, '45550');
      await tester.pumpAndSettle();
      expect(find.text('350 KM'), findsOneWidget);

      await tester.ensureVisible(
          find.text('Finalize Return & Settle Deposit'));
      await tester.tap(find.text('Finalize Return & Settle Deposit'));
      await tester.pumpAndSettle();

      final done =
          await bookingDs.getBookingById(booking.bookingId);
      expect(done?.status, 'completed');

      final deposit = await di
          .sl<SecurityDepositDataSource>()
          .getByBookingId(booking.bookingId);
      expect(deposit, isNotNull);
      expect(deposit!.status, 'deducted');
      expect(deposit.excessKm, 100);
      expect(deposit.netRefund, 10000);

      final vehicles = await di
          .sl<FleetRemoteDataSource>()
          .getShopVehicles('shop-basic');
      final vehicle =
          vehicles.firstWhere((v) => v.vehicleId == 'v1');
      expect(vehicle.status, 'available');
      expect(vehicle.mileageKm, 45550);
    });

    testWidgets(
        'Finalize is not rendered until the real values load (audit §14)',
        (tester) async {
      final bookingDs = di.sl<BookingRemoteDataSource>();
      final booking = await bookingDs.createBookingRequest(
        customerId: 'cust-f1-gate',
        shopId: 'shop-basic',
        vehicleId: 'v1',
        vehicleName: 'Honda Civic Oriel 2021',
        customerName: 'Gate Check',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now().subtract(const Duration(days: 1)),
        returnTime: DateTime.now().subtract(const Duration(hours: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
        kmLimit: 250,
      );
      await bookingDs.updateBookingStatus(
          bookingId: booking.bookingId, status: 'active');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerReturnSettlementView(
            booking: booking,
            initialOdometer: 45200,
            kmAllowance: 250,
            initialDeposit: 20000,
          ),
        ),
      );
      // No settle: the real-values load is still in flight, so the
      // form — and its Finalize button — must not be rendered yet.
      // The old code settled against 45200 / 250 km / Rs. 15,000
      // fallbacks while the load was pending.
      expect(find.text('Finalize Return & Settle Deposit'), findsNothing);
      expect(find.byType(AppLoadingState), findsOneWidget);

      // Once the load lands the button appears and the booking can
      // be settled; it must still be 'active' — nothing settled early.
      await tester.pumpAndSettle();
      expect(find.text('Finalize Return & Settle Deposit'), findsOneWidget);
      final stillActive =
          await bookingDs.getBookingById(booking.bookingId);
      expect(stillActive?.status, 'active');
    });
  });
}
