import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/presentation/views/rent_package_picker_view.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/trip_type_section.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/handover_local_data_source.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/owner/presentation/services/return_settlement_service.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_search_field.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/pricing_out_city_modes.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/pricing_policy_fields.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/requests_filter_bar.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/settlement_summary_receipt_widget.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// Team I — audit 2026-11-15 fixes: AC-12 (09b SegmentedButton),
/// DS-10 (localized rate hints), DS-12 (search-field radius),
/// DS-1 (theme-owned selected chips), PW-13 (per-km estimate wiring),
/// step2 face-photo Wrap, PW-16 (first-class handover balance),
/// PW-21 (persisted owed collection + receipt line).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  /// A minimal valid 1x1 PNG, used as a stand-in signature image.
  Uint8List tinyPng() => base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      );

  Future<void> pumpUrdu360(
    WidgetTester tester,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ur'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpEnglish(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  PricingOutCityModes modesWidget({required String mode}) {
    final outOfCity = TextEditingController(text: '9500');
    final perKm = TextEditingController(text: '30');
    final extraKm = TextEditingController(text: '100');
    final outOfCityKm = TextEditingController(text: '300');
    addTearDown(() {
      outOfCity.dispose();
      perKm.dispose();
      extraKm.dispose();
      outOfCityKm.dispose();
    });
    return PricingOutCityModes(
      mode: mode,
      onModeChanged: (_) {},
      outOfCityController: outOfCity,
      perKmController: perKm,
      extraKmController: extraKm,
      outOfCityKmController: outOfCityKm,
      perKmEnabled: true,
      onPerKmChanged: (_) {},
      shopId: 'shop-1',
      selectedRouteId: null,
      onRouteChanged: (_) {},
    );
  }

  group('AC-12 — 09b SegmentedButton at 360 px in Urdu', () {
    testWidgets('all three mode labels render without clipping',
        (tester) async {
      await pumpUrdu360(tester, modesWidget(mode: 'perDay'));

      // No RenderFlex overflow: the segmented row fits 360 px.
      expect(tester.takeException(), isNull);
      expect(find.text('فی دن'), findsOneWidget);
      expect(find.text('فی کلومیٹر'), findsOneWidget);
      expect(find.text('مقررہ راستہ'), findsOneWidget);
      for (final label in ['فی دن', 'فی کلومیٹر', 'مقررہ راستہ']) {
        // No ellipsis: the label text is fully laid out.
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text(label));
        expect(paragraph.didExceedMaxLines, isFalse);
        // Fully inside the 360 px screen.
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
    });
  });

  group('DS-10 — rate-editor hints are localized', () {
    testWidgets('per-km hint renders in Urdu, no hardcoded Rs.',
        (tester) async {
      await pumpUrdu360(tester, modesWidget(mode: 'perKm'));
      expect(tester.takeException(), isNull);
      // Twice by design: the field hint AND the live km-cap line
      // under it both render the localized per-km rate.
      expect(find.text('30 روپے / کلومیٹر'), findsNWidgets(2));
      expect(find.text('Rs. 30 / km'), findsNothing);
    });

    testWidgets('policy-field hints render in Urdu', (tester) async {
      final surcharge = TextEditingController();
      final deposit = TextEditingController();
      final advance = TextEditingController();
      final extraHour = TextEditingController();
      addTearDown(() {
        surcharge.dispose();
        deposit.dispose();
        advance.dispose();
        extraHour.dispose();
      });
      await pumpUrdu360(
        tester,
        PricingPolicyFields(
          surchargeController: surcharge,
          depositController: deposit,
          advanceController: advance,
          extraHourController: extraHour,
          fuelPolicy: 'Same to Same',
          onFuelPolicyChanged: (_) {},
          fuelPolicies: const ['Same to Same'],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('2,000 روپے / دن'), findsOneWidget);
      expect(find.text('25,000 روپے'), findsOneWidget);
      expect(find.text('Rs. 2,000 / day'), findsNothing);
      expect(find.text('Rs. 25,000'), findsNothing);
    });
  });

  group('DS-12 — search fields let the theme own the border', () {
    testWidgets('fleet + requests search fields carry no explicit border',
        (tester) async {
      final searchController = TextEditingController();
      addTearDown(searchController.dispose);
      await pumpEnglish(
        tester,
        Column(
          children: [
            FleetSearchField(onChanged: (_) {}),
            RequestsFilterBar(
              searchController: searchController,
              onSearchChanged: (_) {},
              filter: 'requested',
              counts: const {'requested': 1},
              onFilterChanged: (_) {},
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.decoration?.border, isNull,
            reason: 'the theme input border (radius 16) owns the shape');
      }
      final themeBorder =
          AppTheme.lightTheme.inputDecorationTheme.border
              as OutlineInputBorder;
      expect(themeBorder.borderRadius, BorderRadius.circular(16));
    });
  });

  group('DS-1 — trip-type chips inherit the navy theme token', () {
    testWidgets('no per-chip selectedColor/labelStyle override',
        (tester) async {
      await pumpEnglish(
        tester,
        TripTypeSection(
          isOutOfCity: false,
          onChanged: (_) {},
          fixedRoutes: const [],
          selectedRoute: null,
          onRouteSelected: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(AppTheme.lightTheme.chipTheme.selectedColor,
          AppColors.primary);
      for (final chip
          in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
        expect(chip.selectedColor, isNull);
        expect(chip.labelStyle, isNull);
      }
    });
  });

  group('PW-13 — per-km estimate renders from the picker', () {
    testWidgets('out-of-city per-km shows the live estimate',
        (tester) async {
      const vehicle = VehicleEntity(
        vehicleId: 'veh-pw13',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla GLi',
        year: 2022,
        plateNumber: 'LEA-22-7000',
        rates: VehicleRatesEntity(daily24: 7000, outOfCityDaily: 9500),
        withDriverSurchargePkr: 1500,
        extraKmPkr: 25,
        outOfCityKmPerDay: 300,
        packages: [
          VehiclePackageEntity(
              label: '24h', hours: 24, pricePkr: 7000, kmIncluded: 250),
        ],
        outCityMode: 'perKm',
        outCityPerKmPkr: 30,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RentPackagePickerView(
            carId: 'veh-pw13',
            carName: 'Toyota Corolla GLi',
            plateNumber: 'LEA-22-7000',
            shopId: 'shop-1',
            shopName: 'Test Shop',
            dailySelfDriveRate: 7000,
            dailyWithDriverRate: 8500,
            vehicle: vehicle,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The estimate only renders out-of-city: switch the toggle.
      await tester.ensureVisible(find.text('Out-of-City'));
      await tester.tap(find.text('Out-of-City'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Default: 1 day × 300 km/day × Rs. 30/km = Rs. 9,000.
      expect(find.text('≈ Rs. 9,000 for 1 days × 300 km/day'),
          findsOneWidget);
    });
  });

  group('Step2 face-photo actions wrap at 360 px', () {
    testWidgets('Take + Retake + Remove fit with a face photo present',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = KycDraft()
        ..facePhoto = XFile('test/assets/mock_selfie.jpg');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Step2Photo(draft: draft, onChanged: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The old Row overflowed 108 px here; the Wrap must not.
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('step2_face_take')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('step2_face_retake')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('step2_face_remove')), findsOneWidget);
    });
  });

  group('PW-16 — first-class handover balance', () {
    test('cubit records the balance on the entity + local store',
        () async {
      final cubit = HandoverCubit(
        localDataSource: di.sl<HandoverLocalDataSource>(),
      );
      final entity = await cubit.completeHandoverOfflineFirst(
        bookingId: 'RH-I-16',
        shopName: 'Test Showroom',
        customerName: 'Ayesha Khan',
        cnicNumber: '35202-1234567-1',
        vehicleDetails: 'Honda Civic Oriel 2021',
        totalAmount: 9000,
        advancePaid: 3000,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        balanceDuePkr: 6000,
        balancePaymentMethod: 'cash',
        customerSignaturePng: tinyPng(),
        ownerSignaturePng: tinyPng(),
        isOnline: false,
      );
      expect(entity.balanceDuePkr, 6000);
      expect(entity.balancePaymentMethod, 'cash');
      final stored =
          await di.sl<HandoverLocalDataSource>().getHandover('RH-I-16');
      expect(stored, isNotNull);
      expect(stored!.balanceDuePkr, 6000);
      expect(stored.balancePaymentMethod, 'cash');
    });
  });

  group('PW-21 — owed collection persists + receipt shows it', () {
    test('recordOwedCollected round-trips through loadOwedState',
        () async {
      final before =
          await ReturnSettlementService.loadOwedState('RH-I-21');
      expect(before.collected, isFalse);
      await ReturnSettlementService.recordOwedCollected(
        bookingId: 'RH-I-21',
        amount: 6000,
        method: 'cash',
      );
      final after =
          await ReturnSettlementService.loadOwedState('RH-I-21');
      expect(after.collected, isTrue);
      expect(after.amount, 6000);
      expect(after.method, 'cash');
      // Undo clears it.
      await ReturnSettlementService.recordOwedCollected(
        bookingId: 'RH-I-21',
        amount: 0,
      );
      final cleared =
          await ReturnSettlementService.loadOwedState('RH-I-21');
      expect(cleared.collected, isFalse);
      expect(cleared.amount, 0);
    });

    testWidgets('receipt shows the owed line from amountOwed',
        (tester) async {
      await pumpEnglish(
        tester,
        const SettlementSummaryReceiptWidget(
          totalKm: 300,
          excessKm: 0,
          excessKmPenalty: 0,
          fuelDeficitFee: 0,
          overtimeFee: 0,
          damageCharge: 6000,
          securityDeposit: 0,
          netRefund: 0,
          amountOwed: 6000,
        ),
      );
      expect(find.text('Customer owes Rs. 6,000'), findsOneWidget);
    });

    testWidgets('receipt hides the owed line when nothing is owed',
        (tester) async {
      await pumpEnglish(
        tester,
        const SettlementSummaryReceiptWidget(
          totalKm: 300,
          excessKm: 0,
          excessKmPenalty: 0,
          fuelDeficitFee: 0,
          overtimeFee: 0,
          securityDeposit: 20000,
          netRefund: 20000,
        ),
      );
      expect(find.textContaining('Customer owes'), findsNothing);
    });
  });
}
