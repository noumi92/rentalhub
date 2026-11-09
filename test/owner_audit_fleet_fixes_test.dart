import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/add_vehicle/add_vehicle_stepper_bar.dart';
import 'package:rentalhub/features/owner/presentation/widgets/availability_month_grid.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fixed_route_form.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_filter_chips.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/rate_matrix_field_widget.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Owner visual audit fix batch (Fleet branch, 2026-11-08): widget tests
// for the §4–§8 fixes. These are pure widget tests — no DI, no Firebase.
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

Widget _wrap(Widget child, {ThemeData? theme, Locale? locale}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    theme: theme ?? AppTheme.lightTheme,
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
  group('Audit §5 — add-vehicle stepper label stays readable in dark mode', () {
    testWidgets('active label uses primaryContainer in dark mode', (tester) async {
      await tester.pumpWidget(_wrap(const AddVehicleStepperBar(currentStep: 1), theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();
      final label = tester.widget<Text>(find.text('Vehicle Specs'));
      expect(label.style?.color, AppColors.primaryContainer);
    });

    testWidgets('active label uses the theme primary in light mode', (tester) async {
      await tester.pumpWidget(_wrap(const AddVehicleStepperBar(currentStep: 1), theme: AppTheme.lightTheme));
      await tester.pumpAndSettle();
      final label = tester.widget<Text>(find.text('Vehicle Specs'));
      expect(label.style?.color, AppTheme.lightTheme.colorScheme.primary);
    });
  });

  group('Audit §4 — fleet card', () {
    testWidgets('rented car: shows On Rent badge and two actions, no switch', (tester) async {
      const rented = VehicleEntity(
        vehicleId: 'veh-rented',
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
      // Simplified card (2026-11-09): no availability switch, no
      // "On Rent until" row — the status is a badge, and the only
      // actions are Rates and Out-of-city rules.
      expect(find.byType(Switch), findsNothing);
      expect(find.text('On Rent'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.text('Edit rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
      await tester.tap(find.text('Edit rates'));
      await tester.tap(find.text('Out-of-city rules'));
      expect(ratesTapped, isTrue);
      expect(rulesTapped, isTrue);
    });

    testWidgets('available car: shows Available badge and two actions, no switch', (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _testVehicle,
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('On Rent'), findsNothing);
      expect(find.byType(OutlinedButton), findsNWidgets(2));
      expect(find.text('Edit rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
    });

    testWidgets('selected filter chip label is white on orange', (tester) async {
      await tester.pumpWidget(_wrap(FleetFilterChips(
        selectedFilter: 'All',
        totalCount: 3,
        availableCount: 1,
        onRentCount: 1,
        maintenanceCount: 1,
        onSelected: (_) {},
      )));
      await tester.pumpAndSettle();
      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip).first);
      expect(chip.selectedColor, AppColors.orangeFill);
      expect(chip.labelStyle?.color, Colors.white);
    });
  });

  group('Audit §6 — rate matrix', () {
    testWidgets('disabled package price field is not editable', (tester) async {
      final controller = TextEditingController(text: '8500');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(RateMatrixFieldWidget(
        controller: controller,
        label: 'In-City Daily (24h)',
        hint: 'Rs. 8500',
        kmCap: '250 km included',
        enabled: false,
      )));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('invalid input blocks the save and names the field', (tester) async {
      var saved = false;
      await tester.pumpWidget(_wrap(
        OwnerRateMatrixView(vehicle: _testVehicle, onRatesSaved: () => saved = true),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.tap(find.text('Save package'));
      await tester.pumpAndSettle();
      expect(saved, isFalse);
      expect(find.textContaining('Enter a valid number for'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 360px / 1.35x / Urdu', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ur'),
        theme: AppTheme.lightTheme,
        home: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
            child: const OwnerRateMatrixView(vehicle: _testVehicle),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // Urdu locale: the title is the Urdu translation, so assert on
      // the view itself plus a clean render (no overflow exception).
      expect(find.byType(OwnerRateMatrixView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Audit §7 — calendar month grid', () {
    testWidgets('weekday header and today marker render without overflow at 360px / 1.35x', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final now = DateTime.now();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
          child: Scaffold(
            body: AvailabilityMonthGrid(
              month: DateTime(now.year, now.month),
              bookings: const [],
              selectedDay: null,
              onMonthChanged: (_) {},
              onDaySelected: (_) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('${now.day}'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Audit §8 — fixed-route form', () {
    testWidgets('destination is free text and the CTA is a DebouncedButton', (tester) async {
      final origin = TextEditingController();
      final destination = TextEditingController();
      final distance = TextEditingController(text: '300');
      final price = TextEditingController();
      addTearDown(() {
        origin.dispose();
        destination.dispose();
        distance.dispose();
        price.dispose();
      });
      await tester.pumpWidget(_wrap(FixedRouteForm(
        originController: origin,
        destinationController: destination,
        distanceController: distance,
        priceController: price,
        onAdd: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(DebouncedButton), findsOneWidget);
      expect(find.text('To (city)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await tester.enterText(find.byType(TextField).at(1), 'Sialkot');
      expect(destination.text, 'Sialkot');
    });
  });
}
