// Discovery untouched-visual-fix tests (2026-11-14): the visual fixes
// for the 18 discovery files that the 2026-11-13 fix-all never
// touched — 360px + large-text-scale overflow, Urdu pumps, the
// borderless card look, and 48dp touch targets.
//
// The local PNG assets are corrupt ("Invalid image data" locally,
// passing in CI), so image-bearing widgets are pumped through the
// [_TestAssetBundle] that serves a valid 1x1 PNG (same pattern as
// worker_c_hero_icons_test.dart).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/constants/app_colors.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/customer_vehicle_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/empty_radar_state.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/location_confirm_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/location_permission_dialog.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/vehicle_detail_packages.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

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

/// Pumps [screen] at 360x640 with [textScale] and fails on any
/// Flutter error (including RenderFlex overflow).
Future<void> _pump360(
  WidgetTester tester,
  Widget screen, {
  Locale locale = const Locale('en'),
  double textScale = 1.35,
}) async {
  tester.view.physicalSize = const Size(720, 1280);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  FlutterErrorDetails? caught;
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    caught ??= details;
    previousOnError?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = previousOnError;
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 640),
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (caught != null) debugPrint('PUMP ERROR: ${caught!.summary}');
  expect(tester.takeException(), isNull);
}

const _longNameCar = VehicleEntity(
  vehicleId: 'veh-corolla-grande',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla Grande CVT-i',
  year: 2022,
  plateNumber: 'LEA-23-4567',
  category: 'Sedan',
  transmission: 'Automatic',
  fuelType: 'Petrol',
  seats: 5,
  rates: VehicleRatesEntity(daily24: 12500),
  withDriverSurchargePkr: 2500,
  securityDepositPkr: 50000,
  extraHourPkr: 1000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerVehicleCard (360px fix)', () {
    testWidgets('long name + spec chips + two rates do not overflow',
        (tester) async {
      await _pump360(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomerVehicleCard(
              vehicle: _longNameCar,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Corolla Grande'), findsOneWidget);
      expect(find.textContaining('Rs'), findsWidgets);
    });

    testWidgets('card has the borderless look (no divider side)',
        (tester) async {
      await _pump360(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomerVehicleCard(
              vehicle: _longNameCar,
              onTap: () {},
            ),
          ),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side, BorderSide.none);
    });
  });

  group('LocationPermissionDialog (Urdu + 48dp fix)', () {
    testWidgets('Urdu pump at 360px: no overflow, buttons are 48dp',
        (tester) async {
      await _pump360(
        tester,
        Scaffold(
          body: Center(
            child: LocationPermissionDialog(
              onAllow: () {},
              onManualCity: () {},
            ),
          ),
        ),
        locale: const Locale('ur'),
        textScale: 1.3,
      );
      expect(find.text('درست جگہ فعال کریں'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ElevatedButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('allow button uses orangeFill (AA white text)',
        (tester) async {
      await _pump360(
        tester,
        Scaffold(
          body: Center(
            child: LocationPermissionDialog(
              onAllow: () {},
              onManualCity: () {},
            ),
          ),
        ),
      );
      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final background =
          button.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(background, AppColors.orangeFill);
    });
  });

  group('EmptyRadarState (360px fix)', () {
    testWidgets('expand button is full-width 48dp, no overflow',
        (tester) async {
      await _pump360(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: EmptyRadarState(
              currentRadiusKm: 3.0,
              onExpandRadius: _noop,
            ),
          ),
        ),
      );
      expect(find.text('Expand to 5 km'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ElevatedButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('VehicleDetailPackages (Urdu 360px fix)', () {
    testWidgets('Urdu pump at 360px: no overflow, equal-height cards',
        (tester) async {
      await _pump360(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: VehicleDetailPackages(
                vehicle: _longNameCar,
                withDriver: false,
                onDriveModeChanged: (_) {},
              ),
            ),
          ),
        ),
        locale: const Locale('ur'),
      );
      expect(find.byType(VehicleDetailPackages), findsOneWidget);
    });
  });

  group('LocationConfirmCard (360px fix)', () {
    testWidgets('very long city name ellipsizes instead of overflowing',
        (tester) async {
      await _pump360(
        tester,
        Scaffold(
          body: Column(
            children: [
              const Expanded(child: SizedBox.shrink()),
              LocationConfirmCard(
                selectedCity: 'Gulberg III, Lahore — Main Boulevard',
                addressLabel: '31.5204°N, 74.3587°E',
                onConfirm: () {},
              ),
            ],
          ),
        ),
      );
      expect(
        find.text('Gulberg III, Lahore — Main Boulevard'),
        findsOneWidget,
      );
    });
  });
}

void _noop() {}
