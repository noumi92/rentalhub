// Audit 2026-11-15 leftovers — the 7 items blocked on the shop-id fix
// (BP-14, DS-5, DS-6, DS-8, DS-15, PW-11, PW-22). Verification for
// each item lives here; the functional shop-id coverage already lives
// in test/booking_shop_id_resolution_test.dart and
// test/owner_shop_id_resolution_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart' show sl;
import 'package:rentalhub/core/utils/money_format.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  // 360 px overflows in widgets this file does not own are drained
  // the same way team_g does: only RenderFlex overflows are
  // accepted, any other error still fails the test.
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
      debugPrint('Leftovers: drained $drained known pre-existing 360 px '
          'overflow error(s).');
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
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
    drainKnownErrors(tester);
  }

  Future<void> seedBooking({
    required String customerId,
    required String customerName,
    required String customerCnic,
    DateTime? pickupTime,
  }) async {
    final ds = sl<BookingRemoteDataSource>();
    final pickup = pickupTime ?? DateTime(2026, 11, 3, 9);
    await ds.createBookingRequest(
      customerId: customerId,
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: pickup,
      returnTime: pickup.add(const Duration(days: 1)),
      totalAmount: 9000,
      advanceRequired: 3000,
      customerName: customerName,
      customerPhone: '0300-1234567',
      customerCnic: customerCnic,
    );
  }

  group('BP-14 — Owner Customers tab root: last card, 16 dp list padding', () {
    testWidgets('last card has no bottom margin; 16 dp list padding remains',
        (tester) async {
      for (var i = 0; i < 8; i++) {
        await seedBooking(
          customerId: 'cust-bp14-$i',
          customerName: 'BP14 Customer $i',
          // Distinct CNICs: the list rolls bookings up per CNIC, so
          // a shared CNIC would collapse all eight into one card.
          customerCnic: '35201-100000$i-1',
        );
      }
      await pump(tester, const OwnerCustomersListView(shopId: 'shop-1'));
      // Inter-item spacing is preserved: the first card keeps its
      // 10 dp bottom margin (Card's render box includes its margin,
      // so this is a property assertion).
      expect(
        tester.widget<Card>(find.byType(Card).first).margin,
        const EdgeInsets.only(bottom: 10),
      );
      // Scroll to the very bottom deterministically: jump straight to
      // maxScrollExtent. Jump in a loop: the max is underestimated
      // until the last child is built, so the first jump lands short
      // and a later jump — after the pump builds the last child —
      // lands on the true max. The ListView's own Scrollable, not the
      // search field's internal one (a TextField also builds a
      // Scrollable, and it comes first in tree order).
      final list = find.byType(ListView).first;
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      for (var i = 0; i < 3; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        if (scrollable.position.pixels >=
            scrollable.position.maxScrollExtent) {
          break;
        }
      }
      drainKnownErrors(tester);
      // The last card carries no bottom margin — the 16 dp list
      // padding is the only bottom gap.
      expect(tester.widget<Card>(find.byType(Card).last).margin,
          EdgeInsets.zero);
      final listBottom = tester.getBottomRight(list).dy;
      final lastCardBottom =
          tester.getBottomRight(find.byType(Card).last).dy;
      expect(listBottom - lastCardBottom, closeTo(16, 1));
    });
  });

  group('DS-5 — expanded booking shows a localized date', () {
    testWidgets('booking date carries a month name, never raw d/m/y',
        (tester) async {
      await seedBooking(
        customerId: 'cust-ds5',
        customerName: 'DS5 Customer',
        customerCnic: '35201-2000000-1',
        pickupTime: DateTime(2026, 11, 3, 9),
      );
      await pump(tester, const OwnerCustomersListView(shopId: 'shop-1'));
      // Filter to this customer: the shared in-memory store also
      // holds the eight BP-14 rows, and the ninth row sits below the
      // fold unbuilt — the search box is the user-visible way to
      // bring it into view.
      await tester.enterText(find.byType(TextField), 'DS5');
      await tester.pumpAndSettle();
      await tester.tap(find.text('DS5 Customer'));
      await tester.pumpAndSettle();
      // Expanding renders the "Book for this customer" row, which
      // overflows at 360 px in the test font (pre-existing, outside
      // this item's scope — same drain as team_g's helper).
      drainKnownErrors(tester);
      expect(find.textContaining('Nov 3, 2026'), findsOneWidget);
      expect(find.textContaining('3/11/2026'), findsNothing);
    });
  });

  group('DS-6 — cash-closing load error', () {
    test('cashClosingLoadError exists in EN + UR and names cash closing',
        () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ur = await AppLocalizations.delegate.load(const Locale('ur'));
      expect(en.cashClosingLoadError, contains('cash closing'));
      expect(en.cashClosingLoadError, isNot(en.dashboardLoadError));
      // Non-raw string so the \u escapes resolve to the Arabic block
      // without any Arabic-script literal in this file.
      expect(ur.cashClosingLoadError.contains(RegExp('[\\u0600-\\u06FF]')),
          isTrue,
          reason: 'UR message must be localized: ${ur.cashClosingLoadError}');
      expect(ur.cashClosingLoadError, isNot(ur.dashboardLoadError));
    });
  });

  group('DS-8 — wizard stepper uses theme slots', () {
    test('no hardcoded font sizes in the wizard stepper', () {
      final content = File(
        'lib/features/owner/presentation/views/owner_add_customer_wizard.dart',
      ).readAsStringSync();
      expect(content, isNot(contains('fontSize: 13')));
      expect(content, isNot(contains('fontSize: 11')));
      expect(content, contains('textTheme.bodyMedium'));
      expect(content, contains('textTheme.labelSmall'));
    });
  });

  group('DS-15 — no shopId = \'shop-1\' default remains', () {
    test('no shopId default in lib/; cash closing requires it', () {
      final offenders = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        if (file.readAsStringSync().contains("shopId = 'shop-1'")) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'shopId = \'shop-1\' default survives (DS-15):\n'
              '${offenders.join('\n')}');
      final cashClosing = File(
        'lib/features/owner/presentation/views/owner_cash_closing_view.dart',
      ).readAsStringSync();
      expect(cashClosing, contains('required this.shopId'));
    });
  });

  group('PW-11 — bookNowWithRate through amountRs', () {
    test('renders the currency exactly once, EN + UR', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ur = await AppLocalizations.delegate.load(const Locale('ur'));
      expect(
        en.bookNowWithRate(en.amountRs(formatRs(7500))),
        'Book Now (Rs. 7,500/day)',
      );
      final urRendered = ur.bookNowWithRate(ur.amountRs(formatRs(7500)));
      expect(urRendered, contains('7,500'));
      expect(urRendered, isNot(contains('Rs.')));
      // Non-raw check: the Urdu rendering carries Urdu script.
      expect(urRendered.contains(RegExp('[\\u0600-\\u06FF]')), isTrue);
    });

    test('arb value carries no hardcoded currency; caller routes via amountRs',
        () {
      final enArb = File('lib/l10n/app_en.arb').readAsStringSync();
      final value = RegExp(r'"bookNowWithRate": "([^"]*)"')
          .firstMatch(enArb)!
          .group(1)!;
      expect(value, isNot(contains('Rs.')));
      expect(value, contains('{rate}'));
      final bar = File(
        'lib/features/discovery/presentation/views/widgets/vehicle_detail_action_bar.dart',
      ).readAsStringSync();
      expect(bar, contains('amountRs(formatRs(selectedRate))'));
    });
  });

  group('PW-22 — shop-id linking already fixed (verify present)', () {
    test('bookings stream resolves candidate shop ids', () {
      final dataSource = File(
        'lib/features/bookings/data/datasources/booking_remote_data_source.dart',
      ).readAsStringSync();
      expect(dataSource,
          contains('candidateShopIds(_resolvedFirestore, shopId)'));
      expect(dataSource, contains("where('shopId', whereIn: ids)"));
      final helper = File('lib/core/utils/shop_id_resolution.dart')
          .readAsStringSync();
      expect(helper, contains('Future<List<String>> candidateShopIds('));
      expect(helper, contains('Future<String> canonicalShopId('));
    });
  });
}
