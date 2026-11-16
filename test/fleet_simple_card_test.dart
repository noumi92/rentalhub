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

// Simplified fleet card (2026-11-09, header rework round 4; horizontal
// split in the Phase 2 showroom redesign, 2026-11-16): the car header
// lives BESIDE the 110x95 thumbnail — name, plate, one in-city daily
// rate and the self-drive badge stack in the details column on the
// right — and UNDER the details there is exactly ONE slim row of
// small orange icon buttons: Rates (09b editor), Out-of-city rules
// (010b) and Edit (edit-details route, only when onEditDetails is
// provided). No price block and no OutlinedButtons below the photo.
// No availability switch, no "On Rent until" row, no calendar /
// edit-rent / update-price actions. Pure widget tests — no DI, no
// Firebase.
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
    testWidgets('shows name, plate, rate and badges beside the thumbnail',
        (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.text('LEA-23-4567'), findsOneWidget);
      // Phase 2: the rate lives in the details column beside the
      // thumbnail, not in a price block below the photo.
      expect(find.text('Rs. 8,500/day'), findsOneWidget);
      expect(find.text('Daily Self-Drive Rate'), findsNothing);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Self-Drive'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('one icon-button row: Rates + Out-of-city rules fire, no Edit without callback',
        (tester) async {
      var ratesFired = false;
      var rulesFired = false;
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () => ratesFired = true,
        onOutCityRules: () => rulesFired = true,
      )));
      await tester.pumpAndSettle();
      // The old stacked text buttons are gone.
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      await tester.tap(find.text('Rates'));
      expect(ratesFired, isTrue);
      await tester.tap(find.text('Out-of-city rules'));
      expect(rulesFired, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit icon button appears and fires when onEditDetails is provided',
        (tester) async {
      var editFired = false;
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
        onEditDetails: () => editFired = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      expect(editFired, isTrue);
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
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('passes onEditDetails through to the card', (tester) async {
      var editedId = '';
      await tester.pumpWidget(_wrap(FleetBody(
        state: const FleetLoaded(vehicles: [_testVehicle], tier: 'free'),
        fleet: const [_testVehicle],
        filtered: const [_testVehicle],
        onAddVehicle: () {},
        onRetry: () {},
        onEditRates: (_) {},
        onOutCityRules: (_) {},
        onTapVehicle: (_) {},
        onEditDetails: (v) => editedId = v.vehicleId,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      expect(editedId, 'veh-test-1');
      expect(tester.takeException(), isNull);
    });
  });
}
