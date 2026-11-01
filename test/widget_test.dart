import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'test_helper.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rentalhub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:rentalhub/features/auth/presentation/cubit/auth_state.dart';
import 'package:rentalhub/features/bookings/domain/usecases/create_booking_request_usecase.dart';
import 'package:rentalhub/features/bookings/domain/usecases/update_booking_status_usecase.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/usecases/add_vehicle_usecase.dart';
import 'package:rentalhub/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/blacklist/presentation/cubit/blacklist_cubit.dart';
import 'package:rentalhub/core/routing/admin_guard.dart';
import 'package:rentalhub/features/trust/presentation/views/customer_documents_view.dart';
import 'package:rentalhub/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('Phase 0: RentalHub app launches and renders discovery baseline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RentalHubApp());
    await tester.pumpAndSettle();

    expect(find.text('RentalHub'), findsWidgets);
  });

  test(
      'Phase 1 DoD (4.1): Role immutability locks permanent role and rejects overwrite',
      () async {
    final authDataSource = sl<AuthRemoteDataSource>();
    final lockedCustomer = await authDataSource.assignPermanentRole(
      role: 'customer',
      fullName: 'Ahmed Raza',
      phone: '+92 300 4129811',
    );
    expect(lockedCustomer.role, 'customer');

    expect(
      () => authDataSource.assignPermanentRole(
        role: 'owner',
        fullName: 'Ahmed Raza',
        phone: '+92 300 4129811',
      ),
      throwsA(isA<RoleImmutableException>()),
    );

    final authCubit = sl<AuthCubit>();
    await authCubit.selectPermanentRole(
      role: 'owner',
      fullName: 'Ahmed Raza',
      phone: '+92 300 4129811',
    );
    expect(authCubit.state, isA<AuthError>());
  });

  testWidgets(
      'Phase 1 DoD (4.2): CustomerHomeView renders with 0 overflow on 360px viewport and 1.35x font scale',
      (WidgetTester tester) async {
    await TestHarness.pumpScreenWithOverflowCheck(
      tester: tester,
      screen: const CustomerHomeView(),
      width: 360.0,
      height: 640.0,
      textScale: 1.35,
      theme: AppTheme.lightTheme,
    );

    expect(find.text('Find Verified Rental Shops'), findsOneWidget);
    expect(find.text('1 km'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
  });

  testWidgets(
      'Phase 1 DoD: CustomerDocumentsView (KYC upload) renders cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CustomerDocumentsView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NADRA CNIC & Driving License KYC'), findsOneWidget);
    expect(find.text('NADRA CNIC — Front Side'), findsOneWidget);
  });

  test('Phase 2 DoD (4.1): Owner on basic tier cannot add 4th vehicle',
      () async {
    final addVehicleUseCase = sl<AddVehicleUseCase>();
    const sample4thCar = VehicleEntity(
      vehicleId: 'v4',
      shopId: 'shop-basic',
      make: 'Kia',
      model: 'Sportage',
      year: 2023,
      plateNumber: 'LEA-9981',
      rates: VehicleRatesEntity(daily24: 12000),
    );

    // shop-basic already has 3 seeded vehicles
    expect(
      () => addVehicleUseCase(shopId: 'shop-basic', vehicle: sample4thCar),
      throwsA(isA<BusinessRuleException>()),
    );
  });

  testWidgets(
      'Phase 2 DoD (4.2): DebouncedButton emits exactly 1 event on 5 rapid taps',
      (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebouncedButton(
            label: 'Submit',
            onPressed: () => tapCount++,
            debounceMs: 400,
          ),
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.tap(find.text('Submit'));
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(tapCount, equals(1));
    await tester.pump(const Duration(milliseconds: 500));
  });

  test(
      'Phase 2 DoD: Booking state machine transitions (requested -> approved -> payment_submitted -> paid)',
      () async {
    final createBooking = sl<CreateBookingRequestUseCase>();
    final updateStatus = sl<UpdateBookingStatusUseCase>();
    final paymentCubit = sl<PaymentCubit>();

    final created = await createBooking(
      customerId: 'usr_pk_001',
      shopId: 'shop-1',
      vehicleId: 'v1',
      packageType: '3-Hour QuickRide',
      isWithDriver: true,
      pickupTime: DateTime(2026, 11, 1, 14, 0),
      returnTime: DateTime(2026, 11, 1, 17, 0),
      totalAmount: 3500,
      advanceRequired: 1000,
    );
    expect(created.status, 'requested');

    final approved = await updateStatus(
      bookingId: created.bookingId,
      status: 'approved',
    );
    expect(approved.status, 'approved');

    await paymentCubit.submitPaymentProof(
      bookingId: created.bookingId,
      customerUid: 'usr_pk_001',
      transactionId: 'TX98412850',
    );
    expect(paymentCubit.state, isA<PaymentSubmittedSuccess>());

    await paymentCubit.verifyOwnerPayment(
      bookingId: created.bookingId,
      advanceAmount: 1000,
    );
    final verifiedState = paymentCubit.state as PaymentVerifiedSuccess;
    expect(verifiedState.booking.status, 'paid');
    expect(verifiedState.booking.advancePaid, 1000);
    expect(verifiedState.booking.remainingBalance, 2500);
  });

  test(
      'Phase 3 DoD: Offline Handover persists locally in Airplane mode and syncs A4 PDF on reconnect',
      () async {
    final handoverCubit = sl<HandoverCubit>();
    await handoverCubit.completeHandoverOfflineFirst(
      bookingId: 'RH-84920',
      shopName: 'Al-Falah Rent a Car',
      customerName: 'Ahmed Raza',
      cnicNumber: '35202-8819201-5',
      vehicleDetails: 'Honda Civic Oriel 2021 (LEA-4820)',
      initialOdometer: 42850,
      fuelLevel: '6/8 (75%)',
      damageNotes: const ['Front Bumper: Minor Scratch'],
      customerSignatureSvg: 'M10 10 L90 40',
      ownerSignatureSvg: 'M12 20 L85 35',
      isOnline: false,
    );

    expect(handoverCubit.state, isA<HandoverSavedOffline>());
    final offlineState = handoverCubit.state as HandoverSavedOffline;
    expect(offlineState.handover.isSynced, isFalse);

    final syncedCount = await handoverCubit.syncPendingHandovers();
    expect(syncedCount, 1);
    expect(handoverCubit.state, isA<HandoverSynced>());
  });

  test(
      'Phase 4 DoD: Single super_admin guard and Blacklist Tribunal instant flag & mandatory-audit reversal',
      () async {
    expect(
      AdminGuard.verifySuperAdmin(
        email: 'superadmin@rentalhub.pk',
        role: 'super_admin',
      ),
      isTrue,
    );
    expect(
      AdminGuard.verifySuperAdmin(
        email: 'attacker@rentalhub.pk',
        role: 'super_admin',
      ),
      isFalse,
    );

    final blacklistCubit = sl<BlacklistCubit>();
    final flagged = await blacklistCubit.reportFraud(
      reportedByShopId: 'shop-1',
      cnicNumber: '35201-9918234-1',
      phoneNumber: '+92 300 0000000',
      reasonCategory: 'Vehicle Theft / Tracker Tampered',
      description: 'Failed to return after 48h',
    );
    expect(flagged.isActive, isTrue);

    final reverted = await blacklistCubit.revertBySuperAdmin(
      blacklistId: flagged.blacklistId,
      adminUid: 'admin_master_01',
      justification: 'Verified settlement receipt and police clearance.',
    );
    expect(reverted.isActive, isFalse);
    expect(
      reverted.revertedReason,
      'Verified settlement receipt and police clearance.',
    );
  });
}
