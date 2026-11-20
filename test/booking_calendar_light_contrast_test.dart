// Phone-test round 4, Worker 2 — booking calendar light-theme contrast.
//
// The bug: in LIGHT theme the four day fills were the bare pale
// containers (free #ECFDF5, requested #FFFBEB, confirmed #FEF2F2, past
// #F8FAFC), 1.01-1.05:1 apart and 1.04-1.09:1 from white, with no border
// — free / requested / confirmed / past were indistinguishable, the
// legend swatches were near-invisible, and selected (onSurface ring)
// vs today (primary ring) measured 1.18:1 apart. The day numbers
// themselves were never the problem (onSurface on the pale fills was
// 16-17:1); the fix deepens the fills, adds a full-strength state
// border, and gives the selected day a solid primary fill. Dark theme
// is unchanged (its fills/borders/numbers are asserted as such).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_calendar_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/availability_month_grid.dart';
import 'package:rentalhub/features/owner/presentation/widgets/booking_calendar_origin_colors.dart';
import 'package:rentalhub/features/owner/presentation/widgets/calendar_status_chip.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

BookingEntity _booking(DateTime month, int day, String status) {
  final pickup = DateTime(month.year, month.month, day, 10);
  return BookingEntity(
    bookingId: 'bk-$status-$day',
    customerId: 'cust-1',
    shopId: 'shop-1',
    vehicleId: 'veh-cal-1',
    packageType: '24h',
    pickupTime: pickup,
    returnTime: DateTime(month.year, month.month, day, 12),
    totalAmount: 9000,
    remainingBalance: 9000,
    status: status,
    customerName: 'Calendar Customer',
  );
}

