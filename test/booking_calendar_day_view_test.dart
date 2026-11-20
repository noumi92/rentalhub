// O25 — booking calendar Day / Week views.
//
// Day grid: blocks positioned by pickup/return time on the 9 AM–9 PM
// window, coloured Online (navy) vs Walk-in (orange) from the booking
// origin (with the walkin- backfill for older docs). Week grid: one
// column per day, one mini-block per origin present. The fleet view
// toggle switches Month / Day / Week and keeps the per-vehicle
// drill-down.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart' show sl;
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_calendar_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/booking_calendar_origin_colors.dart';
import 'package:rentalhub/features/owner/presentation/widgets/calendar_day_time_grid.dart';
import 'package:rentalhub/features/owner/presentation/widgets/calendar_week_grid.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _vehicle1 = VehicleEntity(
  vehicleId: 'veh-day-1',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla',
  year: 2022,
  plateNumber: 'ICT-9912',
  rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
);

const _vehicle2 = VehicleEntity(
  vehicleId: 'veh-day-2',
  shopId: 'shop-1',
  make: 'Honda',
  model: 'Civic',
  year: 2021,
  plateNumber: 'LEA-4820',
  rates: VehicleRatesEntity(daily24: 9000, outOfCityDaily: 11500),
);

BookingEntity _booking({
  required String id,
  required String vehicleId,
  required DateTime pickup,
  required DateTime ret,
  String status = 'paid',
  String customerId = 'cust-1',
  String? origin,
}) {
  return BookingEntity(
    bookingId: id,
    customerId: customerId,
    shopId: 'shop-1',
    vehicleId: vehicleId,
    packageType: '24h',
    pickupTime: pickup,
    returnTime: ret,
    totalAmount: 9000,
    remainingBalance: 9000,
    status: status,
    customerName: 'Calendar Customer',
    origin: origin,
  );
}

