import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Car header (phone-test round 4, 2026-11-09): the fleet card header
// lives ON the photo — name, plate, one in-city daily rate and the
// self-drive badge stack over the bottom gradient scrim — and under
// the photo there is exactly ONE row of small orange icon buttons
// with short regular labels (Rates, Out-of-city rules, Edit). The old
// price block and the stacked OutlinedButtons are gone. The owner
// vehicle-detail header follows the same pattern: rate, self-drive
// badge and status sit on its photo; the rate/status row below the
// photo is gone (name/plate stay in the app bar, not repeated on the
// photo). Pure widget tests — no DI, no Firebase.
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

void main() {
  group('Fleet card header on the photo', () {
    testWidgets('name, plate, rate and self-drive badge render inside the photo Stack',
        (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();

      final photoStack = find.byType(Stack).first;
      for (final label in ['Toyota Corolla Grande 2022', 'LEA-23-4567', 'Rs. 8,500/day', 'Self-Drive', 'Available']) {
        expect(find.descendant(of: photoStack, matching: find.text(label)), findsOneWidget, reason: '$label must sit on the photo');
      }
      // The rate is no longer in a price block below the photo.
      expect(find.text('Daily Self-Drive Rate'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with-driver car shows the With Driver badge instead', (tester) async {
      final withDriver = _testVehicle.copyWith(isSelfDriveAvailable: false);
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: withDriver,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('With Driver'), findsOneWidget);
      expect(find.text('Self-Drive'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exactly one action row under the image, with small orange regular labels',
        (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
        onEditDetails: () {},
      )));
      await tester.pumpAndSettle();

      // The old stacked text buttons are gone.
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);

      // All three actions live in one single Row, outside the photo Stack.
      for (final label in ['Rates', 'Out-of-city rules', 'Edit']) {
        expect(find.descendant(of: find.byType(Stack).first, matching: find.text(label)), findsNothing, reason: '$label must be under the image, not on it');
        final rowAncestors = find.ancestor(of: find.text(label), matching: find.byType(Row));
        expect(rowAncestors, findsOneWidget, reason: '$label must have exactly one ancestor Row — the single action row');
      }
      final actionRow = find.ancestor(of: find.text('Rates'), matching: find.byType(Row)).evaluate().single;
      for (final label in ['Out-of-city rules', 'Edit']) {
        final otherRow = find.ancestor(of: find.text(label), matching: find.byType(Row)).evaluate().single;
        expect(identical(otherRow.widget, actionRow.widget), isTrue, reason: '$label must share the Rates action row');
      }

      // Eye-catching: orange icons on the pale orange container, and
      // short labels in small regular type — never bold.
      final ratesIcon = tester.widget<Icon>(find.byIcon(Icons.tune_rounded));
      expect(ratesIcon.color, AppColors.orangeTextFor(Brightness.light));
      expect(ratesIcon.size, 20);
      for (final label in ['Rates', 'Out-of-city rules', 'Edit']) {
        final text = tester.widget<Text>(find.text(label));
        final weight = text.style?.fontWeight;
        expect(weight == null || weight.value < FontWeight.w700.value, isTrue, reason: '$label must be regular, never bold');
        expect(text.style?.color, AppColors.orangeTextFor(Brightness.light));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit hidden without onEditDetails; Rates / rules / Edit callbacks fire',
        (tester) async {
      var ratesFired = false;
      var rulesFired = false;
      var editFired = false;
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () => ratesFired = true,
        onOutCityRules: () => rulesFired = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
      await tester.tap(find.text('Rates'));
      await tester.tap(find.text('Out-of-city rules'));
      expect(ratesFired, isTrue);
      expect(rulesFired, isTrue);

      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
        onEditDetails: () => editFired = true,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      expect(editFired, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the photo still fires onTap', (tester) async {
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
      expect(tester.takeException(), isNull);
    });
  });

  group('Owner vehicle detail header', () {
    testWidgets('rate, self-drive badge and status sit on the photo; old rate row is gone',
        (tester) async {
      await tester.pumpWidget(_wrap(OwnerVehicleDetailView(
        vehicle: _testVehicle,
        bookings: const [],
      )));
      await tester.pumpAndSettle();

      final photoStack = find.byType(Stack).first;
      for (final label in ['Rs. 8,500/day', 'Self-Drive', 'Available']) {
        expect(find.descendant(of: photoStack, matching: find.text(label)), findsOneWidget, reason: '$label must sit on the detail photo');
      }
      // Old below-photo rate row ("Rs. 8,500 / day") is gone.
      expect(find.text('Rs. 8,500 / day'), findsNothing);
      // Name/plate stay in the app bar, not repeated on the photo.
      expect(find.descendant(of: photoStack, matching: find.text('Toyota Corolla Grande 2022')), findsNothing);
      // The bottom action bar is untouched.
      expect(find.text('Manage rates'), findsOneWidget);
      expect(find.text('Booking calendar'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
