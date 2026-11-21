import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/presentation/views/rent_package_picker_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/bookings/utils/booking_availability.dart';
import 'package:rentalhub/features/bookings/utils/package_pricing.dart';
import 'package:rentalhub/features/fleet/data/datasources/fixed_route_remote_data_source.dart';
import 'package:rentalhub/features/fleet/data/models/fixed_route_model.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/fleet/data/repositories/fixed_route_repository_impl.dart';
import 'package:rentalhub/features/fleet/domain/entities/fixed_route_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/usecases/delete_fixed_route_usecase.dart';
import 'package:rentalhub/features/fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import 'package:rentalhub/features/fleet/domain/usecases/save_fixed_route_usecase.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/package_tier_list.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fixed_routes_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_calendar_view.dart';

// Owner Module Plan — Phase B (B3): in/out-city rates with km limits
// and an extra-km charge, fixed out-of-city routes per shop, and the
// booking calendar (availability per vehicle, shared with the picker).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-b3-1',
    shopId: 'shop-1',
    make: 'Honda',
    model: 'Civic Oriel',
    year: 2021,
    plateNumber: 'LEA-4820',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 9000,
      outOfCityDaily: 11500,
    ),
    weeklyRate: 52000,
    securityDepositPkr: 20000,
    advanceRequiredPkr: 3000,
    extraHourPkr: 600,
    extraKmPkr: 100,
    outOfCityKmPerDay: 350,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250),
      VehiclePackageEntity(
          label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750),
    ],
  );

  group('Phase B (B3) — vehicle pricing fields', () {
    test('extra-km charge and out-of-city km survive a round-trip', () {
      final model = VehicleModel.fromEntity(testVehicle);
      final restored = VehicleModel.fromMap(model.toMap(), 'veh-b3-1');
      expect(restored.extraKmPkr, 100);
      expect(restored.outOfCityKmPerDay, 350);
      expect(restored.toMap(), model.toMap());
    });
  });

  group('Phase B (B3) — fixed routes', () {
    test('route model round-trips', () {
      const route = FixedRouteModel(
        routeId: 'route-test-1',
        shopId: 'shop-b3-test',
        originCity: 'Lahore',
        destinationCity: 'Islamabad',
        distanceKm: 300,
        fixedPricePkr: 18000,
      );
      final restored = FixedRouteModel.fromMap(route.toMap(), 'route-test-1');
      expect(restored, equals(route));
      expect(restored.displayName, 'Lahore → Islamabad');
    });

    test('shop seeds, save, toggle and delete', () async {
      final ds = FixedRouteRemoteDataSource();
      final repo = FixedRouteRepositoryImpl(remoteDataSource: ds);
      final get = GetShopFixedRoutesUseCase(repo);
      final save = SaveFixedRouteUseCase(repo);
      final remove = DeleteFixedRouteUseCase(repo);

      final seeds = await get('shop-1');
      expect(seeds.length, 6);
      expect(seeds.map((r) => r.destinationCity).toList(),
          containsAll(['Islamabad', 'Murree', 'Karachi']));
      expect(seeds.every((r) => r.enabled), isTrue);

      const newRoute = FixedRouteEntity(
        routeId: 'route-b3-new',
        shopId: 'shop-b3-test',
        originCity: 'Lahore',
        destinationCity: 'Multan',
        distanceKm: 340,
        fixedPricePkr: 20000,
      );
      await save(newRoute);
      var mine = await get('shop-b3-test');
      expect(mine.length, 1);
      expect(mine.first.fixedPricePkr, 20000);

      await save(newRoute.copyWith(enabled: false, fixedPricePkr: 21000));
      mine = await get('shop-b3-test');
      expect(mine.first.enabled, isFalse);
      expect(mine.first.fixedPricePkr, 21000);

      await remove('route-b3-new');
      mine = await get('shop-b3-test');
      expect(mine, isEmpty);
    });

    test('save rejects a route without a destination or a price', () async {
      final ds = FixedRouteRemoteDataSource();
      final repo = FixedRouteRepositoryImpl(remoteDataSource: ds);
      final save = SaveFixedRouteUseCase(repo);
      expect(
        () => save(const FixedRouteEntity(
          routeId: 'x',
          shopId: 's',
          originCity: 'Lahore',
          destinationCity: '',
          distanceKm: 100,
          fixedPricePkr: 1000,
        )),
        throwsArgumentError,
      );
      expect(
        () => save(const FixedRouteEntity(
          routeId: 'x',
          shopId: 's',
          originCity: 'Lahore',
          destinationCity: 'Multan',
          distanceKm: 100,
          fixedPricePkr: 0,
        )),
        throwsArgumentError,
      );
    });

    testWidgets('fixed routes view lists the seeded routes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerFixedRoutesView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fixed Out-of-City Routes'), findsOneWidget);
      expect(find.text('Lahore → Islamabad'), findsOneWidget);
      // Audit §8: the add-route form now sits above the list, so the
      // 6th seeded route is below the fold in the default viewport
      // and the lazy ListView only builds it once scrolled to. The
      // ListView's own Scrollable is the first Scrollable in the tree
      // (the form's TextFields each contain one too).
      await tester.scrollUntilVisible(
        find.text('Lahore → Karachi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Lahore → Karachi'), findsOneWidget);
      expect(find.text('300 km • Rs. 18,000 fixed'), findsOneWidget);
    });
  });

  group('Phase B (B3) — booking trip fields and availability', () {
    test('booking round-trips tripType, kmLimit and trackerCleared', () {
      final model = BookingModel(
        bookingId: 'RH-test-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-b3-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 10, 9),
        returnTime: DateTime(2026, 11, 12, 9),
        totalAmount: 23000,
        remainingBalance: 23000,
        tripType: 'out_of_city',
        kmLimit: 700,
      );
      final restored = BookingModel.fromMap(model.toMap(), 'RH-test-1');
      expect(restored.tripType, 'out_of_city');
      expect(restored.kmLimit, 700);
      expect(restored.trackerCleared, isFalse);
      // fromMap backfills a missing origin: 'cust-1' is not a
      // walk-in id, so the restored map gains 'origin': 'online'.
      expect(restored.origin, 'online');
      expect(restored.toMap(), {...model.toMap(), 'origin': 'online'});
    });

    test('getVehicleBookings returns intervals, not cancelled ones',
        () async {
      final ds = BookingRemoteDataSource();
      final now = DateTime.now();
      final created = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-b3-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: now.add(const Duration(days: 1)),
        returnTime: now.add(const Duration(days: 3)),
        totalAmount: 18000,
        advanceRequired: 3000,
        tripType: 'out_of_city',
        kmLimit: 700,
        customerName: 'Test Customer',
      );
      final cancelled = await ds.createBookingRequest(
        customerId: 'cust-2',
        shopId: 'shop-1',
        vehicleId: 'veh-b3-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: now.add(const Duration(days: 5)),
        returnTime: now.add(const Duration(days: 6)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await ds.updateBookingStatus(
          bookingId: cancelled.bookingId, status: 'cancelled');

      final bookings = await ds.getVehicleBookings('veh-b3-1');
      expect(bookings.length, 1);
      expect(bookings.first.bookingId, created.bookingId);
      expect(bookings.first.tripType, 'out_of_city');
      expect(bookings.first.kmLimit, 700);

      final blocked = blockedDaysOf(bookings);
      expect(blocked.length, 3);
      expect(
        isDayBlocked(bookings, now.add(const Duration(days: 2))),
        isTrue,
      );
      expect(
        isDayBlocked(bookings, now.add(const Duration(days: 4))),
        isFalse,
      );
      expect(isDayConfirmed(bookings, now.add(const Duration(days: 2))),
          isFalse);
    });

    testWidgets('calendar view shows a booked day and its booking',
        (tester) async {
      // Tall surface so the whole calendar (grid + legend + day list)
      // is inside the viewport and the lazy ListView builds it all.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final ds = di.sl<BookingRemoteDataSource>();
      final now = DateTime.now();
      final pickup = DateTime(now.year, now.month, now.day + 1, 9);
      await ds.createBookingRequest(
        customerId: 'cust-cal',
        shopId: 'shop-1',
        vehicleId: 'veh-cal-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: pickup,
        returnTime: pickup.add(const Duration(days: 2)),
        totalAmount: 18000,
        advanceRequired: 3000,
        customerName: 'Calendar Customer',
      );
      const vehicle = VehicleEntity(
        vehicleId: 'veh-cal-1',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2022,
        plateNumber: 'ICT-9912',
        rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
      );
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerVehicleCalendarView(vehicle: vehicle),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Booking Calendar'), findsOneWidget);
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);

      await tester.tap(find.text('${pickup.day}').first);
      await tester.pumpAndSettle();
      expect(find.text('Calendar Customer'), findsOneWidget);
    });
  });

  group('Phase B (B3) — picker out-of-city pricing', () {
    test('out-of-city tiers scale by the daily-rate ratio', () {
      final options = PackageTierList.optionsFor(
        vehicle: testVehicle,
        isWithDriver: false,
        dailySelfDriveRate: 9000,
        dailyWithDriverRate: 10500,
        hourlyRate: 1500,
        isOutOfCity: true,
      );
      final daily = options.firstWhere((o) => o.label == '24h');
      expect(daily.price, 11500);
      expect(daily.kmIncluded, '350 km/day');
      final weekly = options.firstWhere((o) => o.label == 'Weekly');
      expect(weekly.price, (52000 * 11500 / 9000).round());
    });

    test('pricing helpers: rate, advance and km limit', () {
      final options = PackageTierList.optionsFor(
        vehicle: testVehicle,
        isWithDriver: false,
        dailySelfDriveRate: 9000,
        dailyWithDriverRate: 10500,
        hourlyRate: 1500,
      );
      final daily = options.firstWhere((o) => o.label == '24h');
      expect(
        PackagePricing.rateFor(
          vehicle: testVehicle,
          tier: daily,
          durationDays: 2,
          isWithDriver: true,
          driverRatePerDayPkr: 1500,
        ),
        21000, // (9000 + 1500) x 2
      );
      expect(
        PackagePricing.advanceFor(vehicle: testVehicle, total: 21000),
        3000,
      );
      expect(
        PackagePricing.kmLimitFor(tier: daily, durationDays: 2),
        500,
      );
    });

    testWidgets('out-of-city toggle reprices and records the trip',
        (tester) async {
      Map<String, dynamic>? draft;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RentPackagePickerView(
            carId: 'veh-b3-1',
            carName: 'Honda Civic Oriel',
            plateNumber: 'LEA-4820',
            shopId: 'shop-1',
            shopName: 'Test Shop',
            dailySelfDriveRate: 9000,
            dailyWithDriverRate: 10500,
            hourlyRate: 1500,
            vehicle: testVehicle,
            onProceedToReview: (d) => draft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('In-City'), findsOneWidget);
      expect(find.text('Out-of-City'), findsOneWidget);
      expect(find.text('Total: Rs. 9,000'), findsOneWidget);

      await tester.tap(find.text('Out-of-City'));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 11,500'), findsOneWidget);
      expect(find.text('Fixed routes from this shop'), findsOneWidget);
      expect(find.text('Islamabad • Rs. 18,000'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(draft!['tripType'], 'out_of_city');
      expect(draft!['kmLimit'], 350);
      expect(draft!['totalAmount'], 11500);
      expect(draft!['trackerCleared'], isFalse);
    });

    testWidgets('a fixed route sets the total to its fixed price',
        (tester) async {
      Map<String, dynamic>? draft;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RentPackagePickerView(
            carId: 'veh-b3-1',
            carName: 'Honda Civic Oriel',
            plateNumber: 'LEA-4820',
            shopId: 'shop-1',
            shopName: 'Test Shop',
            dailySelfDriveRate: 9000,
            dailyWithDriverRate: 10500,
            hourlyRate: 1500,
            vehicle: testVehicle,
            onProceedToReview: (d) => draft = d,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Out-of-City'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Islamabad • Rs. 18,000'));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 18,000'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(draft!['fixedRouteId'], 'route-lhr-isb');
      expect(draft!['destinationCity'], 'Islamabad');
      expect(draft!['totalAmount'], 18000);
    });
  });

  group('Phase B (B3) — routing', () {
    test('fixed-routes and calendar routes exist', () async {
      final names = await File('lib/core/routing/route_names.dart')
          .readAsString();
      final router =
          await File('lib/core/routing/app_router.dart').readAsString();
      expect(names, contains("ownerFixedRoutes = '/owner/fixed-routes'"));
      expect(names, contains("ownerCalendar = '/owner/calendar/:vehicleId'"));
      expect(router, contains('OwnerFixedRoutesView'));
      expect(router, contains('OwnerVehicleCalendarView'));
    });
  });
}