Future<void> _pumpGrid(
  WidgetTester tester, {
  required DateTime month,
  List<BookingEntity> bookings = const [],
  DateTime? selectedDay,
}) async {
  // Phone viewport: at the default 800px test width the grid cells
  // (childAspectRatio 0.85) grow to ~130px tall and overflow.
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
    home: Scaffold(
      body: AvailabilityMonthGrid(
        month: month,
        bookings: bookings,
        selectedDay: selectedDay,
        onMonthChanged: (_) {},
        onDaySelected: (_) {},
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The day-cell Container (BoxDecoration) for [day], found via its number.
BoxDecoration _cellDecoration(WidgetTester tester, int day) {
  final finder = find.ancestor(
    of: find.text('$day'),
    matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration),
  );
  expect(finder, findsWidgets);
  return (tester.widget<Container>(finder.first).decoration as BoxDecoration);
}

/// The day-number TextStyle colour for [day].
Color? _numberColor(WidgetTester tester, int day) =>
    tester.widget<Text>(find.text('$day')).style?.color;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  tearDownAll(() async {
    await di.sl.reset();
  });

  group('light fills — measured contrast (no pump)', () {
    test('each state fill is visibly tinted vs the surface', () {
      const surface = AppColors.backgroundLight; // scaffold background
      for (final state in [
        CalendarDayState.free,
        CalendarDayState.requested,
        CalendarDayState.confirmed,
      ]) {
        final fill = AvailabilityMonthGrid.fillFor(Brightness.light, state);
        final ratio = _ratio(fill, surface);
        debugPrint('light $state fill vs surface: ${ratio.toStringAsFixed(2)}:1');
        expect(ratio, greaterThanOrEqualTo(1.30),
            reason: '$state fill must stand out from the surface');
      }
    });

    test('the old pale containers fail (the bug, pinned)', () {
      const surface = AppColors.backgroundLight;
      for (final container in [
        AppColors.successContainer,
        AppColors.warningContainer,
        AppColors.errorContainer,
      ]) {
        expect(_ratio(container, surface), lessThan(1.15));
      }
      expect(_ratio(AppColors.successContainer, AppColors.warningContainer),
          lessThan(1.10));
    });

    test('day numbers are legible on the deepened fills', () {
      for (final state in [
        CalendarDayState.free,
        CalendarDayState.requested,
        CalendarDayState.confirmed,
      ]) {
        final fill = AvailabilityMonthGrid.fillFor(Brightness.light, state);
        final number = AvailabilityMonthGrid.numberColorFor(
            Brightness.light, state, isSelected: false);
        final ratio = _ratio(number, fill);
        debugPrint('light $state number on fill: ${ratio.toStringAsFixed(2)}:1');
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
      // Past numbers are muted but still AA: 4.55:1.
      final pastFill =
          AvailabilityMonthGrid.fillFor(Brightness.light, CalendarDayState.past);
      final pastNumber = AvailabilityMonthGrid.numberColorFor(
          Brightness.light, CalendarDayState.past, isSelected: false);
      expect(_ratio(pastNumber, pastFill), greaterThanOrEqualTo(4.5));
      // Selected number (white on the solid primary fill): 15.14:1.
      final selectedNumber = AvailabilityMonthGrid.numberColorFor(
          Brightness.light, CalendarDayState.free, isSelected: true);
      expect(_ratio(selectedNumber, AppColors.primary),
          greaterThanOrEqualTo(4.5));
    });

    test('state borders are strong edges, distinct per state', () {
      final borders = <CalendarDayState, Border>{};
      for (final state in CalendarDayState.values) {
        final border =
            AvailabilityMonthGrid.borderFor(Brightness.light, state)!;
        borders[state] = border;
        // Past is muted by design (subtle 1px border, 1.18:1) — it is
        // set apart by the other three states being tinted, not by
        // standing out itself. The three live states need hard edges.
        if (state == CalendarDayState.past) {
          expect(border.top.color, AppColors.borderSubtle);
          expect(border.top.width, 1);
          continue;
        }
        final fill = AvailabilityMonthGrid.fillFor(Brightness.light, state);
        final edge = border.top.color;
        final ratio = _ratio(edge, fill);
        debugPrint('light $state border vs fill: ${ratio.toStringAsFixed(2)}:1');
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '$state border must read as a hard edge on its fill');
      }
      expect(borders[CalendarDayState.free]!.top.color,
          isNot(borders[CalendarDayState.requested]!.top.color));
      expect(borders[CalendarDayState.requested]!.top.color,
          isNot(borders[CalendarDayState.confirmed]!.top.color));
      expect(borders[CalendarDayState.free]!.top.color,
          isNot(borders[CalendarDayState.confirmed]!.top.color));
    });

    test('dark theme is unchanged', () {
      expect(
          AvailabilityMonthGrid.fillFor(
              Brightness.dark, CalendarDayState.free),
          AppColors.successContainerDark);
      expect(
          AvailabilityMonthGrid.fillFor(
              Brightness.dark, CalendarDayState.requested),
          AppColors.warningContainerDark);
      expect(
          AvailabilityMonthGrid.fillFor(
              Brightness.dark, CalendarDayState.confirmed),
          AppColors.errorContainerDark);
      expect(
          AvailabilityMonthGrid.fillFor(
              Brightness.dark, CalendarDayState.past),
          AppColors.surfaceContainerHighestDark);
      for (final state in CalendarDayState.values) {
        expect(AvailabilityMonthGrid.borderFor(Brightness.dark, state), isNull);
        expect(
            AvailabilityMonthGrid.numberColorFor(Brightness.dark, state,
                isSelected: false),
            AppColors.onSurfaceDark);
      }
    });
  });

  group('light theme — rendered grid', () {
    testWidgets('each day state renders its fill, border and legible number',
        (tester) async {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month + 1);
      await _pumpGrid(
        tester,
        month: month,
        bookings: [_booking(month, 10, 'requested'), _booking(month, 15, 'paid')],
        selectedDay: DateTime(month.year, month.month, 20),
      );
      expect(tester.takeException(), isNull);

      final states = {
        21: CalendarDayState.free,
        10: CalendarDayState.requested,
        15: CalendarDayState.confirmed,
      };
      for (final entry in states.entries) {
        final day = entry.key;
        final state = entry.value;
        final decoration = _cellDecoration(tester, day);
        expect(decoration.color,
            AvailabilityMonthGrid.fillFor(Brightness.light, state));
        final border = AvailabilityMonthGrid.borderFor(Brightness.light, state)!;
        expect(decoration.border, border);
        expect(_numberColor(tester, day),
            AvailabilityMonthGrid.numberColorFor(Brightness.light, state,
                isSelected: false));
        final ratio = _ratio(
            _numberColor(tester, day)!, decoration.color!);
        debugPrint('rendered $state day $day number: ${ratio.toStringAsFixed(2)}:1');
        expect(ratio, greaterThanOrEqualTo(4.5));
        expect(_ratio(decoration.color!, AppColors.backgroundLight),
            greaterThanOrEqualTo(1.30));
      }

      // Selected day: solid primary fill, white number, no ring — a
      // highlight, not another pale cell with a border.
      final selected = _cellDecoration(tester, 20);
      expect(selected.color, AppColors.primary);
      expect(selected.border, isNull);
      expect(_numberColor(tester, 20), Colors.white);
      expect(_ratio(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));

      // Weekday header: muted label, still AA on the background (4.55:1).
      final header = tester.widget<Text>(find.text('Mon'));
      expect(header.style?.color, AppColors.onSurfaceVariantLight);
      expect(_ratio(header.style!.color!, AppColors.backgroundLight),
          greaterThanOrEqualTo(4.5));
    });

    testWidgets('today ring is distinct from the selected fill',
        (tester) async {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final otherDay = now.day < daysInMonth ? now.day + 1 : now.day - 1;
      await _pumpGrid(
        tester,
        month: DateTime(now.year, now.month),
        selectedDay: DateTime(now.year, now.month, otherDay),
      );
      expect(tester.takeException(), isNull);

      final today = _cellDecoration(tester, now.day);
      expect(today.color,
          AvailabilityMonthGrid.fillFor(Brightness.light, CalendarDayState.free));
      expect(today.border,
          Border.all(color: AppColors.primary, width: 2));
      // The 5px today dot, in primary.
      expect(
          find.byWidgetPredicate((w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration as BoxDecoration).color == AppColors.primary),
          findsOneWidget);
      // The selected day is a solid fill with no border: it cannot be
      // mistaken for today's ringed cell.
      final selected = _cellDecoration(tester, otherDay);
      expect(selected.color, AppColors.primary);
      expect(selected.border, isNull);
      expect(selected.color, isNot(today.color));
    });

    testWidgets('past days are muted and distinct from free days',
        (tester) async {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month - 1);
      await _pumpGrid(tester, month: month);
      expect(tester.takeException(), isNull);

      final past = _cellDecoration(tester, 15);
      expect(past.color, AppColors.surfaceContainerHighestLight);
      expect(past.border,
          Border.all(color: AppColors.borderSubtle, width: 1));
      expect(_numberColor(tester, 15), AppColors.onSurfaceVariantLight);
      expect(_ratio(_numberColor(tester, 15)!, past.color!),
          greaterThanOrEqualTo(4.5));
      expect(past.color,
          isNot(AvailabilityMonthGrid.fillFor(Brightness.light, CalendarDayState.free)));
    });
  });

  group('light theme — legend matches the grid', () {
    testWidgets('legend swatches use the grid fill and border per state',
        (tester) async {
      const vehicle = VehicleEntity(
        vehicleId: 'veh-cal-1',
        shopId: 'shop-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2022,
        plateNumber: 'ICT-9912',
        rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: const OwnerVehicleCalendarView(vehicle: vehicle),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Booking Calendar'), findsOneWidget);

      final labels = {
        'Free': CalendarDayState.free,
        'Requested': CalendarDayState.requested,
        'Confirmed': CalendarDayState.confirmed,
        'Past': CalendarDayState.past,
      };
      for (final entry in labels.entries) {
        final row = find.ancestor(
          of: find.text(entry.key),
          matching: find.byType(Row),
        );
        expect(row, findsWidgets);
        final swatch = find.descendant(
          of: row.first,
          matching: find.byWidgetPredicate((w) =>
              w is Container && w.decoration is BoxDecoration),
        );
        expect(swatch, findsOneWidget);
        final decoration =
            tester.widget<Container>(swatch).decoration as BoxDecoration;
        expect(decoration.color,
            AvailabilityMonthGrid.fillFor(Brightness.light, entry.value));
        expect(decoration.border,
            AvailabilityMonthGrid.borderFor(Brightness.light, entry.value));
        // Free / requested / confirmed swatches must themselves be
        // visible on white. Past is muted by design (pale fill, subtle
        // border) — it matches its cell and is set apart by the other
        // three being tinted, not by standing out itself.
        if (entry.value != CalendarDayState.past) {
          expect(_ratio(decoration.color!, AppColors.surfaceLight),
              greaterThanOrEqualTo(1.30));
        } else {
          expect(decoration.border, isNotNull);
        }
      }
    });
  });

  group('light theme — day-detail status chips (coordinator add-on)', () {
    test('chip label contrast is AA in light theme, dark unchanged', () {
      final light = AppTheme.lightTheme.colorScheme;
      final dark = AppTheme.darkTheme.colorScheme;
      const statuses = ['completed', 'requested', 'rejected', 'unknown'];
      for (final status in statuses) {
        final c = CalendarStatusChip.colorsFor(
          brightness: Brightness.light,
          status: status,
          onSurface: light.onSurface,
          surfaceContainerHighest: light.surfaceContainerHighest,
        );
        // Label on background must be AA; known statuses also carry a
        // strong border that stands off the fill.
        expect(_ratio(c.label, c.background), greaterThanOrEqualTo(4.5),
            reason: '$status label');
        if (status != 'unknown') {
          expect(c.border, isNotNull, reason: '$status border');
          expect(_ratio(c.border!, c.background), greaterThanOrEqualTo(3.0),
              reason: '$status border');
        }
        // Dark theme keeps the old pairs: container + on-container,
        // no border.
        final d = CalendarStatusChip.colorsFor(
          brightness: Brightness.dark,
          status: status,
          onSurface: dark.onSurface,
          surfaceContainerHighest: dark.surfaceContainerHighest,
        );
        expect(d.border, isNull, reason: '$status dark border');
      }
      // Spot-check the old failing value is gone in light: the warning
      // label was #F59E0B (2.07:1) on its container.
      final requested = CalendarStatusChip.colorsFor(
        brightness: Brightness.light,
        status: 'requested',
        onSurface: light.onSurface,
        surfaceContainerHighest: light.surfaceContainerHighest,
      );
      expect(requested.label, light.onSurface);
      expect(requested.border, AppColors.orangeTextFor(Brightness.light));
    });

    testWidgets('chip renders with the mapped colours', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: CalendarStatusChip(status: 'requested', label: 'Requested'),
        ),
      ));
      await tester.pumpAndSettle();
      final chip = tester.widget<Chip>(find.byType(Chip));
      final scheme = AppTheme.lightTheme.colorScheme;
      expect(
          chip.backgroundColor,
          CalendarStatusChip.colorsFor(
            brightness: Brightness.light,
            status: 'requested',
            onSurface: scheme.onSurface,
            surfaceContainerHighest: scheme.surfaceContainerHighest,
          ).background);
      expect(chip.side, isNotNull);
    });
  });

  group('light theme — O25 origin blocks (day / week calendar)', () {
    test('white labels on the navy and orange fills are AA', () {
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
          debugPrint('O25 $brightness $origin label on fill: '
              '${ratio.toStringAsFixed(2)}:1');
          expect(ratio, greaterThanOrEqualTo(4.5),
              reason: '$brightness $origin label');
        }
      }
      // The two origin fills are distinguishable from each other and
      // from the light surface.
      final online = BookingCalendarOriginColors.fillFor(
          Brightness.light, BookingCalendarOriginColors.online);
      final walkIn = BookingCalendarOriginColors.fillFor(
          Brightness.light, BookingCalendarOriginColors.walkIn);
      expect(_ratio(online, walkIn), greaterThanOrEqualTo(2.0));
      expect(_ratio(online, AppColors.surfaceLight),
          greaterThanOrEqualTo(1.30));
      expect(_ratio(walkIn, AppColors.surfaceLight),
          greaterThanOrEqualTo(1.30));
    });
  });
}
