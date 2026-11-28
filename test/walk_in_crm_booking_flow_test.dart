import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/utils/booking_next_step.dart';
import 'package:rentalhub/features/finance/utils/settlement_calculator.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_detail_bookings_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/return_late_fee_section.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  BookingEntity booking({
    String id = 'WI-1',
    String status = 'approved',
    String? origin = 'walk_in',
    int totalAmount = 10000,
    int advanceRequired = 3000,
    int advancePaid = 0,
  }) =>
      BookingEntity(
        bookingId: id,
        customerId: 'walkin-cust-1',
        shopId: 'shop-wi-test',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 28, 10),
        returnTime: DateTime(2026, 11, 29, 10),
        totalAmount: totalAmount,
        advanceRequired: advanceRequired,
        advancePaid: advancePaid,
        remainingBalance: totalAmount - advancePaid,
        status: status,
        origin: origin,
        customerName: 'Walk-in Bilal',
        customerPhone: '03001234567',
        vehicleName: 'Toyota Corolla',
      );

  group('Walk-in booking owner-only flow', () {
    test('resolveOwnerNextStep routes approved walk-in to recordPayment', () {
      final walkIn = booking(status: 'approved', origin: 'walk_in');
      expect(resolveOwnerNextStep(walkIn).kind,
          BookingNextStepKind.recordPayment);

      final online = booking(status: 'approved', origin: 'online');
      expect(resolveOwnerNextStep(online).kind, BookingNextStepKind.none);
    });

    test('recordOwnerPayment adds balance and promotes approved -> paid',
        () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'walkin-pay-1',
        shopId: 'shop-wi-pay',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 28, 10),
        returnTime: DateTime(2026, 11, 29, 10),
        totalAmount: 10000,
        advanceRequired: 3000,
        origin: 'walk_in',
        customerName: 'Walk-in Cash',
      );
      final approved = await ds.recordAdvancePayment(
        bookingId: created.bookingId,
        advanceAmount: 0,
      );
      expect(approved.status, 'approved');
      expect(approved.remainingBalance, 10000);

      final updated = await WalkInBookingService.recordOwnerPayment(
        booking: approved,
        amount: 3000,
        paymentMethod: 'cash',
      );
      expect(updated.status, 'paid');
      expect(updated.advancePaid, 3000);
      expect(updated.remainingBalance, 7000);
    });

    test('SettlementCalculator applies overtimeFeeOverride when provided', () {
      final autoZero = SettlementCalculator.calculate(
        totalKmDriven: 100,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        overtimeHours: 3,
        extraHourPkr: 0,
        securityDeposit: 15000,
      );
      expect(autoZero.overtimeFee, 0);

      final overridden = SettlementCalculator.calculate(
        totalKmDriven: 100,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        overtimeHours: 3,
        extraHourPkr: 0,
        overtimeFeeOverride: 2500,
        securityDeposit: 15000,
      );
      expect(overridden.overtimeFee, 2500);
      expect(overridden.totalDeductions, 2500);
      expect(overridden.netRefund, 12500);
    });

    testWidgets('ReturnLateFeeSection shows overdue hours and editable input',
        (tester) async {
      final controller = TextEditingController(text: '1500');
      addTearDown(controller.dispose);
      String? lastValue;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReturnLateFeeSection(
              overtimeHours: 3,
              extraHourPkr: 500,
              controller: controller,
              onChanged: (v) => lastValue = v,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Late Fee'), findsOneWidget);
      expect(find.text('Late by 3h'), findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('return_late_fee_field')), '2000');
      expect(lastValue, '2000');
    });

    testWidgets(
        'CustomerDetailBookingsSection shows status filters, badges and next steps',
        (tester) async {
      final bookings = [
        booking(id: 'B-APR', status: 'approved', advancePaid: 0),
        booking(id: 'B-ACT', status: 'active', advancePaid: 5000),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: SingleChildScrollView(
                child: CustomerDetailBookingsSection(bookings: bookings),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Approved (1)'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Add Payment'), findsNWidgets(2));
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Proceed to Return & Settlement'), findsOneWidget);

      await tester.tap(find.text('Active (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Proceed to Return & Settlement'), findsOneWidget);
      expect(find.text('Start Handover'), findsNothing);
    });
  });
}