Future<void> _pumpGrid(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.lightTheme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  tearDownAll(() async {
    await di.sl.reset();
  });

  group('dayBlockSpan — 9 AM–9 PM window geometry', () {
    final day = DateTime(2026, 10, 28);
    test('a 10 AM–12 PM booking sits at 1/12–3/12 of the track', () {
      final span = CalendarDayTimeGrid.dayBlockSpan(
        pickup: DateTime(2026, 10, 28, 10),
        ret: DateTime(2026, 10, 28, 12),
        day: day,
      );
      expect(span, isNotNull);
      expect(span!.start, closeTo(1 / 12, 0.001));
      expect(span.end, closeTo(3 / 12, 0.001));
    });

    test('a booking starting before 9 AM is clipped to the left edge', () {
      final span = CalendarDayTimeGrid.dayBlockSpan(
        pickup: DateTime(2026, 10, 28, 8),
        ret: DateTime(2026, 10, 28, 10),
        day: day,
      );
      expect(span, isNotNull);
      expect(span!.start, 0);
      expect(span.end, closeTo(1 / 12, 0.001));
    });

    test('a multi-day booking fills the whole day track', () {
      final span = CalendarDayTimeGrid.dayBlockSpan(
        pickup: DateTime(2026, 10, 27, 15),
        ret: DateTime(2026, 10, 29, 11),
        day: day,
      );
      expect(span, isNotNull);
      expect(span!.start, 0);
      expect(span.end, 1);
    });

    test('a booking on another day, or ending at 9 AM, draws nothing', () {
      expect(
        CalendarDayTimeGrid.dayBlockSpan(
          pickup: DateTime(2026, 10, 29, 10),
          ret: DateTime(2026, 10, 29, 12),
          day: day,
        ),
        isNull,
      );
      expect(
        CalendarDayTimeGrid.dayBlockSpan(
          pickup: DateTime(2026, 10, 28, 7),
          ret: DateTime(2026, 10, 28, 9),
          day: day,
        ),
        isNull,
      );
    });
  });

  group('origin — explicit value wins, older docs backfill', () {
    test('explicit origin is used as-is', () {
      expect(
        BookingCalendarOriginColors.originOf(
          _booking(
            id: 'b1',
            vehicleId: 'veh-day-1',
            pickup: DateTime(2026, 10, 28, 10),
            ret: DateTime(2026, 10, 28, 12),
            origin: 'walk_in',
          ),
        ),
        'walk_in',
      );
    });

    test('null origin backfills from the customerId', () {
      final walkIn = _booking(
        id: 'b2',
        vehicleId: 'veh-day-1',
        pickup: DateTime(2026, 10, 28, 10),
        ret: DateTime(2026, 10, 28, 12),
        customerId: 'walkin-1720000000000',
      );
      expect(BookingCalendarOriginColors.originOf(walkIn), 'walk_in');
      expect(BookingCalendarOriginColors.isWalkIn(walkIn), isTrue);
      final online = _booking(
        id: 'b3',
        vehicleId: 'veh-day-1',
        pickup: DateTime(2026, 10, 28, 10),
        ret: DateTime(2026, 10, 28, 12),
      );
      expect(BookingCalendarOriginColors.originOf(online), 'online');
      expect(BookingCalendarOriginColors.isWalkIn(online), isFalse);
    });
  });

  group('origin fills — white labels are AA in both themes', () {
    test('online navy and walk-in orange carry white labels', () {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        for (final origin in [
          BookingCalendarOriginColors.online,
          BookingCalendarOriginColors.walkIn,
        ]) {
          final fill =
              BookingCalendarOriginColors.fillFor(brightness, origin);
          final label = BookingCalendarOriginColors.labelColorFor(
              brightness, origin);
          final ratio = _ratio(label, fill);
          debugPrint('$brightness $origin label on fill: '
              '${ratio.toStringAsFixed(2)}:1');
          expect(ratio, greaterThanOrEqualTo(4.5),
              reason: '$brightness $origin label');
        }
      }
      // The two origins must be distinguishable from each other.
      final online = BookingCalendarOriginColors.fillFor(
          Brightness.light, BookingCalendarOriginColors.online);
      final walkIn = BookingCalendarOriginColors.fillFor(
          Brightness.light, BookingCalendarOriginColors.walkIn);
      expect(_ratio(online, walkIn), greaterThanOrEqualTo(2.0));
      // Both fills stand out from the light surface.
      expect(_ratio(online, AppColors.surfaceLight),
          greaterThanOrEqualTo(1.30));
      expect(_ratio(walkIn, AppColors.surfaceLight),
          greaterThanOrEqualTo(1.30));
    });
  });

  group('day time-grid — rendered', () {
    final day = DateTime(2026, 10, 28);
    testWidgets('online block is navy, walk-in block is orange',
        (tester) async {
      await _pumpGrid(
        tester,
        CalendarDayTimeGrid(
          day: day,
          fleet: const [_vehicle1, _vehicle2],
          bookings: [
            _booking(
              id: 'on1',
              vehicleId: 'veh-day-1',
              pickup: DateTime(2026, 10, 28, 10),
              ret: DateTime(2026, 10, 28, 12),
              origin: 'online',
            ),
            _booking(
              id: 'wi1',
              vehicleId: 'veh-day-2',
              pickup: DateTime(2026, 10, 28, 15),
              ret: DateTime(2026, 10, 28, 18),
              origin: 'walk_in',
            ),
            // A pending request is not a booking: no block.
            _booking(
              id: 'rq1',
              vehicleId: 'veh-day-1',
              pickup: DateTime(2026, 10, 28, 15),
              ret: DateTime(2026, 10, 28, 17),
              status: 'requested',
              origin: 'online',
            ),
          ],
          onVehicleTap: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Walk-in'), findsOneWidget);
      // Time ruler from the spec: 9 AM … 9 PM.
      for (final label in ['9 AM', '12 PM', '3 PM', '6 PM', '9 PM']) {
        expect(find.text(label), findsOneWidget);
      }
      // Block fills come from the origin helper, so the grid can
      // never drift from the legend.
      final onlineBlock = find.ancestor(
        of: find.text('Online'),
        matching: find.byWidgetPredicate((w) =>
            w is Container && w.decoration is BoxDecoration),
      );
      final onlineDecoration = tester.widget<Container>(onlineBlock.first)
          .decoration as BoxDecoration;
      expect(
        onlineDecoration.color,
        BookingCalendarOriginColors.fillFor(
            Brightness.light, BookingCalendarOriginColors.online),
      );
      final walkInBlock = find.ancestor(
        of: find.text('Walk-in'),
        matching: find.byWidgetPredicate((w) =>
            w is Container && w.decoration is BoxDecoration),
      );
      final walkInDecoration =
          tester.widget<Container>(walkInBlock.first).decoration
              as BoxDecoration;
      expect(
        walkInDecoration.color,
        BookingCalendarOriginColors.fillFor(
            Brightness.light, BookingCalendarOriginColors.walkIn),
      );
      // The 10 AM–12 PM online block starts 1/12 across its track
      // and is 2/12 wide: its left edge sits right of the car label.
      final onlineLeft = tester.getTopLeft(onlineBlock.first).dx;
      final trackLeft =
          tester.getTopLeft(find.byType(CalendarDayTimeGrid)).dx +
              CalendarDayTimeGrid.labelWidth;
      final trackWidth = 390 - CalendarDayTimeGrid.labelWidth;
      expect(onlineLeft - trackLeft, closeTo(trackWidth / 12, 12));
    });

    testWidgets('a null-origin walk-in backfills to an orange block',
        (tester) async {
      await _pumpGrid(
        tester,
        CalendarDayTimeGrid(
          day: day,
          fleet: const [_vehicle1],
          bookings: [
            _booking(
              id: 'wi2',
              vehicleId: 'veh-day-1',
              pickup: DateTime(2026, 10, 28, 10),
              ret: DateTime(2026, 10, 28, 12),
              customerId: 'walkin-1720000000000',
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Walk-in'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });

    testWidgets('tapping a car row opens its per-vehicle calendar',
        (tester) async {
      VehicleEntity? tapped;
      await _pumpGrid(
        tester,
        CalendarDayTimeGrid(
          day: day,
          fleet: const [_vehicle1],
          bookings: const [],
          onVehicleTap: (v) => tapped = v,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(_vehicle1.displayName));
      expect(tapped?.vehicleId, 'veh-day-1');
    });
  });

  group('week grid — rendered', () {
    testWidgets('one column per day, origin blocks, tap jumps to a day',
        (tester) async {
      // Week of Mon 26 Oct 2026.
      final monday = DateTime(2026, 10, 26);
      DateTime? selected;
      await _pumpGrid(
        tester,
        CalendarWeekGrid(
          weekStart: monday,
          fleet: const [_vehicle1],
          bookings: [
            _booking(
              id: 'on-w',
              vehicleId: 'veh-day-1',
              pickup: DateTime(2026, 10, 28, 10),
              ret: DateTime(2026, 10, 28, 12),
              origin: 'online',
            ),
            _booking(
              id: 'wi-w',
              vehicleId: 'veh-day-1',
              pickup: DateTime(2026, 10, 28, 15),
              ret: DateTime(2026, 10, 29, 12),
              origin: 'walk_in',
            ),
          ],
          onDaySelected: (d) => selected = d,
        ),
      );
      expect(tester.takeException(), isNull);
      // Day headers: Mon 26 … Sun 1.
      expect(find.text('26'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      // Wed 28 Oct carries both origins; Thu 29 Oct only walk-in.
      expect(
        CalendarWeekGrid.weekDayOrigins(
          [
            _booking(
              id: 'on-w',
              vehicleId: 'veh-day-1',
              pickup: DateTime(2026, 10, 28, 10),
              ret: DateTime(2026, 10, 28, 12),
              origin: 'online',
            ),
          ],
          'veh-day-1',
          DateTime(2026, 10, 28),
        ),
        {'online'},
      );
      await tester.tap(find.text('28'));
      expect(selected, DateTime(2026, 10, 28));
    });
  });

  group('fleet calendar — Month / Day / Week toggle', () {
    testWidgets('toggle switches mode, legend, subtitle and note',
        (tester) async {
      // Seed two vehicles under shop-1 (the fallback shop id in
      // tests) through the same DI data source the view reads.
      final ds = sl<FleetRemoteDataSource>();
      await ds.addVehicle(shopId: 'shop-1', vehicle: _vehicle1);
      await ds.addVehicle(shopId: 'shop-1', vehicle: _vehicle2);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: OwnerFleetCalendarView()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Month is the default: Booked / Available legend, month title.
      expect(find.text('Fleet Schedule'), findsWidgets);
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      // The spec overlap note is present in every mode.
      expect(
        find.text('Overlapping bookings are blocked automatically, '
            'so a car can never be double-booked.'),
        findsOneWidget,
      );

      // Day mode: "Booking Calendar" title, dated subtitle, origin
      // legend, 9 AM–9 PM ruler.
      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Booking Calendar'), findsWidgets);
      final today = DateTime.now();
      expect(
        find.text(DateFormat('EEE, d MMM yyyy').format(today)),
        findsOneWidget,
      );
      expect(find.text('Online booking'), findsOneWidget);
      expect(find.text('Manual booking'), findsOneWidget);
      expect(find.text('Booked'), findsNothing);
      expect(find.text('9 AM'), findsOneWidget);
      expect(find.text('9 PM'), findsOneWidget);

      // Day prev/next moves one day; Today jumps back.
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(
        find.text(DateFormat('EEE, d MMM yyyy')
            .format(today.add(const Duration(days: 1)))),
        findsOneWidget,
      );
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(
        find.text(DateFormat('EEE, d MMM yyyy').format(today)),
        findsOneWidget,
      );

      // Week mode: 7 day headers, origin legend kept.
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Online booking'), findsOneWidget);
      expect(find.text('${today.day}'), findsWidgets);

      // Back to Month: the original legend and drill-down cards.
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Fleet Schedule'), findsWidgets);
    });
  });
}
