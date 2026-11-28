import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/utils/booking_next_step.dart';
import 'package:rentalhub/features/finance/utils/settlement_calculator.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_wizard_cubit.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/handover_balance_section.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// Rigorous end-to-end audit test verifying step-wise data flow,
/// approvals, payment-proof downgrade guards, handover payment dropdown
/// & editable security deposit checks, and button integrity across both
/// Online and Walk-in booking pipelines.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('1. Online booking pipeline — end-to-end data & next-step integrity',
      () {
    test('requested -> approved -> payment_submitted -> paid -> active -> completed',
        () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final pickup = DateTime(2026, 11, 28, 10);
      final ret = DateTime(2026, 11, 30, 10);

      // Step 1: Customer creates online booking request
      final requested = await ds.createBookingRequest(
        customerId: 'audit-online-cust-1',
        shopId: 'audit-shop-1',
        vehicleId: 'audit-veh-1',
        vehicleName: 'Honda Civic Oriel',
        customerName: 'Ayesha Tariq',
        customerPhone: '03001234567',
        origin: 'online',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: pickup,
        returnTime: ret,
        totalAmount: 20000,
        advanceRequired: 5000,
      );
      expect(requested.status, 'requested');
      expect(requested.advancePaid, 0);
      expect(requested.remainingBalance, 20000);
      expect(resolveOwnerNextStep(requested).kind, BookingNextStepKind.approve);
      expect(resolveCustomerNextStep(requested).kind, BookingNextStepKind.none);

      // Step 2: Owner approves booking
      final approved = await ds.updateBookingStatus(
        bookingId: requested.bookingId,
        status: 'approved',
      );
      expect(approved.status, 'approved');
      expect(resolveOwnerNextStep(approved).kind, BookingNextStepKind.none);
      expect(resolveCustomerNextStep(approved).kind,
          BookingNextStepKind.payAdvance);

      // Step 3: Customer submits payment proof
      final submitted = await ds.updatePaymentProof(
        bookingId: approved.bookingId,
        paymentProofUrl: 'https://cdn.example/proofs/audit-1.jpg',
        transactionId: 'TRX-AUDIT-001',
      );
      expect(submitted.status, 'payment_submitted');
      expect(submitted.transactionId, 'TRX-AUDIT-001');
      expect(resolveOwnerNextStep(submitted).kind,
          BookingNextStepKind.verifyProof);
      expect(resolveCustomerNextStep(submitted).kind, BookingNextStepKind.none);

      // Step 4: Owner verifies payment -> paid
      final paid = await ds.verifyPayment(
        bookingId: submitted.bookingId,
        advanceAmount: 5000,
      );
      expect(paid.status, 'paid');
      expect(paid.advancePaid, 5000);
      expect(paid.remainingBalance, 15000);
      expect(resolveOwnerNextStep(paid).kind, BookingNextStepKind.startHandover);
      expect(resolveCustomerNextStep(paid).kind, BookingNextStepKind.viewPass);

      // Downgrade guard: proof upload MUST fail once paid
      await expectLater(
        ds.updatePaymentProof(
          bookingId: paid.bookingId,
          paymentProofUrl: 'https://cdn.example/proofs/late.jpg',
          transactionId: 'TRX-LATE',
        ),
        throwsStateError,
      );

      // Step 5: Handover completed -> active
      final active = await ds.updateBookingStatus(
        bookingId: paid.bookingId,
        status: 'active',
      );
      expect(active.status, 'active');
      expect(resolveOwnerNextStep(active).kind,
          BookingNextStepKind.returnSettlement);
      expect(resolveCustomerNextStep(active).kind,
          BookingNextStepKind.viewActiveTrip);

      // Step 6: Return settlement with editable late fee & remaining rent
      final afterBalance = await ds.recordBalanceCollected(
        bookingId: active.bookingId,
        amount: 15000,
      );
      expect(afterBalance.advancePaid, 20000);
      expect(afterBalance.remainingBalance, 0);

      final settlement = SettlementCalculator.calculate(
        totalKmDriven: 300,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        overtimeHours: 2,
        extraHourPkr: 0,
        overtimeFeeOverride: 2000,
        securityDeposit: 15000,
      );
      expect(settlement.excessKmCharge, 5000);
      expect(settlement.overtimeFee, 2000);
      expect(settlement.totalDeductions, 7000);
      expect(settlement.netRefund, 8000);

      final completed = await ds.updateBookingStatus(
        bookingId: active.bookingId,
        status: 'completed',
      );
      expect(completed.status, 'completed');
      expect(resolveOwnerNextStep(completed).kind,
          BookingNextStepKind.rateCustomer);
      expect(resolveCustomerNextStep(completed).kind,
          BookingNextStepKind.rateTrip);
    });
  });

  group('2. Walk-in booking pipeline — 100% owner-only integrity', () {
    test('walk-in approved -> owner recordPayment -> paid -> active', () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'walkin-audit-1',
        shopId: 'audit-shop-2',
        vehicleId: 'audit-veh-2',
        vehicleName: 'Toyota Yaris',
        customerName: 'Usman Ali',
        customerPhone: '03011234567',
        origin: 'walk_in',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 28, 12),
        returnTime: DateTime(2026, 11, 29, 12),
        totalAmount: 12000,
        advanceRequired: 4000,
      );
      final approved = await ds.recordAdvancePayment(
        bookingId: created.bookingId,
        advanceAmount: 0,
      );
      expect(approved.status, 'approved');
      expect(resolveOwnerNextStep(approved).kind,
          BookingNextStepKind.recordPayment);

      // Partial payment keeps status approved until advance met
      final partial = await WalkInBookingService.recordOwnerPayment(
        booking: approved,
        amount: 2000,
        paymentMethod: 'cash',
      );
      expect(partial.status, 'approved');
      expect(partial.advancePaid, 2000);
      expect(partial.remainingBalance, 10000);

      // Completing advance promotes approved -> paid
      final paid = await WalkInBookingService.recordOwnerPayment(
        booking: partial,
        amount: 2000,
        paymentMethod: 'jazzcash',
      );
      expect(paid.status, 'paid');
      expect(paid.advancePaid, 4000);
      expect(paid.remainingBalance, 8000);
      expect(resolveOwnerNextStep(paid).kind, BookingNextStepKind.startHandover);
    });
  });

  group('3. Handover payment step — editable security, dropdowns & strict checks',
      () {
    test('HandoverWizardCubit enforces strict step-1 Continue validation', () {
      final cubit = HandoverWizardCubit(bookingId: 'HO-AUDIT-1', initialStep: 1);
      addTearDown(cubit.close);

      // 1. Missing balance method blocks Continue
      cubit.nextStep(balanceDue: 10000, securityDeposit: 15000);
      expect(cubit.state.step, 1);
      expect(cubit.state.error, 'payment');
      expect(cubit.state.errorTick, 1);

      // Repeated blocked tap increments errorTick so toast re-fires
      cubit.nextStep(balanceDue: 10000, securityDeposit: 15000);
      expect(cubit.state.errorTick, 2);

      // 2. Picking Cash without toggling Balance Received blocks Continue
      cubit.setBalanceMethod('cash');
      cubit.nextStep(balanceDue: 10000, securityDeposit: 15000);
      expect(cubit.state.step, 1);
      expect(cubit.state.error, 'payment_confirm');

      // 3. Confirming Balance Received advances check to deposit method
      cubit.setBalanceReceived(true);
      cubit.nextStep(balanceDue: 10000, securityDeposit: 15000);
      expect(cubit.state.step, 1);
      expect(cubit.state.error, 'deposit');

      // 4. Editing security deposit to 20000 and picking method without
      //    toggling Deposit Received blocks Continue
      cubit.setSecurityDeposit(20000);
      expect(cubit.state.effectiveDeposit(15000), 20000);
      cubit.setDepositMethod('bank_transfer');
      cubit.nextStep(balanceDue: 10000, securityDeposit: 15000);
      expect(cubit.state.step, 1);
      expect(cubit.state.error, 'deposit_confirm');

      // 5. Confirming Deposit Received allows moving to Step 2 (Checklist)
      cubit.setDepositReceived(true);
      cubit.nextStep(balanceDue: 10000, securityDeposit: 15000);
      expect(cubit.state.step, 2);
      expect(cubit.state.error, isNull);
    });

    test('waiving security deposit to 0 bypasses deposit method/received gate',
        () {
      final cubit = HandoverWizardCubit(bookingId: 'HO-AUDIT-2', initialStep: 1);
      addTearDown(cubit.close);

      cubit.setBalanceMethod('not_yet');
      cubit.setSecurityDeposit(0);
      cubit.nextStep(balanceDue: 8000, securityDeposit: 15000);
      expect(cubit.state.step, 2);
    });

    testWidgets(
        'HandoverBalanceSection renders editable security field & dropdowns',
        (tester) async {
      int? editedDeposit;
      String? balanceMethod;
      String? depositMethod;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: HandoverBalanceSection(
                balanceDue: 10000,
                securityDeposit: 15000,
                advancePaid: 5000,
                selectedMethod: balanceMethod,
                onMethodChanged: (m) => balanceMethod = m,
                onSecurityDepositChanged: (v) => editedDeposit = v,
                depositMethod: depositMethod,
                onDepositMethodChanged: (m) => depositMethod = m,
                balanceReceived: false,
                onBalanceReceivedChanged: (_) {},
                depositReceived: false,
                onDepositReceivedChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Payment methods are dropdowns, not ChoiceChips
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byKey(const ValueKey('handover_balance_method_dropdown')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('handover_deposit_method_dropdown')),
          findsOneWidget);

      // Security amount is editable
      final secField =
          find.byKey(const ValueKey('handover_security_deposit_field'));
      expect(secField, findsOneWidget);
      await tester.enterText(secField, '18000');
      expect(editedDeposit, 18000);
    });
  });

  group('4. Booking detail button integrity across statuses', () {
    BookingEntity makeBooking(String status, {String origin = 'walk_in'}) =>
        BookingEntity(
          bookingId: 'BTN-$status',
          customerId: 'cust-btn',
          shopId: 'shop-btn',
          vehicleId: 'veh-btn',
          packageType: '24h',
          pickupTime: DateTime(2026, 11, 28, 10),
          returnTime: DateTime(2026, 11, 29, 10),
          totalAmount: 10000,
          advanceRequired: 3000,
          advancePaid: status == 'paid' || status == 'active' ? 3000 : 0,
          remainingBalance:
              status == 'paid' || status == 'active' ? 7000 : 10000,
          status: status,
          origin: origin,
          customerName: 'Button Audit',
          customerPhone: '03001234567',
          vehicleName: 'Suzuki Alto',
        );

    Future<void> pumpDetail(WidgetTester tester, BookingEntity b) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => OwnerBookingDetailView(booking: b),
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
    }

    testWidgets('each status exposes exact expected owner buttons',
        (tester) async {
      await pumpDetail(tester, makeBooking('requested', origin: 'online'));
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      await pumpDetail(tester, makeBooking('approved', origin: 'walk_in'));
      expect(find.text('Add Payment'), findsOneWidget);
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);

      await pumpDetail(tester, makeBooking('paid', origin: 'walk_in'));
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Add Payment'), findsOneWidget);

      await pumpDetail(tester, makeBooking('active', origin: 'walk_in'));
      expect(find.text('Proceed to Return & Settlement'), findsOneWidget);
      expect(find.text('Add Payment'), findsOneWidget);

      await pumpDetail(tester, makeBooking('cancelled', origin: 'walk_in'));
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
