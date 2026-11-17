import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_status_usecase.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_filter_chips.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/vehicle_detail/vehicle_detail_feature_actions.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Showroom redesign Phase 2 (2026-11-16): the fleet segmented bar
// (All / Ready / On Rent / Maintenance, with the Maintenance filter
// actually filtering), the horizontal-split vehicle card, and the
// vehicle-detail inline actions with the sticky bar deleted.
//
// The local copy's PNG assets are corrupt (downloaded through the
// connector's text path), so any widget rendering a car photo throws
// "Invalid image data" locally while passing in CI. This bundle answers
// every image load with a valid 1x1 PNG (same trick as
// owner_phase_b_fleet_test).
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

Widget _stub(String label) => Scaffold(body: Center(child: Text(label)));

GoRouter _detailRouter() {
  return GoRouter(
    initialLocation: '/owner/vehicles/veh-test-1',
    routes: [
      GoRoute(
        path: '/owner/vehicles/:id',
        builder: (context, state) => OwnerVehicleDetailView(
          vehicle: _detailVehicle,
          bookings: const [],
        ),
      ),
      GoRoute(
        path: RouteNames.ownerCalendar,
        builder: (context, state) => _stub('Calendar stub'),
      ),
      GoRoute(
        path: RouteNames.ownerEditVehicle,
        builder: (context, state) => _stub('Edit vehicle stub'),
      ),
      GoRoute(
        path: RouteNames.ownerRatesVehicle,
        builder: (context, state) => _stub('Rates stub'),
      ),
      GoRoute(
        path: RouteNames.ownerFareTable,
        builder: (context, state) => _stub('Fare table stub'),
      ),
      GoRoute(
        path: RouteNames.ownerPriceEstimate,
        builder: (context, state) => _stub('Estimate stub'),
      ),
    ],
  );
}

