import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_body.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Simplified fleet card (2026-11-09): the card is a hero photo with
// name/plate/status, one in-city daily price row, and exactly two
// actions — "Rates" (09b editor) and "Out-of-city rules" (010b).
// No availability switch, no "On Rent until" row, no calendar /
// edit-rent / update-price actions. Pure widget tests — no DI,
// no Firebase.
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
    theme: AppTheme.lightTheme,
    home: DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: Scaffold(body: child),
    ),
  );
}

const _testVehicle = VehicleEntity(
  vehicleId: 'veh-test-1',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla Grande',
  year: 2022,
  plateNumber: 'LEA-23-4567',
  rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
);

const _rentedVehicle = VehicleEntity(
  vehicleId: 'veh-rented',
  shopId: 'shop-1',
  make: 'Honda',
  model: 'Civic',
  year: 2021,
  plateNumber: 'LEA-21-1000',
  status: 'rented',
  rates: VehicleRatesEntity(daily24: 9000),
);

void main() {
  group('Simplified fleet card', () {
    testWidgets('shows name, plate, price and status badge', (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.text('LEA-23-4567'), findsOneWidget);
      expect(find.text('Daily Self-Drive Rate'), findsOneWidget);
      expect(find.text('Rs. 8,500/day'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exactly two action buttons and both callbacks fire',
        (tester) async {
      var ratesFired = false;
      var rulesFired = false;
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () => ratesFired = true,
        onOutCityRules: () => rulesFired = true,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      await tester.tap(find.text('Edit rates'));
      expect(ratesFired, isTrue);
      await tester.tap(find.text('Out-of-city rules'));
      expect(rulesFired, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no availability switch and no "On Rent until" row',
        (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _rentedVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      expect(find.textContaining('On Rent until'), findsNothing);
      // The rented status badge itself is still shown.
      expect(find.text('On Rent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the photo fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
        onTap: () => tapped = true,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });
  });

  group('FleetBody with the simplified card', () {
    testWidgets('renders the new card for each vehicle', (tester) async {
      await tester.pumpWidget(_wrap(FleetBody(
        state: const FleetLoaded(vehicles: [_testVehicle], tier: 'free'),
        fleet: const [_testVehicle],
        filtered: const [_testVehicle],
        onAddVehicle: () {},
        onRetry: () {},
        onEditRates: (_) {},
        onOutCityRules: (_) {},
        onTapVehicle: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(FleetVehicleCard), findsOneWidget);
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
