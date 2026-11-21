import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_settings_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_settings_model.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_settings_entity.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/package_tier_list.dart';
import 'package:rentalhub/features/bookings/utils/package_pricing.dart';
import 'package:rentalhub/features/fleet/domain/entities/fixed_route_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_car_step.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_draft.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Worker A (2026-11-21): the driver rate is SHOP-SCOPED, set in
// booking general settings (`booking_settings/{shopId}`). Pricing
// reads the setting only — the vehicle's stored
// `withDriverSurchargePkr` is ignored by every pricing path, and
// an unset (null) rate charges Rs. 0.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-booking-settings-1',
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

  const tier24 = PackageTierOption(
    label: '24h',
    hours: 24,
    title: 'Daily 24-Hours',
    subtitle: 'Full day flexibility',
    price: 6000,
    kmIncluded: '250 km/day',
  );
  const tier6 = PackageTierOption(
    label: '6h',
    hours: 6,
    title: '6-Hour Express',
    subtitle: 'City errands',
    price: 6000,
    kmIncluded: '80 km',
  );

  Widget appFor(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  group('PackagePricing follows the booking setting', () {
    test('set rate charges the surcharge per day', () {
      expect(
        PackagePricing.driverSurchargeFor(
          vehicle: testVehicle,
          tier: tier24,
          isWithDriver: true,
          driverRatePerDayPkr: 2000,
        ),
        2000,
      );
      expect(
        PackagePricing.rateFor(
          vehicle: testVehicle,
          tier: tier24,
          durationDays: 2,
          isWithDriver: true,
          driverRatePerDayPkr: 2000,
        ),
        16000, // (6000 + 2000) x 2
      );
    });

    test('hourly tiers prorate the setting rate', () {
      expect(
        PackagePricing.driverSurchargeFor(
          vehicle: testVehicle,
          tier: tier6,
          isWithDriver: true,
          driverRatePerDayPkr: 2000,
        ),
        500, // 2000 x 6/24
      );
    });

    test('unset rate charges Rs. 0 even though the vehicle stores 1500', () {
      expect(
        PackagePricing.driverSurchargeFor(
          vehicle: testVehicle,
          tier: tier24,
          isWithDriver: true,
        ),
        0,
      );
      expect(
        PackagePricing.rateFor(
          vehicle: testVehicle,
          tier: tier24,
          durationDays: 1,
          isWithDriver: true,
        ),
        6000,
      );
    });

    test('a different setting rate wins over the vehicle field', () {
      expect(
        PackagePricing.driverSurchargeFor(
          vehicle: testVehicle,
          tier: tier24,
          isWithDriver: true,
          driverRatePerDayPkr: 2500,
        ),
        2500,
      );
    });

    test('self-drive never charges, whatever the setting', () {
      expect(
        PackagePricing.driverSurchargeFor(
          vehicle: testVehicle,
          tier: tier24,
          isWithDriver: false,
          driverRatePerDayPkr: 2000,
        ),
        0,
      );
    });
  });

  group('ManualBookingPackageSelector follows the booking setting', () {
    final pkg24 =
        testVehicle.packages.firstWhere((p) => p.label == '24h');
    final pickup = DateTime(2026, 11, 20, 10);
    final twoDays = DateTime(2026, 11, 22, 10);

    test('unit/total add the setting rate per day', () {
      expect(
        ManualBookingPackageSelector.unitFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: true,
          driverRatePerDayPkr: 2000,
        ),
        8000,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: true,
          pickup: pickup,
          returnTime: twoDays,
          driverRatePerDayPkr: 2000,
        ),
        16000,
      );
    });

    test('unset rate: vehicle field ignored, total is the bare package', () {
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: testVehicle,
          package: pkg24,
          isWithDriver: true,
          pickup: pickup,
          returnTime: twoDays,
        ),
        12000,
      );
    });

    test('fixed-route total adds the setting rate per day, never x price', () {
      const route = FixedRouteEntity(
        routeId: 'route-lhr-isb',
        shopId: 'shop-1',
        originCity: 'Lahore',
        destinationCity: 'Islamabad',
        distanceKm: 300,
        fixedPricePkr: 18000,
      );
      final v = testVehicle.copyWith(outCityMode: 'fixedRoute');
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: v,
          package: pkg24,
          isWithDriver: true,
          isOutOfCity: true,
          pickup: pickup,
          returnTime: twoDays,
          fixedRoute: route,
          driverRatePerDayPkr: 2000,
        ),
        24000, // 18000 + 2000 x 2 days + 1 night x 2000 stay
      );
      expect(
        ManualBookingPackageSelector.totalFor(
          vehicle: v,
          package: pkg24,
          isWithDriver: true,
          isOutOfCity: true,
          pickup: pickup,
          returnTime: twoDays,
          fixedRoute: route,
        ),
        20000, // unset rate adds nothing; the night stay still applies
      );
    });
  });

  group('ManualBookingDraft follows the booking setting', () {
    test('driverAmount is the setting rate, 0 when unset', () {
      final draft = ManualBookingDraft(
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
      );
      draft.selectVehicle(testVehicle);
      draft.onPackageChanged(
          testVehicle.packages.firstWhere((p) => p.label == '24h'));
      draft.isWithDriver = true;
      expect(draft.driverAmount, 0);

      draft.driverRatePerDayPkr = 2000;
      expect(draft.rentAmount, 6000);
      expect(draft.driverAmount, 2000);
      expect(draft.total, 8000);
    });
  });

  group('BookingSettingsDataSource round-trip', () {
    test('save then load returns the rate; clearing returns null', () async {
      final ds = BookingSettingsDataSource();
      await ds.saveSettings(
          const BookingSettingsEntity(shopId: 'shop-1', driverRatePerDayPkr: 2500));
      var loaded = await ds.getSettings('shop-1');
      expect(loaded.driverRatePerDayPkr, 2500);

      await ds.saveSettings(
          const BookingSettingsEntity(shopId: 'shop-1').copyWith(clearDriverRate: true));
      loaded = await ds.getSettings('shop-1');
      expect(loaded.driverRatePerDayPkr, isNull);
    });

    test('missing document reads as unset', () async {
      final ds = BookingSettingsDataSource();
      final loaded = await ds.getSettings('shop-never-saved');
      expect(loaded.driverRatePerDayPkr, isNull);
    });

    test('model round-trips through a map', () {
      const model = BookingSettingsModel(
          shopId: 'shop-1', driverRatePerDayPkr: 2000);
      final restored =
          BookingSettingsModel.fromMap(model.toMap());
      expect(restored.driverRatePerDayPkr, 2000);
      expect(restored.shopId, 'shop-1');
      expect(
        BookingSettingsModel.fromMap({'shopId': 'shop-1'})
            .driverRatePerDayPkr,
        isNull,
      );
    });
  });

  group('walk-in step 2 widget follows the setting', () {
    testWidgets('toggle total uses the setting rate, not the vehicle field',
        (tester) async {
      var isWithDriver = false;
      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      await tester.pumpWidget(appFor(StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SingleChildScrollView(
            child: ManualBookingCarStep(
              isLoadingVehicles: false,
              vehiclesError: null,
              onRetryLoad: () {},
              vehicles: const [testVehicle],
              selectedVehicle: testVehicle,
              onVehicleChanged: (_) {},
              selectedPackage: pkg24,
              onPackageChanged: (_) {},
              isWithDriver: isWithDriver,
              onDriverModeChanged: (v) => setState(() => isWithDriver = v),
              isOutOfCity: false,
              pickupTime: DateTime(2026, 11, 20, 10),
              returnTime: DateTime(2026, 11, 21, 10),
              onPickupChanged: (_) {},
              onReturnChanged: (_) {},
              onTripTypeChanged: (_) {},
              onAvailabilityChanged: (_) {},
              existingBookings: const [],
              driverRatePerDayPkr: 2000,
            ),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Total: Rs. 6,000'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      // 6000 package + 2000 setting rate — NOT the vehicle's 1500.
      expect(find.text('Total: Rs. 8,000'), findsOneWidget);
    });
  });

  group('OwnerBookingSettingsView', () {
    testWidgets('shows the driver rate field and the unset note',
        (tester) async {
      await tester.pumpWidget(
          appFor(const OwnerBookingSettingsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      expect(find.text('Booking Settings'), findsOneWidget);
      expect(find.text('Driver rate (per day)'), findsOneWidget);
      expect(
          find.text(
              'Not set — trips with a driver add no extra charge.'),
          findsOneWidget);
    });

    testWidgets('typing a rate and saving confirms', (tester) async {
      await tester.pumpWidget(
          appFor(const OwnerBookingSettingsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2500');
      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Booking settings saved.'), findsOneWidget);
    });

    testWidgets('a negative rate is rejected', (tester) async {
      await tester.pumpWidget(
          appFor(const OwnerBookingSettingsView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '-5');
      await tester.tap(find.text('Save Settings'));
      await tester.pump();
      expect(
          find.text('Enter a valid driver rate (0 or more).'),
          findsOneWidget);
    });
  });
}
