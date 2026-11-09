import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// 09b "Package Rates" (deck p.4): the simple per-package editor —
// seven package chips, one price row at a time, shared out-of-city
// values. No per-package toggles, no custom-rates UI, no estimate link.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-rates-9b',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla GLi',
    year: 2022,
    plateNumber: 'LEA-22-7000',
    rates: VehicleRatesEntity(
      hourly1: 1000,
      hourly3: 2500,
      hourly6: 4000,
      daily24: 7000,
      outOfCityDaily: 9500,
    ),
    weeklyRate: 42000,
    monthlyRate: 168000,
    securityDepositPkr: 25000,
    advanceRequiredPkr: 2000,
    extraHourPkr: 500,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    extraKmPkr: 25,
    outOfCityKmPerDay: 300,
    packages: [
      VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1000, kmIncluded: 15),
      VehiclePackageEntity(label: '3h', hours: 3, pricePkr: 2500, kmIncluded: 40),
      VehiclePackageEntity(label: '6h', hours: 6, pricePkr: 4000, kmIncluded: 80),
      VehiclePackageEntity(label: '12h', hours: 12, pricePkr: 4200, kmIncluded: 150),
      VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 7000, kmIncluded: 250),
      VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 42000, kmIncluded: 1750),
      VehiclePackageEntity(label: 'Monthly', hours: 720, pricePkr: 168000, kmIncluded: 7500),
    ],
  );

  Future<void> pumpEditor(WidgetTester tester, {VoidCallback? onSaved}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OwnerRateMatrixView(vehicle: testVehicle, onRatesSaved: onSaved),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The chips are one horizontal scrolling row — scroll a far chip
  /// into view before tapping it, or the tap misses.
  Future<void> tapChip(WidgetTester tester, int index) async {
    final finder = find.byType(ChoiceChip).at(index);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool fieldShows(WidgetTester tester, String value) =>
      tester.widgetList<TextField>(find.byType(TextField)).any((f) => f.controller?.text == value);

  /// The §2 mode pills sit below the fold in the 800×600 test
  /// viewport — scroll them into view before tapping, or the tap
  /// misses and the mode never switches.
  Future<void> tapModeSegment(WidgetTester tester, String label) async {
    final finder = find.text(label).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('09b package rates editor', () {
    testWidgets('shows all seven package chips and the daily price by default', (tester) async {
      await pumpEditor(tester);
      expect(find.text('Package rates'), findsOneWidget);
      expect(find.text('Toyota Corolla GLi (2022)'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      for (final label in ['1-Hour City Commute', '3-Hour Airport / Quick Trip', '6-Hour Express Rate', '12-Hour Half Day', 'Weekly Package (7 Days)', 'Monthly Package (30 Days)']) {
        expect(find.text(label), findsOneWidget);
      }
      // The daily label appears twice: its chip AND its price row.
      expect(find.text('In-City Daily (24h)'), findsWidgets);
      // Default selection is the daily package.
      expect(fieldShows(tester, '7000'), isTrue);
      expect(find.text('Out-City Rent Rates'), findsOneWidget);
      expect(find.text('Applies to all packages'), findsOneWidget);
    });

    testWidgets('no per-package enable toggles, no custom rates, no estimate link', (tester) async {
      await pumpEditor(tester);
      // Only the two drive-mode switches + the Per KM switch remain.
      expect(find.byType(Switch), findsNWidgets(3));
      expect(find.text('Switch a package off to hide it from customers.'), findsNothing);
      expect(find.text('View estimated rates'), findsNothing);
    });

    testWidgets('switching chips changes the displayed price and keeps edits', (tester) async {
      await pumpEditor(tester);
      // Chips are in package order: 1h, 3h, 6h, 12h, 24h, Weekly, Monthly.
      await tapChip(tester, 3);
      expect(fieldShows(tester, '4200'), isTrue);

      // Edit the 12h price, switch away and back — the edit survives.
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final priceField = fields.firstWhere((f) => f.controller?.text == '4200');
      await tester.enterText(find.byWidget(priceField), '6000');
      await tester.pumpAndSettle();
      await tapChip(tester, 4);
      expect(fieldShows(tester, '7000'), isTrue);
      await tapChip(tester, 3);
      expect(fieldShows(tester, '6000'), isTrue);
    });

    testWidgets('saving persists the package price and the out-of-city values', (tester) async {
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: testVehicle);
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);

      await tapChip(tester, 3);
      TextField fieldWithText(String value) =>
          tester.widgetList<TextField>(find.byType(TextField)).firstWhere((f) => f.controller?.text == value);
      await tester.enterText(find.byWidget(fieldWithText('4200')), '6000');
      // The out-of-city daily field currently shows 9500.
      await tester.enterText(find.byWidget(fieldWithText('9500')), '10000');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);

      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-rates-9b');
      expect(stored.packages.firstWhere((p) => p.label == '12h').pricePkr, 6000);
      expect(stored.rates.outOfCityDaily, 10000);
      // Untouched packages and the daily mirror are unchanged.
      expect(stored.packages.firstWhere((p) => p.label == '24h').pricePkr, 7000);
      expect(stored.rates.daily24, 7000);
      // Enabled flags are preserved as stored (no toggles on this screen).
      expect(stored.packages.every((p) => p.enabled), isTrue);
    });

    testWidgets('invalid price blocks the save', (tester) async {
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      await tester.enterText(find.byWidget(fields.firstWhere((f) => f.controller?.text == '7000')), 'abc');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isFalse);
    });
  });

  group('09b package rates editor — out-of-city modes', () {
    testWidgets('mode pills switch the visible out-of-city fields', (tester) async {
      await pumpEditor(tester);
      expect(find.text('Pricing mode'), findsOneWidget);
      expect(find.text('Per day'), findsOneWidget);
      expect(find.text('Per km'), findsOneWidget);
      expect(find.text('Fixed route'), findsOneWidget);
      // Per-day is the default: daily rate + km allowance visible.
      expect(fieldShows(tester, '9500'), isTrue);
      expect(fieldShows(tester, '300'), isTrue);

      await tapModeSegment(tester, 'Per km');
      // Per-km rate (deck default Rs. 30/km) appears; the daily rate
      // and the km allowance do not apply and are hidden.
      expect(fieldShows(tester, '30'), isTrue);
      expect(find.text('Rs. 30 / km'), findsOneWidget);
      expect(find.text('Estimated on 300 km — final total on actual km at return'), findsOneWidget);
      expect(fieldShows(tester, '9500'), isFalse);
      expect(fieldShows(tester, '300'), isFalse);

      await tapModeSegment(tester, 'Per day');
      expect(fieldShows(tester, '9500'), isTrue);
      expect(fieldShows(tester, '300'), isTrue);
    });

    testWidgets('saving in per-day mode persists the mode', (tester) async {
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: testVehicle);
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-rates-9b');
      expect(stored.outCityMode, 'perDay');
    });

    testWidgets('saving in per-km mode persists the mode and the rate', (tester) async {
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: testVehicle);
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);
      await tapModeSegment(tester, 'Per km');
      TextField fieldWithText(String value) =>
          tester.widgetList<TextField>(find.byType(TextField)).firstWhere((f) => f.controller?.text == value);
      await tester.enterText(find.byWidget(fieldWithText('30')), '45');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-rates-9b');
      expect(stored.outCityMode, 'perKm');
      expect(stored.outCityPerKmPkr, 45);
      // The per-day values the mode does not use are untouched.
      expect(stored.rates.outOfCityDaily, 9500);
    });

    testWidgets('invalid per-km rate blocks the save', (tester) async {
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);
      await tapModeSegment(tester, 'Per km');
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      await tester.enterText(find.byWidget(fields.firstWhere((f) => f.controller?.text == '30')), 'abc');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isFalse);
    });

    testWidgets('fixed-route mode shows the route picker and its flat price', (tester) async {
      await pumpEditor(tester);
      // The segment label is the first 'Fixed route' text; the
      // picker label appears only once the routes have loaded.
      await tapModeSegment(tester, 'Fixed route');
      expect(find.text('Choose a fixed route'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lahore → Islamabad'));
      await tester.pumpAndSettle();
      expect(find.text('Fixed route: Lahore → Islamabad'), findsOneWidget);
      expect(find.text('300 km • Rs. 18,000 fixed'), findsOneWidget);
    });

    testWidgets('saving in fixed-route mode persists the mode and the route id', (tester) async {
      final repo = di.sl<FleetRepository>();
      await repo.addVehicle(shopId: 'shop-1', vehicle: testVehicle);
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);
      await tapModeSegment(tester, 'Fixed route');
      await tester.ensureVisible(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lahore → Islamabad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final cars = await repo.getShopVehicles('shop-1');
      final stored = cars.firstWhere((c) => c.vehicleId == 'veh-rates-9b');
      expect(stored.outCityMode, 'fixedRoute');
      expect(stored.outCityFixedRouteId, 'route-lhr-isb');
    });

    testWidgets('fixed-route mode without a route blocks the save', (tester) async {
      bool saved = false;
      await pumpEditor(tester, onSaved: () => saved = true);
      await tapModeSegment(tester, 'Fixed route');
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isFalse);
    });
  });
}
