import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_out_city_rules_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// 010b "Out-of-city rules" (deck p.4): the car-level shared rules —
// editable home-city boundary, the shop's fixed routes, trip charges
// (fuel policy, deposit, advance, driver night stay per night,
// tolls & parking). No in-city pricing, no per-package fields,
// no boundary map.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const baseVehicle = VehicleEntity(
    vehicleId: 'veh-rules-10b',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla GLi',
    year: 2022,
    plateNumber: 'LEA-22-7000',
    rates: VehicleRatesEntity(daily24: 7000, outOfCityDaily: 9500),
    securityDepositPkr: 25000,
    advanceRequiredPkr: 2000,
    fuelPolicy: 'Same to Same',
  );

  Future<void> pumpRules(WidgetTester tester, {VehicleEntity vehicle = baseVehicle}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OwnerOutCityRulesView(vehicle: vehicle),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextField fieldWithText(WidgetTester tester, String value) =>
      tester.widgetList<TextField>(find.byType(TextField)).firstWhere((f) => f.controller?.text == value);

  group('010b out-of-city rules', () {
    testWidgets('boundary shows the stored city and radius', (tester) async {
      const stored = VehicleEntity(
        vehicleId: 'veh-rules-10b',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla GLi',
        year: 2022,
        plateNumber: 'LEA-22-7000',
        rates: VehicleRatesEntity(daily24: 7000, outOfCityDaily: 9500),
        homeCity: 'Islamabad',
        homeCityRadiusKm: 60,
      );
      await pumpRules(tester, vehicle: stored);
      expect(find.text('Out-of-city rules'), findsOneWidget);
      expect(find.text('Applies to all packages'), findsOneWidget);
      expect(find.text('Islamabad · 60 km'), findsOneWidget);
    });

    testWidgets('boundary defaults to Lahore / 40 km when unset', (tester) async {
      await pumpRules(tester);
      expect(find.text('Lahore · 40 km'), findsOneWidget);
      expect(find.text('Trip charges'), findsOneWidget);
      expect(find.text('Fuel Policy'), findsOneWidget);
    });

    testWidgets('fixed routes list renders with an Add route button', (tester) async {
      await pumpRules(tester);
      // Seeded in-memory routes for shop-1.
      expect(find.text('Lahore → Islamabad'), findsOneWidget);
      expect(find.text('Lahore → Murree'), findsOneWidget);
      expect(find.text('Add Fixed Route'), findsOneWidget);
    });

    testWidgets('empty shop shows the fixed-routes empty state', (tester) async {
      const emptyShop = VehicleEntity(
        vehicleId: 'veh-rules-empty',
        shopId: 'shop-no-routes',
        make: 'Toyota',
        model: 'Corolla GLi',
        year: 2022,
        plateNumber: 'LEA-22-7000',
        rates: VehicleRatesEntity(daily24: 7000),
      );
      await pumpRules(tester, vehicle: emptyShop);
      expect(find.text('No fixed routes yet — add your first destination below.'), findsOneWidget);
      expect(find.text('Add Fixed Route'), findsOneWidget);
    });

    testWidgets('night stay defaults to Rs 2,000 and tolls to Paid by customer', (tester) async {
      await pumpRules(tester);
      expect(find.text('Driver night stay (per night)'), findsOneWidget);
      expect(find.text('Charged for each night away from the home city'), findsOneWidget);
      // Both the advance and the night stay default to 2000.
      expect(find.text('Paid by customer'), findsOneWidget);
      final nightStay = tester.widgetList<TextField>(find.byType(TextField)).where((f) => f.controller?.text == '2000');
      expect(nightStay.length, 2);
    });

    testWidgets('stored night stay and tolls choice render instead of the defaults', (tester) async {
      const stored = VehicleEntity(
        vehicleId: 'veh-rules-10b',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla GLi',
        year: 2022,
        plateNumber: 'LEA-22-7000',
        rates: VehicleRatesEntity(daily24: 7000, outOfCityDaily: 9500),
        driverNightStayPkr: 2500,
        tollsPaidBy: 'included',
      );
      await pumpRules(tester, vehicle: stored);
      expect(find.text('Included in rent'), findsOneWidget);
      expect(find.text('Paid by customer'), findsNothing);
      expect(find.byWidget(fieldWithText(tester, '2500')), findsOneWidget);
    });

    testWidgets('Edit dialog changes the boundary and Save rules persists it', (tester) async {
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: baseVehicle);
      await pumpRules(tester);
      expect(find.text('Lahore · 40 km'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Home city boundary'), findsWidgets);
      await tester.enterText(find.byWidget(fieldWithText(tester, 'Lahore')), 'Faisalabad');
      await tester.enterText(find.byWidget(fieldWithText(tester, '40')), '25');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Faisalabad · 25 km'), findsOneWidget);

      // Change a trip charge too, then save.
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      await tester.enterText(find.byWidget(fields.firstWhere((f) => f.controller?.text == '25000')), '30000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save rules'));
      await tester.pumpAndSettle();

      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-rules-10b');
      expect(stored.homeCity, 'Faisalabad');
      expect(stored.homeCityRadiusKm, 25);
      expect(stored.securityDepositPkr, 30000);
      // Pricing the editor does not own is untouched.
      expect(stored.rates.daily24, 7000);
      expect(stored.rates.outOfCityDaily, 9500);
    });

    testWidgets('edit night stay + tolls and Save rules persists them', (tester) async {
      // Distinct advance (3000) so the 2000 night-stay field is unique.
      const nightVehicle = VehicleEntity(
        vehicleId: 'veh-rules-night',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla GLi',
        year: 2022,
        plateNumber: 'LEA-22-7001',
        rates: VehicleRatesEntity(daily24: 7000, outOfCityDaily: 9500),
        securityDepositPkr: 25000,
        advanceRequiredPkr: 3000,
        fuelPolicy: 'Same to Same',
      );
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: nightVehicle);
      await pumpRules(tester, vehicle: nightVehicle);
      expect(find.text('Paid by customer'), findsOneWidget);

      await tester.enterText(find.byWidget(fieldWithText(tester, '2000')), '2500');
      await tester.ensureVisible(find.text('Paid by customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid by customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Included in rent').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save rules'));
      await tester.pumpAndSettle();

      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-rules-night');
      expect(stored.driverNightStayPkr, 2500);
      expect(stored.tollsPaidBy, 'included');
      // Pricing the editor does not own is untouched.
      expect(stored.securityDepositPkr, 25000);
      expect(stored.advanceRequiredPkr, 3000);
    });

    testWidgets('invalid radius in the Edit dialog is rejected', (tester) async {
      await pumpRules(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byWidget(fieldWithText(tester, '40')), 'abc');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      // The dialog stays open and the boundary is unchanged.
      expect(find.text('Lahore · 40 km'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
