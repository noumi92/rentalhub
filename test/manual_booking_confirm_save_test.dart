import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/fixed_route_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_confirm_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_manual_booking_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/guarantor_picker.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Step-4 save repro (user report 2026-11-20, build 87): "Unable to
// save booking in 4th step (summary)". The service-level path was
// covered, but no test ever pumped the summary view and tapped
// Confirm, and no test ever ran the save with Firestore present
// (the phone configuration) — both gaps are closed here.
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

  OwnerManualBookingConfirmView confirmView({
    bool addRemainingToDues = true,
    int advanceReceived = 3000,
    double? depositAmountPkr = 20000,
    double? discountAmountPkr = 1000,
  }) {
    final pkg24 =
        testVehicle.packages.firstWhere((p) => p.label == '24h');
    return OwnerManualBookingConfirmView(
      customerId: 'cust-reg-1',
      customerName: 'Ahmed Khan',
      customerPhone: '03001234567',
      customerCnic: '35202-1234567-1',
      guarantor: const GuarantorSelection(
          name: 'Bilal Ahmed',
          cnic: '35202-1234567-2',
          phone: '03007654321',
          relationship: 'Brother'),
      vehicle: testVehicle,
      package: pkg24,
      isWithDriver: true,
      isOutOfCity: false,
      pickupTime: DateTime(2026, 11, 20, 10),
      returnTime: DateTime(2026, 11, 21, 10),
      rentAmount: 6000,
      driverAmount: 1500,
      discountAmountPkr: discountAmountPkr,
      advanceReceived: advanceReceived,
      paymentMethod: 'cash',
      depositAmountPkr: depositAmountPkr,
      depositMethod: 'cash',
      addRemainingToDues: addRemainingToDues,
    );
  }

  GoRouter routerFor(Widget confirm) => GoRouter(
        initialLocation: RouteNames.ownerManualBookingConfirm,
        routes: [
          GoRoute(
            path: RouteNames.ownerManualBookingConfirm,
            builder: (context, state) => confirm,
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingReceipt,
            builder: (context, state) {
              final booking =
                  (state.extra as Map<String, dynamic>?)?['booking']
                      as BookingEntity?;
              return Scaffold(
                body: Center(
                    child: Text('receipt:${booking?.bookingId ?? 'none'}')),
              );
            },
          ),
        ],
      );

  Widget appFor(Widget confirm) => MaterialApp.router(
        routerConfig: routerFor(confirm),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );

  group('step 4: Confirm saves the booking', () {
    testWidgets('registered customer, deposit + discount: receipt opens',
        (tester) async {
      await tester.pumpWidget(appFor(confirmView()));
      await tester.pumpAndSettle();
      expect(find.text('Booking Summary'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining('receipt:RH-'), findsOneWidget,
          reason: 'the receipt opens only after the booking is created');
      expect(find.textContaining('Booking creation failed'),
          findsNothing);
      final ds = di.sl<BookingRemoteDataSource>();
      final bookings = await ds.getShopBookings('shop-1');
      expect(bookings, isNotEmpty);
      final created = bookings.last;
      expect(created.customerId, 'cust-reg-1');
      expect(created.status, 'paid');
      expect(created.advancePaid, 3000);
      expect(created.depositAmountPkr, 20000);
      expect(created.discountAmountPkr, 1000);
    });

    testWidgets('zero advance, no deposit: receipt still opens',
        (tester) async {
      await tester.pumpWidget(appFor(confirmView(
        advanceReceived: 0,
        depositAmountPkr: null,
        discountAmountPkr: null,
      )));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining('receipt:RH-'), findsOneWidget);
      expect(find.textContaining('Booking creation failed'),
          findsNothing);
    });

    testWidgets(
        'dues toggle off with a remaining balance refuses the save',
        (tester) async {
      await tester.pumpWidget(appFor(confirmView(
        addRemainingToDues: false,
      )));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining('receipt:RH-'), findsNothing);
      expect(
          find.text('Collect the full amount, or add the remaining '
              'to customer dues.'),
          findsOneWidget);
    });
  });


  group('wizard end to end: steps 1-4 with the real draft handoff', () {
    testWidgets('tap through the wizard; Confirm saves the booking',
        (tester) async {
      // Seed the shop's data the wizard loads.
      await di.sl<CustomerRemoteDataSource>().upsertCustomer(
            CustomerEntity(
              customerId: 'cust-reg-1',
              shopId: 'shop-1',
              name: 'Ahmed Khan',
              phone: '03001234567',
              cnic: '35202-1234567-1',
              createdAt: DateTime(2026, 11, 1),
            ),
          );
      await di.sl<FleetRemoteDataSource>().addVehicle(
          shopId: 'shop-1',
          vehicle: testVehicle.copyWith(
              vehicleId: 'veh-walkin-4', plateNumber: 'LEA-1004'));

      final router = GoRouter(
        initialLocation: RouteNames.ownerManualBooking,
        routes: [
          GoRoute(
            path: RouteNames.ownerManualBooking,
            builder: (context, state) =>
                const OwnerManualBookingView(),
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingConfirm,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return OwnerManualBookingConfirmView(
                customerId: extra?['customerId'] as String,
                customerName: extra?['customerName'] as String,
                customerPhone: extra?['customerPhone'] as String,
                customerCnic: extra?['customerCnic'] as String,
                guarantor: extra?['guarantor'] as GuarantorSelection?,
                vehicle: extra?['vehicle'] as VehicleEntity,
                package: extra?['package'] as VehiclePackageEntity,
                isWithDriver: extra?['isWithDriver'] as bool? ?? false,
                isOutOfCity: extra?['isOutOfCity'] as bool? ?? false,
                pickupTime: extra?['pickupTime'] as DateTime,
                returnTime: extra?['returnTime'] as DateTime,
                fixedRoute: extra?['fixedRoute'] as FixedRouteEntity?,
                rentAmount: extra?['rentAmount'] as int? ?? 0,
                driverAmount: extra?['driverAmount'] as int? ?? 0,
                discountAmountPkr:
                    (extra?['discountAmountPkr'] as num?)?.toDouble(),
                advanceReceived: extra?['advanceReceived'] as int? ?? 0,
                paymentMethod:
                    extra?['paymentMethod'] as String? ?? 'cash',
                depositAmountPkr:
                    (extra?['depositAmountPkr'] as num?)?.toDouble(),
                depositMethod:
                    extra?['depositMethod'] as String? ?? 'cash',
                addRemainingToDues:
                    extra?['addRemainingToDues'] as bool? ?? true,
              );
            },
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingReceipt,
            builder: (context, state) {
              final booking =
                  (state.extra as Map<String, dynamic>?)?['booking']
                      as BookingEntity?;
              return Scaffold(
                body: Center(
                    child: Text('receipt:${booking?.bookingId ?? 'none'}')),
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      // Step 1: pick the registered customer.
      expect(find.text('Ahmed Khan'), findsWidgets);
      await tester.tap(find.text('Ahmed Khan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: select this test's own car (veh-walkin-1 is booked
      // by the earlier service tests for the same window), then go on.
      await tester.tap(find.text('LEA-1004'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: advance is prefilled; go to the summary.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: confirm and save.
      expect(find.text('Booking Summary'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining('receipt:RH-'), findsOneWidget,
          reason: 'the wizard must save through step 4');
      expect(find.textContaining('Booking creation failed'),
          findsNothing);
    });
  });

  group('custom advance at step 3 (user report 2026-11-20)', () {
    Future<BookingEntity> customWalkIn({required int advance}) async {
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
        isWithDriver: true,
        rentAmount: 7500,
        advanceRequired: 3000,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        tripType: 'in_city',
        advanceReceived: advance,
        customerId: 'cust-reg-1',
        depositAmountPkr: 20000,
        discountAmountPkr: null,
        paymentMethod: 'cash',
        depositMethod: 'cash',
      );
    }

    test('custom advance above required sticks on the booking', () async {
      final booking = await customWalkIn(advance: 5000);
      expect(booking.advancePaid, 5000);
      expect(booking.remainingBalance, 2500);
      expect(booking.status, 'paid');
      expect(booking.advancePaymentMethod, 'cash');
      final reloaded = await di
          .sl<BookingRemoteDataSource>()
          .getBookingById(booking.bookingId);
      expect(reloaded?.advancePaid, 5000);
      expect(reloaded?.remainingBalance, 2500);
    });

    test('custom advance below required sticks as approved', () async {
      final booking = await customWalkIn(advance: 1000);
      expect(booking.advancePaid, 1000);
      expect(booking.remainingBalance, 6500);
      expect(booking.status, 'approved');
      final reloaded = await di
          .sl<BookingRemoteDataSource>()
          .getBookingById(booking.bookingId);
      expect(reloaded?.advancePaid, 1000);
    });

    test('custom advance covering the full total sticks', () async {
      final booking = await customWalkIn(advance: 7500);
      expect(booking.advancePaid, 7500);
      expect(booking.remainingBalance, 0);
      expect(booking.status, 'paid');
    });
  });

  group('wizard: custom advance typed at step 3', () {
    testWidgets('custom advance sticks on the created booking',
        (tester) async {
      await di.sl<CustomerRemoteDataSource>().upsertCustomer(
            CustomerEntity(
              customerId: 'cust-reg-2',
              shopId: 'shop-1',
              name: 'Bilal Ahmed',
              phone: '03001234567',
              cnic: '35202-1234567-2',
              createdAt: DateTime(2026, 11, 1),
            ),
          );
      await di.sl<FleetRemoteDataSource>()
          .addVehicle(shopId: 'shop-1', vehicle: testVehicle.copyWith(vehicleId: 'veh-walkin-2', plateNumber: 'LEA-1001'));

      final router = GoRouter(
        initialLocation: RouteNames.ownerManualBooking,
        routes: [
          GoRoute(
            path: RouteNames.ownerManualBooking,
            builder: (context, state) =>
                const OwnerManualBookingView(),
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingConfirm,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return OwnerManualBookingConfirmView(
                customerId: extra?['customerId'] as String,
                customerName: extra?['customerName'] as String,
                customerPhone: extra?['customerPhone'] as String,
                customerCnic: extra?['customerCnic'] as String,
                guarantor: extra?['guarantor'] as GuarantorSelection?,
                vehicle: extra?['vehicle'] as VehicleEntity,
                package: extra?['package'] as VehiclePackageEntity,
                isWithDriver: extra?['isWithDriver'] as bool? ?? false,
                isOutOfCity: extra?['isOutOfCity'] as bool? ?? false,
                pickupTime: extra?['pickupTime'] as DateTime,
                returnTime: extra?['returnTime'] as DateTime,
                fixedRoute: extra?['fixedRoute'] as FixedRouteEntity?,
                rentAmount: extra?['rentAmount'] as int? ?? 0,
                driverAmount: extra?['driverAmount'] as int? ?? 0,
                discountAmountPkr:
                    (extra?['discountAmountPkr'] as num?)?.toDouble(),
                advanceReceived: extra?['advanceReceived'] as int? ?? 0,
                paymentMethod:
                    extra?['paymentMethod'] as String? ?? 'cash',
                depositAmountPkr:
                    (extra?['depositAmountPkr'] as num?)?.toDouble(),
                depositMethod:
                    extra?['depositMethod'] as String? ?? 'cash',
                addRemainingToDues:
                    extra?['addRemainingToDues'] as bool? ?? true,
              );
            },
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingReceipt,
            builder: (context, state) {
              final booking =
                  (state.extra as Map<String, dynamic>?)?['booking']
                      as BookingEntity?;
              return Scaffold(
                body: Center(
                    child: Text('receipt:${booking?.bookingId ?? 'none'}')),
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      // Step 1: pick the registered customer.
      await tester.tap(find.text('Bilal Ahmed').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: select this test's own car (the first car is
      // pre-selected, and it is busy from the earlier wizard test),
      // then pick the 24h package (total Rs. 6,000, no driver).
      await tester.tap(find.text('LEA-1001'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('24h').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: type a CUSTOM advance over the prefilled required
      // advance (discount, advance, deposit fields in order).
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(1), '5000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: the summary must show the custom advance, and the
      // save must persist it — not the prefilled required advance.
      expect(find.text('Booking Summary'), findsOneWidget);
      expect(find.textContaining('Rs. 5,000'), findsWidgets);
      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining('receipt:RH-'), findsOneWidget);
      final ds = di.sl<BookingRemoteDataSource>();
      final bookings = await ds.getShopBookings('shop-1');
      final created = bookings.last;
      expect(created.advancePaid, 5000);
      expect(created.status, 'paid');
      expect(created.remainingBalance, 1000);
      expect(created.totalAmount, 6000,
          reason: 'no driver was chosen, so no driver charge');
    });

    testWidgets('no-driver walk-in, dues OFF, advance = full rent saves',
        (tester) async {
      await di.sl<CustomerRemoteDataSource>().upsertCustomer(
            CustomerEntity(
              customerId: 'cust-reg-3',
              shopId: 'shop-1',
              name: 'Usman Ali',
              phone: '03001234567',
              cnic: '35202-1234567-3',
              createdAt: DateTime(2026, 11, 1),
            ),
          );
      await di.sl<FleetRemoteDataSource>()
          .addVehicle(shopId: 'shop-1', vehicle: testVehicle.copyWith(vehicleId: 'veh-walkin-3', plateNumber: 'LEA-1002'));

      final router = GoRouter(
        initialLocation: RouteNames.ownerManualBooking,
        routes: [
          GoRoute(
            path: RouteNames.ownerManualBooking,
            builder: (context, state) =>
                const OwnerManualBookingView(),
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingConfirm,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return OwnerManualBookingConfirmView(
                customerId: extra?['customerId'] as String,
                customerName: extra?['customerName'] as String,
                customerPhone: extra?['customerPhone'] as String,
                customerCnic: extra?['customerCnic'] as String,
                guarantor: extra?['guarantor'] as GuarantorSelection?,
                vehicle: extra?['vehicle'] as VehicleEntity,
                package: extra?['package'] as VehiclePackageEntity,
                isWithDriver: extra?['isWithDriver'] as bool? ?? false,
                isOutOfCity: extra?['isOutOfCity'] as bool? ?? false,
                pickupTime: extra?['pickupTime'] as DateTime,
                returnTime: extra?['returnTime'] as DateTime,
                fixedRoute: extra?['fixedRoute'] as FixedRouteEntity?,
                rentAmount: extra?['rentAmount'] as int? ?? 0,
                driverAmount: extra?['driverAmount'] as int? ?? 0,
                discountAmountPkr:
                    (extra?['discountAmountPkr'] as num?)?.toDouble(),
                advanceReceived: extra?['advanceReceived'] as int? ?? 0,
                paymentMethod:
                    extra?['paymentMethod'] as String? ?? 'cash',
                depositAmountPkr:
                    (extra?['depositAmountPkr'] as num?)?.toDouble(),
                depositMethod:
                    extra?['depositMethod'] as String? ?? 'cash',
                addRemainingToDues:
                    extra?['addRemainingToDues'] as bool? ?? true,
              );
            },
          ),
          GoRoute(
            path: RouteNames.ownerManualBookingReceipt,
            builder: (context, state) {
              final booking =
                  (state.extra as Map<String, dynamic>?)?['booking']
                      as BookingEntity?;
              return Scaffold(
                body: Center(
                    child: Text('receipt:${booking?.bookingId ?? 'none'}')),
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      // Step 1: pick the registered customer.
      await tester.tap(find.text('Usman Ali').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: this test's own car, 24h package, NO driver
      // (the toggle stays off).
      await tester.tap(find.text('LEA-1002'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('24h').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: advance = the full rent (Rs. 6,000), dues OFF.
      // Before the driver fix the draft total is Rs. 7,500 (the
      // phantom Rs. 1,500 driver charge), so the dues gate refuses
      // the save even though the whole rent was collected.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '6000');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4 must be reachable and the save must go through.
      expect(find.text('Booking Summary'), findsOneWidget,
          reason: 'the full rent was collected with dues off');
      await tester.ensureVisible(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();

      expect(find.textContaining('receipt:RH-'), findsOneWidget);
      final ds = di.sl<BookingRemoteDataSource>();
      final bookings = await ds.getShopBookings('shop-1');
      final created = bookings.last;
      expect(created.totalAmount, 6000);
      expect(created.advancePaid, 6000);
      expect(created.remainingBalance, 0);
      expect(created.status, 'paid');
    });
  });
}
