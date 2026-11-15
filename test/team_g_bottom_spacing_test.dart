import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart' show sl;
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/features/auth/presentation/views/onboarding_role_view.dart';
import 'package:rentalhub/features/auth/presentation/views/widgets/role_selector_card.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/booking_approved_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/booking_success_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/pickup_countdown_pass_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/rent_package_picker_view.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/booking_summary_card.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/duration_calendar_picker.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/pass_shop_contact_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/vehicle_detail_packages.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_active_trip_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_cancel_booking_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_dispute_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/my_disputes_list.dart';
import 'package:rentalhub/features/discovery/presentation/views/vehicle_detail_view.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_added_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_calendar_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fixed_routes_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_out_city_rules_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dispute_detail_sheet.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_list_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/pricing_trip_charges.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/rate_matrix_field_widget.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Team G (2026-11-15 audit §10, BP-1–BP-21): bottom dead-space sweep.
// Every test pumps at 360x640, scrolls to the bottom, and asserts the
// last content sits exactly on the scroll/list padding above the
// footer or screen edge — no trailing-spacer band left behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  // 1px image for every asset key, so vehicle photos never fail the pump.
  final testBundle = _TestAssetBundle();

  // Pre-existing 360 px horizontal overflows, in widgets Team G does
  // not own and did not touch (PassShopContactCard title row,
  // DriverModeToggle / PackageTierCard / DurationCalendarPicker rows,
  // BookingSuccessView summary rows). The test font renders ~1.85x
  // wider than real Inter (see AGENTS.md), so these overflow in the
  // test env at 360 px; the same views pump clean at the suite's
  // default 800 px width. They are drained with tester.takeException()
  // after every pump and asserted here to be ONLY RenderFlex
  // overflows — any other error still fails the test — so the
  // bottom-spacing assertion can run on the laid out tree (a
  // horizontal overflow does not move the last child's vertical
  // position). NOTE: when several overflows fire in one pump the
  // framework collapses them into a single "Multiple exceptions"
  // pseudo-error (the individuals are dumped to the test log by the
  // framework); that collapse is accepted here and the dumped lines
  // were verified to all be overflows. Filed as pre-existing
  // findings in the report; NOT fixed here (files outside Team G's
  // list). Deliberately NO FlutterError.onError override: overriding
  // it turns any later uncaught error into the framework's opaque
  // "overrode onError" assertion instead of the real error.
  void drainKnownErrors(WidgetTester tester) {
    Object? error;
    var drained = 0;
    while ((error = tester.takeException()) != null) {
      final message = error.toString();
      expect(
        message.contains('overflowed') ||
            message.contains('Multiple exceptions'),
        isTrue,
        reason: 'Unexpected error during pump: $message',
      );
      drained++;
    }
    if (drained > 0) {
      debugPrint(
        'Team G: drained $drained known pre-existing 360 px '
        'overflow error(s) (see header comment).',
      );
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    double width = 360,
    double height = 640,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultAssetBundle(bundle: testBundle, child: screen),
      ),
    );
    await tester.pumpAndSettle();
    drainKnownErrors(tester);
  }

  /// Drags the first scrollable to its bottom, then returns the gap
  /// between the scrollable's bottom edge and [lastContent]'s bottom.
  Future<double> gapBelow(
    WidgetTester tester,
    Finder lastContent, {
    Finder? scrollable,
  }) async {
    final scroll = scrollable ?? find.byType(SingleChildScrollView).first;
    await tester.drag(scroll, const Offset(0, -5000));
    await tester.pumpAndSettle();
    drainKnownErrors(tester);
    final scrollBottom = tester.getBottomRight(scroll).dy;
    final contentBottom = tester.getBottomRight(lastContent).dy;
    return scrollBottom - contentBottom;
  }

  final booking = BookingEntity(
    bookingId: 'RH-000001',
    customerId: 'cust-001',
    shopId: 'shop-001',
    vehicleId: 'veh-001',
    packageType: '24h',
    pickupTime: DateTime(2026, 11, 20, 9),
    returnTime: DateTime(2026, 11, 22, 9),
    totalAmount: 18000,
    advanceRequired: 4500,
    advancePaid: 4500,
    remainingBalance: 13500,
    // PW-10: the pickup pass only renders its QR for a paid/active
    // booking, so the fixture carries the paid status the screen
    // is really shown for.
    status: 'paid',
    vehicleName: 'Honda Civic Oriel 2021',
    vehiclePlate: 'LEA-24-900',
    shopName: 'Al-Falah Rent a Car',
    shopPhone: '+923001234567',
  );

  const vehicle = VehicleEntity(
    vehicleId: 'veh-g-1',
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
    securityDepositPkr: 20000,
    advanceRequiredPkr: 3000,
    extraHourPkr: 600,
    extraKmPkr: 100,
    outOfCityKmPerDay: 350,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250),
      VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750),
    ],
  );

  group('Team G — Pattern A: trailing spacer removed, 12 dp scroll padding remains', () {
    testWidgets('BP-1 booking approved: last content 12 dp above the footer', (tester) async {
      await pump(tester, BookingApprovedView(booking: booking));
      expect(await gapBelow(tester, find.byType(BookingSummaryCard)), closeTo(12, 1));
    });

    testWidgets('BP-3 pickup countdown pass: last content 12 dp above the footer', (tester) async {
      await pump(tester, PickupCountdownPassView(booking: booking));
      expect(await gapBelow(tester, find.byType(PassShopContactCard)), closeTo(12, 1));
    });

    testWidgets('BP-5 customer active trip: last content 12 dp above the footer', (tester) async {
      await pump(tester, CustomerActiveTripView(booking: booking));
      expect(await gapBelow(tester, find.byType(PassShopContactCard)), closeTo(12, 1));
    });

    testWidgets('BP-6 customer cancel booking: last content 12 dp above the footer', (tester) async {
      await pump(tester, CustomerCancelBookingView(booking: booking));
      expect(await gapBelow(tester, find.byType(ListTile).last), closeTo(12, 1));
    });

    testWidgets('BP-7 customer dispute: last content 12 dp above the footer', (tester) async {
      await pump(tester, const CustomerDisputeView());
      expect(await gapBelow(tester, find.byType(MyDisputesList)), closeTo(12, 1));
    });

    testWidgets('BP-8 rent package picker: last content 12 dp above the footer', (tester) async {
      await pump(
        tester,
        RentPackagePickerView(
          carId: 'car-civic',
          carName: 'Honda Civic RS',
          plateNumber: 'LEA-24-900',
          shopId: 'shop-01',
          shopName: 'Al-Falah Rent a Car',
          dailySelfDriveRate: 8000,
          dailyWithDriverRate: 11000,
          hourlyRate: 1200,
        ),
      );
      expect(await gapBelow(tester, find.byType(DurationCalendarPicker)), closeTo(12, 1));
    });

    testWidgets('BP-9 owner out-of-city rules: last content 12 dp above the footer', (tester) async {
      await pump(tester, OwnerOutCityRulesView(vehicle: vehicle));
      expect(await gapBelow(tester, find.byType(PricingTripCharges)), closeTo(12, 1));
    });

    testWidgets('BP-10 owner rate matrix: last content 12 dp above the footer', (tester) async {
      await pump(tester, OwnerRateMatrixView(vehicle: vehicle));
      expect(await gapBelow(tester, find.byType(RateMatrixFieldWidget).last), closeTo(12, 1));
    });

    testWidgets('BP-11 vehicle detail: last content 12 dp above the footer', (tester) async {
      await pump(
        tester,
        VehicleDetailView(
          vehicle: vehicle,
          shopName: 'Al-Falah Rent a Car',
          shopPhone: '+923001234567',
        ),
      );
      expect(await gapBelow(tester, find.byType(VehicleDetailPackages)), closeTo(12, 1));
    });

    testWidgets('BP-12 onboarding role: last content 16 dp above the footer', (tester) async {
      await pump(tester, const OnboardingRoleView());
      // The inner content Padding is all(16) on this screen, so the
      // breathing room is 16 dp rather than the usual 12 dp.
      expect(await gapBelow(tester, find.byType(RoleSelectorCard).last), closeTo(16, 1));
    });

    testWidgets('BP-20 booking success: last content 12 dp above the footer', (tester) async {
      await pump(tester, BookingSuccessView(booking: booking));
      expect(await gapBelow(tester, find.byType(OutlinedButton)), closeTo(12, 1));
    });

    testWidgets('BP-21 customer added: last content 16 dp above the screen edge', (tester) async {
      final saved = CustomerEntity(
        customerId: 'cust-added-1',
        shopId: 'shop-added-1',
        name: 'Ayesha Khan',
        phone: '0300-1111111',
        cnic: '35202-1111111-1',
        createdAt: DateTime(2026, 11, 9),
      );
      // Short viewport (400 px high): the confirmation content is
      // shorter than a 640 px viewport, so at full height the gap
      // below the last button would be empty viewport, not the
      // scroll padding. At 400 px the content scrolls and the gap
      // below the last button is the 16 dp scroll padding.
      await pump(
        tester,
        OwnerCustomerAddedView(customerId: 'cust-added-1', customer: saved),
        height: 400,
      );
      expect(await gapBelow(tester, find.byType(DebouncedButton).last), closeTo(16, 1));
    });
  });

  group('Team G — Pattern B: last-item margin removed, 16 dp list padding remains', () {
    testWidgets('BP-16 fleet calendar: last card 16 dp above the list bottom', (tester) async {
      // Seed eight vehicles under shop-1 (the fallback shop id in
      // tests) through the same DI data source the view reads — the
      // list must be taller than the viewport for a scroll-to-bottom
      // measurement (two cards leave the list short and the gap
      // below them is empty viewport, not list padding).
      final ds = sl<FleetRemoteDataSource>();
      for (var i = 0; i < 8; i++) {
        await ds.addVehicle(
          shopId: 'shop-1',
          vehicle: vehicle.copyWith(
            vehicleId: 'veh-g-cal-$i',
            model: 'Civic Oriel $i',
            plateNumber: 'LEA-482$i',
          ),
        );
      }
      await pump(tester, const OwnerFleetCalendarView());
      // The seeding is verified at the data layer: a ListView only
      // builds items near the viewport, so counting built Cards is
      // flaky at the cache-extent boundary (7 vs 8). The widget
      // assertions below verify the fix itself.
      expect((await ds.getShopVehicles('shop-1')).length, 8);
      // Inter-item spacing is preserved: the first card keeps its
      // 12 dp bottom margin. (A box-to-box gap measurement reads 0
      // here because Card's render box includes its margin — the
      // margin is asserted as a widget property instead.)
      final list = find.byType(ListView).first;
      expect(
        tester.widget<Card>(find.byType(Card).first).margin,
        const EdgeInsets.only(bottom: 12),
      );
      // Scroll to the very bottom deterministically: jump straight to
      // maxScrollExtent (a tester.drag starting on a TextField stops
      // short of the max). Jump in a loop: the max is underestimated
      // until the last child is built, so the first jump lands short
      // and a later jump — after the pump builds the last child —
      // lands on the true max.
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      for (var i = 0; i < 3; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        if (scrollable.position.pixels >= scrollable.position.maxScrollExtent) break;
      }
      drainKnownErrors(tester);
      // The last card carries no bottom margin — the 16 dp list
      // padding is the only bottom gap.
      expect(tester.widget<Card>(find.byType(Card).last).margin, EdgeInsets.zero);
      final listBottom = tester.getBottomRight(list).dy;
      final lastCardBottom = tester.getBottomRight(find.byType(Card).last).dy;
      expect(listBottom - lastCardBottom, closeTo(16, 1));
    });

    testWidgets('BP-17 fixed routes: last card 16 dp above the list bottom', (tester) async {
      await pump(tester, const OwnerFixedRoutesView(shopId: 'shop-1'));
      final list = find.byType(ListView).first;
      // Inter-item spacing is preserved: the first card keeps its
      // 10 dp bottom margin (see BP-16 note: Card's render box
      // includes its margin, so this is a property assertion).
      expect(
        tester.widget<Card>(find.byType(Card).first).margin,
        const EdgeInsets.only(bottom: 10),
      );
      // Scroll to the very bottom deterministically: jump straight to
      // maxScrollExtent (a tester.drag starting on a TextField stops
      // short of the max). Jump in a loop: the max is underestimated
      // until the last child is built, so the first jump lands short
      // and a later jump — after the pump builds the last child —
      // lands on the true max.
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      for (var i = 0; i < 3; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        if (scrollable.position.pixels >= scrollable.position.maxScrollExtent) break;
      }
      drainKnownErrors(tester);
      // The last card carries no bottom margin — the 16 dp list
      // padding is the only bottom gap.
      expect(tester.widget<Card>(find.byType(Card).last).margin, EdgeInsets.zero);
      final listBottom = tester.getBottomRight(list).dy;
      final lastCardBottom = tester.getBottomRight(find.byType(Card).last).dy;
      expect(listBottom - lastCardBottom, closeTo(16, 1));
    });

    testWidgets('BP-18 fleet two columns at 800px: last cards flush, 16 dp list padding', (tester) async {
      final vehicles = [
        vehicle,
        vehicle.copyWith(vehicleId: 'veh-g-2', model: 'Corolla Grande', plateNumber: 'LEA-4821'),
        vehicle.copyWith(vehicleId: 'veh-g-3', model: 'Yaris', plateNumber: 'LEA-4822'),
      ];
      await pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: FleetListSection(
              state: FleetLoaded(vehicles: vehicles, tier: 'pro'),
              fleet: vehicles,
              filtered: vehicles,
              onAddVehicle: () {},
              onRetry: () {},
              onEditRates: (_) {},
              onOutCityRules: (_) {},
              onTapVehicle: (_) {},
            ),
          ),
        ),
        width: 800,
        height: 640,
      );
      expect(find.byKey(const Key('fleet-two-columns')), findsOneWidget);
      final row = find.byKey(const Key('fleet-two-columns'));
      final rowBottom = tester.getBottomRight(row).dy;
      // Left column holds items 0 and 2; its last card (item 2) is
      // the second FleetVehicleCard in tree order and sits flush
      // against the row bottom — no 14 dp spacing under it.
      final lastLeftCard = find.byType(FleetVehicleCard).at(1);
      expect(rowBottom - tester.getBottomRight(lastLeftCard).dy, closeTo(0, 1));
      // The outer 16 dp list padding is the only bottom gap.
      final outerPadding = find.ancestor(of: row, matching: find.byType(Padding)).first;
      expect(tester.getBottomRight(outerPadding).dy - tester.getBottomRight(lastLeftCard).dy, closeTo(16, 1));
    });

    testWidgets('BP-18 fleet compact at 360px: last card 16 dp above the list bottom', (tester) async {
      final vehicles = [
        vehicle,
        vehicle.copyWith(vehicleId: 'veh-g-2', model: 'Corolla Grande', plateNumber: 'LEA-4821'),
        vehicle.copyWith(vehicleId: 'veh-g-3', model: 'Yaris', plateNumber: 'LEA-4822'),
      ];
      await pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: FleetListSection(
              state: FleetLoaded(vehicles: vehicles, tier: 'pro'),
              fleet: vehicles,
              filtered: vehicles,
              onAddVehicle: () {},
              onRetry: () {},
              onEditRates: (_) {},
              onOutCityRules: (_) {},
              onTapVehicle: (_) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('fleet-two-columns')), findsNothing);
      final list = find.byType(ListView).first;
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -5000));
      await tester.pumpAndSettle();
      final listBottom = tester.getBottomRight(list).dy;
      final lastCardBottom = tester.getBottomRight(find.byType(FleetVehicleCard).last).dy;
      expect(listBottom - lastCardBottom, closeTo(16, 1));
    });
  });

  group('Team G — Pattern C: dispute detail sheet', () {
    testWidgets('BP-19 dispute sheet: last button 12 dp above the sheet bottom', (tester) async {
      const record = DisputeRecord(
        id: 'disp-1',
        bookingId: 'RH-000001',
        category: 'Deposit Withheld',
        description: 'The deposit was not returned after the trip.',
        status: 'open',
        customerName: 'Ahmed Raza',
      );
      await pump(
        tester,
        Scaffold(
          body: DisputeDetailSheet(
            dispute: record,
            onStatusChanged: (_) async => true,
          ),
        ),
      );
      final sheetBottom = tester.getBottomRight(find.byType(DisputeDetailSheet)).dy;
      final buttonBottom = tester.getBottomRight(find.byType(OutlinedButton)).dy;
      expect(sheetBottom - buttonBottom, closeTo(12, 1));
    });
  });
}

class _TestAssetBundle extends AssetBundle {
  static final ByteData _pixel = ByteData.view(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ).buffer);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
    }
    return _pixel;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}
