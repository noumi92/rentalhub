import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/package_tier_list.dart';
import 'package:rentalhub/features/bookings/utils/package_pricing.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fare_table_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_calendar_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_price_estimate_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_shop_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_published_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/onboarding/shop_approval_status_step_widget.dart';
import 'package:rentalhub/features/owner/presentation/widgets/onboarding/shop_review_step_widget.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Audit §5 implementation (worker D): Monthly package, custom rates,
// Per KM toggle, fare table, price estimate, published confirmation,
// owner vehicle detail, onboarding Review + status timeline, fleet
// card (simplified 2026-11-09: Rates / Out-of-city rules, no switch,
// no "On Rent until" row), shop settings, multi-car fleet calendar.
// Pure widget/entity tests; the rate matrix save goes through DI
// (in-memory fallback), like the Phase B tests.
class _TestAssetBundle extends AssetBundle {
  static final ByteData _pixel = ByteData.view(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ).buffer);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec()
          .encodeMessage(<String, Object>{})!;
    }
    return _pixel;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: Scaffold(body: child),
    ),
  );
}

const _vehicle = VehicleEntity(
  vehicleId: 'veh-d-1',
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
  monthlyRate: 216000,
  securityDepositPkr: 20000,
  advanceRequiredPkr: 3000,
  extraHourPkr: 600,
  extraKmPkr: 100,
  outOfCityKmPerDay: 350,
  withDriverSurchargePkr: 1500,
  fuelPolicy: 'Same to Same',
  packages: [
    VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
    VehiclePackageEntity(label: '3h', hours: 3, pricePkr: 3500, kmIncluded: 40),
    VehiclePackageEntity(label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
    VehiclePackageEntity(label: '12h', hours: 12, pricePkr: 5400, kmIncluded: 150),
    VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250),
    VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750),
    VehiclePackageEntity(label: 'Monthly', hours: 720, pricePkr: 216000, kmIncluded: 7500),
  ],
  customRates: [
    CustomRateEntity(name: 'Airport transfer', pricePkr: 3000, period: 'daily'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Monthly package', () {
    test('old documents derive Monthly at daily x 24', () {
      const old = VehicleModel(
        vehicleId: 'veh-old-d',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2022,
        plateNumber: 'ICT-9912',
        rates: VehicleRatesEntity(daily24: 8500),
      );
      final monthly = old.effectivePackages.firstWhere((p) => p.label == 'Monthly');
      expect(monthly.pricePkr, 8500 * 24);
      expect(monthly.hours, 720);
      expect(monthly.kmIncluded, 7500);
      expect(old.effectivePackages.length, 7);
    });

    test('stored monthlyRate overrides the derivation', () {
      const old = VehicleModel(
        vehicleId: 'veh-old-d2',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2022,
        plateNumber: 'ICT-9912',
        rates: VehicleRatesEntity(daily24: 8500),
        monthlyRate: 180000,
      );
      final monthly = old.effectivePackages.firstWhere((p) => p.label == 'Monthly');
      expect(monthly.pricePkr, 180000);
    });

    test('picker offers Monthly and totals per 30-day block', () {
      final options = PackageTierList.optionsFor(
        vehicle: _vehicle,
        isWithDriver: false,
        dailySelfDriveRate: 9000,
        dailyWithDriverRate: 10500,
        hourlyRate: 1500,
      );
      expect(options.map((o) => o.label), contains('Monthly'));
      final monthly = options.firstWhere((o) => o.label == 'Monthly');
      expect(PackagePricing.rateFor(vehicle: _vehicle, tier: monthly, durationDays: 30, isWithDriver: false), 216000);
      expect(PackagePricing.rateFor(vehicle: _vehicle, tier: monthly, durationDays: 45, isWithDriver: false), 432000);
    });
  });

  group('Custom rates + Per KM toggle', () {
    test('custom rates and the toggle round-trip through the model', () {
      final model = VehicleModel.fromEntity(_vehicle);
      final restored = VehicleModel.fromMap(model.toMap(), 'veh-d-1');
      expect(restored.toMap(), model.toMap());
      expect(restored.customRates.length, 1);
      expect(restored.customRates.first.name, 'Airport transfer');
      expect(restored.customRates.first.period, 'daily');
      expect(restored.perKmPricingEnabled, isTrue);
    });

    test('a vehicle without custom rates defaults to empty + per-KM on', () {
      const plain = VehicleModel(
        vehicleId: 'veh-plain',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Yaris',
        year: 2023,
        plateNumber: 'LEA-23-1122',
        rates: VehicleRatesEntity(daily24: 6500),
      );
      final restored = VehicleModel.fromMap(plain.toMap(), 'veh-plain');
      expect(restored.customRates, isEmpty);
      expect(restored.perKmPricingEnabled, isTrue);
    });
  });

  group('Rate matrix', () {
    testWidgets('09b editor: seven chips, Per KM toggle, no custom-rates UI', (tester) async {
      bool saved = false;
      await tester.pumpWidget(_wrap(OwnerRateMatrixView(
        vehicle: _vehicle,
        onRatesSaved: () => saved = true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Package rates'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      expect(find.text('Monthly Package (30 Days)'), findsOneWidget);
      expect(find.text('Per KM Pricing?'), findsOneWidget);
      expect(find.text('Applies to all packages'), findsOneWidget);
      expect(find.text('Out-of-City Daily (24h)'), findsOneWidget);
      // 09b has no custom-rates editor and no estimate link — the
      // stored custom rates pass through the save untouched (covered
      // by update_vehicle_usecase_test.dart).
      expect(find.text('Custom Rates'), findsNothing);
      expect(find.text('Airport transfer'), findsNothing);
      expect(find.text('View estimated rates'), findsNothing);

      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
    });
  });

  group('Fare table', () {
    testWidgets('tabs render real packages; Monthly tab shows the Monthly row', (tester) async {
      await tester.pumpWidget(_wrap(OwnerFareTableView(vehicle: _vehicle)));
      await tester.pumpAndSettle();

      expect(find.text('In-City'), findsOneWidget);
      expect(find.text('Out-City'), findsOneWidget);
      expect(find.text('Hourly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Default Free delivery'), findsOneWidget);
      expect(find.text('Weekly Package (7 Days)'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Package (30 Days)'), findsOneWidget);
      expect(find.text('Rs. 216,000'), findsOneWidget);
    });
  });

  group('Price estimate', () {
    testWidgets('shows the In-City / Out-City / Weekly / Monthly breakdown', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPriceEstimateView(vehicle: _vehicle)));
      await tester.pumpAndSettle();

      expect(find.text('Estimated Rates'), findsWidgets);
      expect(find.text('In-City / Day'), findsOneWidget);
      expect(find.text('Out-City / Day'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Rs. 9,000'), findsWidgets);
      expect(find.text('Rs. 216,000'), findsOneWidget);
      expect(find.text('Go to My Cars'), findsOneWidget);
    });
  });

  group('Published confirmation', () {
    // RQ-F1 (2026-11-13): the listing actions are hidden until the
    // public landing page exists — the screen shows the car, the rate,
    // the agreed link shape and the honest note instead of dead links.
    testWidgets('shows the car, the daily rate and the honest note, not the share actions', (tester) async {
      await tester.pumpWidget(_wrap(OwnerVehiclePublishedView(vehicle: _vehicle)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Honda Civic Oriel'), findsWidgets);
      expect(find.text('Rs. 9,000/day'), findsOneWidget);
      expect(find.textContaining('https://rentalhub.62onlinestore.com/vehicle/veh-d-1'), findsOneWidget);
      expect(find.text('The web listing page behind this link is not live yet.'), findsOneWidget);
      expect(find.text('View in App'), findsNothing);
      expect(find.text('Copy Link'), findsNothing);
      expect(find.text('Share Listing'), findsNothing);
    });
  });

  group('Owner vehicle detail', () {
    testWidgets('shows identity, rates and bookings with owner actions', (tester) async {
      final booking = BookingEntity(
        bookingId: 'b-1',
        customerId: 'c-1',
        shopId: 'shop-1',
        vehicleId: 'veh-d-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 10),
        returnTime: DateTime(2026, 10, 29, 10),
        totalAmount: 27000,
        advanceRequired: 3000,
        advancePaid: 3000,
        remainingBalance: 24000,
        status: 'active',
        customerName: 'Ali Raza',
      );
      await tester.pumpWidget(_wrap(OwnerVehicleDetailView(
        vehicle: _vehicle,
        bookings: [booking],
      )));
      await tester.pumpAndSettle();

      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.textContaining('Rs. 9,000'), findsWidgets);
      expect(find.text('Ali Raza'), findsOneWidget);
      expect(find.text('Manage rates'), findsOneWidget);
      expect(find.text('Booking calendar'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Fare table'), findsOneWidget);
    });
  });

  group('Fleet card (O05/O30)', () {
    testWidgets('rented car shows On Rent badge and the two simple actions', (tester) async {
      const rented = VehicleEntity(
        vehicleId: 'veh-rented-d',
        shopId: 'shop-1',
        make: 'Honda',
        model: 'Civic',
        year: 2021,
        plateNumber: 'LEA-21-1000',
        status: 'rented',
        rates: VehicleRatesEntity(daily24: 9000),
      );
      var ratesTapped = false;
      var rulesTapped = false;
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: rented,
        onEditRates: () => ratesTapped = true,
        onOutCityRules: () => rulesTapped = true,
      )));
      await tester.pumpAndSettle();

      // Simplified card (2026-11-09): no "On Rent until" row, no
      // Edit Rent / Update Price, no availability switch.
      expect(find.text('On Rent'), findsOneWidget);
      expect(find.textContaining('On Rent until'), findsNothing);
      expect(find.text('Edit Rent'), findsNothing);
      expect(find.text('Update Price'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
      await tester.tap(find.text('Rates'));
      await tester.tap(find.text('Out-of-city rules'));
      expect(ratesTapped, isTrue);
      expect(rulesTapped, isTrue);
    });

    testWidgets('available car shows Available badge and no On Rent line', (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Available'), findsOneWidget);
      expect(find.textContaining('On Rent until'), findsNothing);
      expect(find.text('On Rent'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
    });
  });

  group('Onboarding Review + status', () {
    testWidgets('review shows every entered value', (tester) async {
      // Production hosts the step in a SingleChildScrollView — the
      // standalone pump must too, or the tall content overflows.
      await tester.pumpWidget(_wrap(const SingleChildScrollView(
          child: ShopReviewStepWidget(
        shopName: 'Al-Falah Rent a Car',
        ownerName: 'Ahmed Raza',
        cnic: '35202-1234567-1',
        whatsapp: '03001234567',
        phone: '03001234567',
        openingHours: '9:00 AM - 10:00 PM',
        shopLogoName: 'logo.png',
        address: 'Main Boulevard, Lahore',
        city: 'Lahore',
        payoutMethods: ['JazzCash', 'Meezan Bank'],
        attachedDocuments: ['CNIC front', 'Selfie with CNIC'],
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Al-Falah Rent a Car'), findsOneWidget);
      expect(find.text('Ahmed Raza'), findsOneWidget);
      expect(find.text('35202-1234567-1'), findsOneWidget);
      expect(find.text('JazzCash'), findsOneWidget);
      expect(find.text('CNIC front'), findsOneWidget);
      expect(find.text('Review your application'), findsOneWidget);
    });

    testWidgets('status shows the timeline, 24-hour line and WhatsApp button', (tester) async {
      // Production hosts the step in a SingleChildScrollView — the
      // standalone pump must too, or the tall content overflows.
      await tester.pumpWidget(_wrap(SingleChildScrollView(
          child: ShopApprovalStatusStepWidget(
        onGoToFleet: () {},
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Usually approved within 24 hours'), findsOneWidget);
      expect(find.text('Contact Admin on WhatsApp'), findsOneWidget);
      expect(find.text('Manage Fleet & Add Vehicles'), findsOneWidget);
    });
  });

  group('Shop settings + fleet calendar', () {
    testWidgets('shop settings shows an honest error when Firestore is unavailable', (tester) async {
      await tester.pumpWidget(_wrap(const OwnerShopSettingsView()));
      await tester.pumpAndSettle();

      expect(find.text('Could not load shop settings.'), findsOneWidget);
    });

    testWidgets('fleet calendar shows the empty state for an empty fleet', (tester) async {
      await tester.pumpWidget(_wrap(const OwnerFleetCalendarView()));
      await tester.pumpAndSettle();

      expect(find.text('Fleet Schedule'), findsWidgets);
      expect(find.text('No cars in your fleet yet'), findsOneWidget);
    });
  });
}