Future<GoRouter> _pumpDetail(WidgetTester tester) async {
  final router = _detailRouter();
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

const _detailVehicle = VehicleEntity(
  vehicleId: 'veh-test-1',
  shopId: 'shop-1',
  make: 'Suzuki',
  model: 'Swift',
  year: 2023,
  plateNumber: 'LEA-24-4096',
  color: 'White',
  category: 'Hatchback',
  rates: VehicleRatesEntity(daily24: 4500, outOfCityDaily: 5500),
  securityDepositPkr: 50000,
);

/// Flips the seeded v2 (Toyota Corolla Grande 2022) to the given
/// status through the shared in-memory data source, so the fleet
/// view's own cubit loads it. Restored by the caller.
Future<void> _setV2Status(String status) async {
  final repo = FleetRepositoryImpl(
    remoteDataSource: di.sl<FleetRemoteDataSource>(),
  );
  await UpdateVehicleStatusUseCase(repo)(
    vehicleId: 'v2',
    status: status,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Fleet segmented bar (Phase 2)', () {
    testWidgets('renders four segments with counts, Maintenance kept',
        (tester) async {
      var selected = 'All';
      await tester.pumpWidget(_wrap(FleetFilterChips(
        selectedFilter: selected,
        totalCount: 3,
        availableCount: 1,
        onRentCount: 1,
        maintenanceCount: 1,
        onSelected: (label) => selected = label,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Ready (1)'), findsOneWidget);
      expect(find.text('On Rent (1)'), findsOneWidget);
      expect(find.text('Maintenance (1)'), findsOneWidget);
      // User layout 2026-11-16: segment labels are 14sp (set on
      // the label Text; the chip theme still supplies color/weight).
      expect(tester.widget<Text>(find.text('All (3)')).style?.fontSize, 14);

      await tester.tap(find.text('Maintenance (1)'));
      expect(selected, 'Maintenance');
      await tester.tap(find.text('Ready (1)'));
      expect(selected, 'Available');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Maintenance filter shows only maintenance vehicles',
        (tester) async {
      // v2 goes to maintenance before the view loads; restored
      // afterwards so no other test sees the mutated seed.
      await _setV2Status('maintenance');
      try {
        await tester.pumpWidget(_wrap(
          const OwnerFleetView(shopId: 'shop-basic'),
        ));
        await tester.pumpAndSettle();

        // The merged bar: All is the total, Ready lost v2.
        expect(find.text('All (3)'), findsOneWidget);
        expect(find.text('Ready (2)'), findsOneWidget);
        expect(find.text('On Rent (0)'), findsOneWidget);
        expect(find.text('Maintenance (1)'), findsOneWidget);
        // The old KPI texts are gone with the KPI boxes.
        expect(find.text('Total Fleet'), findsNothing);
        expect(find.text('3 Cars'), findsNothing);

        await tester.tap(find.text('Maintenance (1)'));
        await tester.pumpAndSettle();
        expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
        expect(find.text('Honda Civic Oriel 2021'), findsNothing);
        expect(find.text('Suzuki Alto VXL 2023'), findsNothing);

        await tester.tap(find.text('Ready (2)'));
        await tester.pumpAndSettle();
        expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
        expect(find.text('Suzuki Alto VXL 2023'), findsOneWidget);
        expect(find.text('Toyota Corolla Grande 2022'), findsNothing);

        await tester.tap(find.text('All (3)'));
        await tester.pumpAndSettle();
        expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
        expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
        expect(find.text('Suzuki Alto VXL 2023'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await _setV2Status('available');
      }
    });

    testWidgets('AppBar holds Schedule + Handover + Requests, Add Vehicle is the FAB',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const OwnerFleetView(shopId: 'shop-basic'),
      ));
      await tester.pumpAndSettle();

      // User layout 2026-11-16: the three AppBar icon actions
      // (Schedule, Handover QR, Requests) and the extended FAB.
      expect(find.byKey(const Key('fleet-action-schedule')), findsOneWidget);
      expect(find.byTooltip('Schedule'), findsOneWidget);
      expect(find.byKey(const Key('fleet-action-handover')), findsOneWidget);
      expect(find.byKey(const Key('fleet-action-requests')), findsOneWidget);
      expect(find.byTooltip('Handover QR'), findsOneWidget);
      expect(find.byTooltip('Bookings'), findsOneWidget);
      expect(find.byKey(const Key('fleet-action-add-vehicle')), findsOneWidget);
      expect(find.text('Add Vehicle'), findsOneWidget);
      // The search bar and the quick-actions row are gone; Customers
      // left the fleet screen (still on the Customers tab).
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('fleet-action-customers')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Horizontal-split fleet card (Phase 2)', () {
    const vehicle = VehicleEntity(
      vehicleId: 'veh-test-1',
      shopId: 'shop-1',
      make: 'Toyota',
      model: 'Corolla Grande',
      year: 2022,
      plateNumber: 'LEA-23-4567',
      rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
    );

    testWidgets('thumbnail 110x95 beside the details, slim footer kept',
        (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: vehicle,
        onEditRates: () {},
        onOutCityRules: () {},
        onEditDetails: () {},
      )));
      await tester.pumpAndSettle();

      // The thumbnail is a fixed 110x95 box; the name, rate, plate
      // and badges sit beside it, not over the photo.
      final thumb = find.descendant(
        of: find.byType(Hero),
        matching: find.byType(Image),
      );
      expect(thumb, findsWidgets);
      expect(tester.getSize(find.byType(Hero).first), const Size(110, 95));
      expect(find.text('Toyota Corolla Grande 2022'), findsOneWidget);
      expect(find.text('Rs. 8,500/day'), findsOneWidget);
      expect(find.text('LEA-23-4567'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Self-Drive'), findsOneWidget);
      // The compact card is short enough for two per phone screen.
      expect(tester.getSize(find.byType(FleetVehicleCard)).height,
          lessThan(260));
      // Footer: the same three actions, no Button widgets.
      expect(find.text('Within city'), findsOneWidget);
      expect(find.text('Out of city'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Vehicle detail inline actions (Phase 2)', () {
    testWidgets('sticky bar gone; calendar + Edit inline, rates in 2 columns',
        (tester) async {
      await _pumpDetail(tester);

      // The old bottom-bar labels are gone: no bare 'Edit', and the
      // three actions now live inline.
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Booking calendar'), findsOneWidget);
      expect(find.text('Edit Vehicle'), findsOneWidget);
      expect(find.text('Manage rates'), findsOneWidget);
      // Rates & Pricing header + the 2-column grid of 7 tiers.
      expect(find.text('Rates & Pricing'), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      for (final label in ['1h', '3h', '6h', '12h', '24h', 'Weekly', 'Monthly']) {
        expect(find.text(label), findsOneWidget, reason: 'missing tier $label');
      }
      expect(find.text('Security deposit'), findsOneWidget);
      expect(find.text('Rs. 50,000'), findsOneWidget);
      expect(find.text('Fare table'), findsOneWidget);
      expect(find.text('View estimated rates'), findsOneWidget);
      // All 5 spec chips kept (guide shows 4; colour is the 5th).
      for (final chip in ['White', '5 seats', 'Petrol', 'Automatic', 'Hatchback']) {
        expect(find.text(chip), findsOneWidget, reason: 'missing spec $chip');
      }
      // Bookings section stays below rates.
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('No bookings for this car yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('inline actions navigate to their screens', (tester) async {
      final router = await _pumpDetail(tester);

      await tester.tap(find.text('Booking calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Calendar stub'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Vehicle'));
      await tester.pumpAndSettle();
      expect(find.text('Edit vehicle stub'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage rates'));
      await tester.pumpAndSettle();
      expect(find.text('Rates stub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phone-test build 80: footer readability + one-row feature actions', () {
    const cardVehicle = VehicleEntity(
      vehicleId: 'veh-test-1',
      shopId: 'shop-1',
      make: 'Toyota',
      model: 'Corolla Grande',
      year: 2022,
      plateNumber: 'LEA-23-4567',
      rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
    );

    Widget cardWrap(Widget child, {ThemeData? theme, Locale? locale}) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme ?? AppTheme.lightTheme,
        home: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: Scaffold(body: child),
        ),
      );
    }

    void setNarrow(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget testCard() => FleetVehicleCard(
          vehicle: cardVehicle,
          onEditRates: () {},
          onOutCityRules: () {},
          onEditDetails: () {},
        );

    testWidgets('footer labels are dark onSurface text, 12sp semibold (light)',
        (tester) async {
      await tester.pumpWidget(cardWrap(testCard()));
      await tester.pumpAndSettle();
      for (final label in ['Within city', 'Out of city', 'Edit']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style?.color, AppColors.onSurfaceLight,
            reason: '$label label colour');
        expect(text.style?.fontSize, 12.0, reason: '$label label size');
        expect(text.style?.fontWeight, FontWeight.w600,
            reason: '$label label weight');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('footer labels are light onSurface text (dark mode)',
        (tester) async {
      await tester.pumpWidget(
          cardWrap(testCard(), theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('Within city'));
      expect(text.style?.color, AppColors.onSurfaceDark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fleet card fits at 360px in Urdu, no overflow',
        (tester) async {
      setNarrow(tester);
      await tester.pumpWidget(cardWrap(
        SingleChildScrollView(child: testCard()),
        locale: const Locale('ur'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('شہر کے اندر'), findsOneWidget);
      expect(find.text('شہر سے باہر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('feature actions are one row: calendar, Edit, Manage rates',
        (tester) async {
      await _pumpDetail(tester);
      for (final label in ['Booking calendar', 'Edit Vehicle', 'Manage rates']) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
      // All three labels share one Row ancestor — one row, not split.
      Row? rowOf(String label) => tester
          .element(find.text(label))
          .findAncestorWidgetOfExactType<Row>();
      final row = rowOf('Booking calendar');
      expect(row, isNotNull);
      expect(identical(row, rowOf('Edit Vehicle')), isTrue);
      expect(identical(row, rowOf('Manage rates')), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('feature-actions row fits at 360px in Urdu, no overflow',
        (tester) async {
      setNarrow(tester);
      var calendarFired = false;
      var editFired = false;
      var ratesFired = false;
      await tester.pumpWidget(cardWrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: VehicleDetailFeatureActions(
            onCalendar: () => calendarFired = true,
            onEdit: () => editFired = true,
            onManageRates: () => ratesFired = true,
          ),
        ),
        locale: const Locale('ur'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('بکنگ کیلنڈر'), findsOneWidget);
      expect(find.text('گاڑی میں ترمیم کریں'), findsOneWidget);
      expect(find.text('نرخ مینیج کریں'), findsOneWidget);
      await tester.tap(find.text('بکنگ کیلنڈر'));
      await tester.tap(find.text('گاڑی میں ترمیم کریں'));
      await tester.tap(find.text('نرخ مینیج کریں'));
      expect(calendarFired && editFired && ratesFired, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
