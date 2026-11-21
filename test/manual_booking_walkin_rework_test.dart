import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_receipt_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/guarantor_picker.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_car_step.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_customer_step.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_payment_step.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Walk-in booking rework (O21–O24): registered customers only,
// 4 steps, deposit + discount on the booking, receipt screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-walkin-1',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    plateNumber: 'LEA-1000',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 6000,
      outOfCityDaily: 7500,
    ),
    weeklyRate: 36000,
    securityDepositPkr: 20000,
    advanceRequiredPkr: 3000,
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 6000, kmIncluded: 250),
    ],
  );

  CustomerEntity customer({
    required String id,
    required String name,
    required String cnic,
    String? signatureUrl,
    String? profilePhotoUrl,
    String? licenseNumber,
  }) =>
      CustomerEntity(
        customerId: id,
        shopId: 'shop-1',
        name: name,
        phone: '03001234567',
        cnic: cnic,
        createdAt: DateTime(2026, 11, 1),
        signatureUrl: signatureUrl,
        profilePhotoUrl: profilePhotoUrl,
        licenseNumber: licenseNumber,
      );

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  BookingModel bookingFor({
    required String vehicleId,
    required DateTime pickup,
    required DateTime ret,
    String status = 'approved',
  }) =>
      BookingModel(
        bookingId: 'RH-overlap-1',
        customerId: 'cust-other',
        shopId: 'shop-1',
        vehicleId: vehicleId,
        packageType: '24h',
        pickupTime: pickup,
        returnTime: ret,
        totalAmount: 6000,
        remainingBalance: 6000,
        status: status,
      );

  group('discount field (data model)', () {
    test('discount round-trips through the model like deposit', () {
      final model = BookingModel(
        bookingId: 'RH-disc-1',
        customerId: 'cust-disc-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 8000,
        remainingBalance: 8000,
        depositAmountPkr: 20000,
        discountAmountPkr: 1000,
        origin: 'walk_in',
      );
      final restored = BookingModel.fromMap(model.toMap(), 'RH-disc-1');
      expect(restored.discountAmountPkr, 1000);
      expect(restored.depositAmountPkr, 20000);
      expect(restored.toMap(), model.toMap());
      final noDiscount = BookingModel.fromMap(
          BookingModel(
            bookingId: 'RH-disc-2',
            customerId: 'cust-disc-2',
            shopId: 'shop-1',
            vehicleId: 'veh-1',
            packageType: '24h',
            pickupTime: DateTime(2026, 11, 6, 9),
            returnTime: DateTime(2026, 11, 7, 9),
            totalAmount: 9000,
            remainingBalance: 9000,
          ).toMap(),
          'RH-disc-2');
      expect(noDiscount.discountAmountPkr, isNull);
    });
  });

  group('walk-in service: registered customer + deposit + discount', () {
    Future<BookingEntity> walkIn({
      String? customerId,
      double? deposit,
      double? discount,
    }) async {
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      return WalkInBookingService.createWalkInBooking(
        name: 'Ahmed Khan',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        guarantor: const GuarantorSelection(
            name: 'Bilal Ahmed',
            cnic: '35202-1234567-2',
            phone: '03007654321',
            relationship: 'Brother'),
        vehicle: testVehicle,
        package: pkg24,
        isWithDriver: false,
        rentAmount: 8000,
        advanceRequired: 3000,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        tripType: 'in_city',
        advanceReceived: 3000,
        customerId: customerId,
        depositAmountPkr: deposit,
        discountAmountPkr: discount,
      );
    }

    test('registered customer keeps its id, deposit + discount saved',
        () async {
      final booking = await walkIn(
          customerId: 'cust-reg-1', deposit: 20000, discount: 1000);
      expect(booking.customerId, 'cust-reg-1');
      expect(booking.origin, 'walk_in');
      expect(booking.depositAmountPkr, 20000);
      expect(booking.discountAmountPkr, 1000);
      expect(booking.totalAmount, 8000);
      expect(booking.guarantorRelation, 'Brother');
      expect(booking.status, 'paid');
      expect(booking.advancePaid, 3000);
      expect(booking.remainingBalance, 5000);
      // The deposit + discount survive a reload through the model.
      final reloaded = await di
          .sl<BookingRemoteDataSource>()
          .getBookingById(booking.bookingId);
      expect(reloaded?.depositAmountPkr, 20000);
      expect(reloaded?.discountAmountPkr, 1000);
      expect(reloaded?.customerId, 'cust-reg-1');
    });

    test('legacy path without a customer id still uses a walkin id',
        () async {
      final booking = await walkIn();
      expect(booking.customerId, startsWith('walkin-'));
      expect(booking.depositAmountPkr, isNull);
      expect(booking.discountAmountPkr, isNull);
    });
  });

  group('car free-for-time check', () {
    final pickup = DateTime(2026, 11, 20, 10);
    final ret = DateTime(2026, 11, 21, 10);

    test('an overlapping live booking blocks the car', () {
      expect(
          WalkInBookingService.bookingOverlaps(
              pickup: pickup,
              returnTime: ret,
              booking: bookingFor(
                  vehicleId: 'veh-walkin-1',
                  pickup: DateTime(2026, 11, 20, 15),
                  ret: DateTime(2026, 11, 21, 9))),
          isTrue);
    });

    test('an adjacent booking does not block', () {
      expect(
          WalkInBookingService.bookingOverlaps(
              pickup: pickup,
              returnTime: ret,
              booking: bookingFor(
                  vehicleId: 'veh-walkin-1',
                  pickup: DateTime(2026, 11, 21, 10),
                  ret: DateTime(2026, 11, 22, 10))),
          isFalse);
    });

    test('a cancelled overlapping booking does not block', () {
      expect(
          WalkInBookingService.bookingOverlaps(
              pickup: pickup,
              returnTime: ret,
              booking: bookingFor(
                  vehicleId: 'veh-walkin-1',
                  pickup: DateTime(2026, 11, 20, 15),
                  ret: DateTime(2026, 11, 21, 9),
                  status: 'cancelled')),
          isFalse);
    });

    test('isVehicleFree honours the booking list', () async {
      final busy = await WalkInBookingService.isVehicleFree(
        shopId: 'shop-1',
        vehicleId: 'veh-walkin-1',
        pickup: pickup,
        returnTime: ret,
        existingBookings: [
          bookingFor(
              vehicleId: 'veh-walkin-1',
              pickup: DateTime(2026, 11, 20, 15),
              ret: DateTime(2026, 11, 21, 9))
        ],
      );
      expect(busy, isFalse);
      final free = await WalkInBookingService.isVehicleFree(
        shopId: 'shop-1',
        vehicleId: 'veh-walkin-1',
        pickup: pickup,
        returnTime: ret,
        existingBookings: const [],
      );
      expect(free, isTrue);
    });
  });

  group('step 1: registered-customer picker', () {
    final good = customer(
        id: 'cust-good',
        name: 'Ahmed Khan',
        cnic: '35202-1234567-1',
        signatureUrl: 'https://example.test/sig.png',
        profilePhotoUrl: 'https://example.test/face.png',
        licenseNumber: 'LHR-123');
    final flagged = customer(
        id: 'cust-flagged', name: 'Bilal Ahmed', cnic: '35202-1234567-2');

    testWidgets('cards show trust, blacklist, KYC and signature state',
        (tester) async {
      CustomerEntity? selected;
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(child: ManualBookingCustomerStep(
        selected: null,
        onSelected: (c) => selected = c,
        onAddNewCustomer: (_) {},
        onGuarantorChanged: (_) {},
        initialCustomers: [good, flagged],
        blacklistedCnics: {'3520212345672'},
        trustScoreOverrides: {'cust-good': 4.7},
      )))));
      await tester.pumpAndSettle();
      // 'Ahmed Khan' also appears in the guarantor picker's saved
      // list (the service tests above saved him in-memory), so the
      // card itself is asserted by key, not by name.
      expect(find.byKey(const ValueKey('manual-booking-customer-cust-good')),
          findsOneWidget);
      expect(find.text('Trust 4.7/5'), findsOneWidget);
      expect(find.text('Not blacklisted'), findsOneWidget);
      expect(find.text('Blacklisted — cannot book'), findsOneWidget);
      expect(find.text('KYC done'), findsOneWidget);
      expect(find.text('Saved signature auto-applied'), findsOneWidget);
      expect(find.text('No saved signature'), findsOneWidget);
      expect(find.byKey(const Key('manual-booking-add-customer')),
          findsOneWidget);
      expect(selected, isNull);
    });

    testWidgets('a blacklisted customer cannot be selected',
        (tester) async {
      CustomerEntity? selected;
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(child: ManualBookingCustomerStep(
        selected: null,
        onSelected: (c) => selected = c,
        onAddNewCustomer: (_) {},
        onGuarantorChanged: (_) {},
        initialCustomers: [good, flagged],
        blacklistedCnics: {'3520212345672'},
        trustScoreOverrides: {'cust-good': 4.7},
      )))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(
          const ValueKey('manual-booking-customer-cust-flagged')));
      await tester.pump();
      expect(selected, isNull);
      expect(
          find.text('This CNIC is blacklisted — walk-in booking refused.'),
          findsOneWidget);
      await tester.tap(find.byKey(
          const ValueKey('manual-booking-customer-cust-good')));
      await tester.pumpAndSettle();
      expect(selected?.customerId, 'cust-good');
    });

    testWidgets('search filters the list; prefill auto-selects',
        (tester) async {
      CustomerEntity? selected;
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(child: ManualBookingCustomerStep(
        selected: null,
        onSelected: (c) => selected = c,
        onAddNewCustomer: (_) {},
        onGuarantorChanged: (_) {},
        initialCustomers: [good, flagged],
        blacklistedCnics: {'3520212345672'},
        trustScoreOverrides: {'cust-good': 4.7},
        prefilledCnic: '35202-1234567-1',
      )))));
      await tester.pumpAndSettle();
      expect(selected?.customerId, 'cust-good');
      await tester.enterText(
          find.byKey(const Key('manual-booking-customer-search')), 'Bilal');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('manual-booking-customer-cust-good')),
          findsNothing);
      expect(find.byKey(const ValueKey('manual-booking-customer-cust-flagged')),
          findsOneWidget);
    });

    testWidgets('add-new-customer passes the typed search text',
        (tester) async {
      String? query;
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(child: ManualBookingCustomerStep(
        selected: null,
        onSelected: (_) {},
        onAddNewCustomer: (q) => query = q,
        onGuarantorChanged: (_) {},
        initialCustomers: [good],
      )))));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('manual-booking-customer-search')),
          '35202-1234567-9');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manual-booking-add-customer')));
      await tester.pumpAndSettle();
      expect(query, '35202-1234567-9');
    });
  });

  group('step 2: car radio list', () {
    final rented =
        testVehicle.copyWith(vehicleId: 'veh-rented', plateNumber: 'LEA-2000', status: 'rented');
    final maintenance = testVehicle.copyWith(
        vehicleId: 'veh-maint', plateNumber: 'LEA-3000', status: 'maintenance');
    final pkg24 =
        testVehicle.packages.firstWhere((p) => p.label == '24h');

    testWidgets('badges render and a busy car is reported',
        (tester) async {
      bool? free;
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(child: ManualBookingCarStep(
        isLoadingVehicles: false,
        vehiclesError: null,
        onRetryLoad: () {},
        vehicles: [testVehicle, rented, maintenance],
        selectedVehicle: testVehicle,
        onVehicleChanged: (_) {},
        selectedPackage: pkg24,
        onPackageChanged: (_) {},
        isWithDriver: false,
        onDriverModeChanged: (_) {},
        isOutOfCity: false,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        onPickupChanged: (_) {},
        onReturnChanged: (_) {},
        onTripTypeChanged: (_) {},
        onAvailabilityChanged: (v) => free = v,
        existingBookings: [
          bookingFor(
              vehicleId: 'veh-walkin-1',
              pickup: DateTime(2026, 11, 20, 15),
              ret: DateTime(2026, 11, 21, 9))
        ],
      )))));
      await tester.pumpAndSettle();
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('On Rent'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Car is already booked for this time'), findsOneWidget);
      expect(free, isFalse);
    });

    testWidgets('a free car shows the free line', (tester) async {
      bool? free;
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(child: ManualBookingCarStep(
        isLoadingVehicles: false,
        vehiclesError: null,
        onRetryLoad: () {},
        vehicles: [testVehicle],
        selectedVehicle: testVehicle,
        onVehicleChanged: (_) {},
        selectedPackage: pkg24,
        onPackageChanged: (_) {},
        isWithDriver: false,
        onDriverModeChanged: (_) {},
        isOutOfCity: false,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        onPickupChanged: (_) {},
        onReturnChanged: (_) {},
        onTripTypeChanged: (_) {},
        onAvailabilityChanged: (v) => free = v,
        existingBookings: const [],
      )))));
      await tester.pumpAndSettle();
      expect(find.text('Car is free for this time'), findsOneWidget);
      expect(free, isTrue);
    });
  });

  group('step 3: payment + deposit', () {
    testWidgets('money lines, method chips, deposit and dues toggle',
        (tester) async {
      final discount = TextEditingController(text: '0');
      final advance = TextEditingController(text: '6000');
      final deposit = TextEditingController(text: '20000');
      addTearDown(() {
        discount.dispose();
        advance.dispose();
        deposit.dispose();
      });
      await tester.pumpWidget(appFor(StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SingleChildScrollView(
          child: ManualBookingPaymentStep(
            rentAmount: 6000,
            driverAmount: 0,
            discountController: discount,
            discountError: null,
            onDiscountChanged: () => setState(() {}),
            advanceController: advance,
            advanceError: null,
            onAdvanceChanged: () => setState(() {}),
            advanceRequired: 3000,
            paymentMethod: 'cash',
            onPaymentMethodChanged: (_) {},
            depositController: deposit,
            depositReceived: true,
            onDepositReceivedChanged: (_) {},
            depositMethod: 'cash',
            onDepositMethodChanged: (_) {},
            remainingDues: 0,
            addToDues: true,
            onAddToDuesChanged: (_) {},
          ),
        ),
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 6,000'), findsWidgets);
      expect(find.text('Cash'), findsWidgets);
      expect(find.text('JazzCash'), findsWidgets);
      expect(find.text('EasyPaisa'), findsWidgets);
      expect(find.text('Bank Transfer'), findsWidgets);
      expect(find.text('Security received'), findsOneWidget);
      expect(find.text('Remaining Dues'), findsOneWidget);
      expect(find.text('Add remaining to customer dues'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('manual-booking-discount')), '500');
      await tester.pumpAndSettle();
      expect(find.text('Rs. 5,500'), findsOneWidget);
    });
  });

  group('receipt screen', () {
    testWidgets('real booking number, Walk-in badge, share action',
        (tester) async {
      final booking = BookingModel(
        bookingId: 'RH-1234567-1',
        customerId: 'cust-good',
        shopId: 'shop-1',
        vehicleId: 'veh-walkin-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        totalAmount: 6000,
        advancePaid: 6000,
        remainingBalance: 0,
        status: 'paid',
        customerName: 'Ahmed Khan',
        customerPhone: '03001234567',
        vehicleName: 'Toyota Corolla 2022',
        depositAmountPkr: 20000,
        discountAmountPkr: 500,
      );
      await tester.pumpWidget(appFor(OwnerManualBookingReceiptView(
        booking: booking,
        paymentMethod: 'cash',
        rentAmount: 6000,
        driverAmount: 0,
        depositMethod: 'cash',
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('RH-1234567-1'), findsOneWidget);
      expect(find.text('Walk-in'), findsOneWidget);
      expect(find.text('Rs. 6,000'), findsWidgets);
      expect(find.textContaining('Rs. 500'), findsOneWidget);
      expect(find.text('Rs. 20,000 (Cash)'), findsOneWidget);
      expect(
          find.text(
              'Agreement is generated automatically at handover using saved signatures'),
          findsOneWidget);
      expect(find.byKey(const Key('manual-booking-share-receipt')),
          findsOneWidget);
    });
  });

  group('wizard: no customer, no next step', () {
    testWidgets('Next on step 1 without a customer is refused',
        (tester) async {
      await tester.pumpWidget(appFor(const OwnerManualBookingView()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Select a customer to continue.'), findsOneWidget);
    });
  });
}
