// Phase F: localization tests — the bilingual gate (plan F1/F2).
//
// Pumps the 10 tab screens in Locale('ur') and asserts:
//   (1) Directionality is RTL,
//   (2) no overflow (via TestHarness, which fails on any FlutterError),
//   (3) no hardcoded English visible on screen — implemented by scanning
//       every rendered Text/RichText for ASCII English words, excluding
//       numbers, brand names, proper nouns and strings that are
//       legitimately data (names, plates, CNICs).
// The same screens are pumped in Locale('en') and asserted LTR.
// A negative control proves the English scan actually flags a hardcoded
// English literal (a detector that never fires proves nothing).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_support_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

/// Latin tokens that legitimately render inside Urdu copy (verified
/// against lib/l10n/app_ur.arb): acronyms and format fragments, not
/// English prose. 'Out of City' is a package-type name quoted in a
/// FAQ answer. Anything else ASCII with 3+ letters is treated as
/// hardcoded English.
const Set<String> _allowedLatin = {
  'RentalHub',
  'Rentalhub',
  'KYC',
  'NADRA',
  'SOS',
  'Rs',
  'PK',
  'PKR',
  'ICT',
  'LEA',
  'GPS',
  'QR',
  'AC',
  'ID',
  'IBAN',
  'TID',
  'RH',
  'XX',
  'dd',
  'mm',
  'yyyy',
  'API',
  'JPG',
  'PNG',
  'PDF',
  'cPanel',
  'LTV',
  'HTV',
  'VIP',
  'WhatsApp',
  'Google',
  'CNIC',
  'SMS',
  'OTP',
  'URL',
  'AM',
  'PM',
  'km',
  'Out',
  'of',
  'City',
};

/// The ASCII English words in [s] (3+ letters, not allowlisted).
/// Urdu script, digits, punctuation and data (plates, CNICs, phones,
/// amounts, dates) yield nothing.
List<String> _englishWords(String s) {
  return RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?")
      .allMatches(s)
      .map((m) => m.group(0)!)
      .where((w) => w.length >= 3 && !_allowedLatin.contains(w))
      .toList();
}

/// True for comma-separated proper-noun strings — shop addresses
/// ('Gulberg III, Lahore', rendered as 'address, city') and personal
/// names. Addresses are stored data, not UI copy: they are shown
/// verbatim in every locale, like a plate or a CNIC. The comma is
/// the discriminator — title-case UI copy ('Find Verified Rental
/// Shops') has no comma, and comma copy with a lowercase word
/// ('Booking confirmed, thank you!') is still flagged.
bool _isAddressLike(String s) {
  if (!s.contains(', ')) return false;
  final words =
      RegExp(r"[A-Za-z]+").allMatches(s).map((m) => m.group(0)!).toList();
  if (words.isEmpty) return false;
  return words.every((w) =>
      w.length < 2 ||
      _allowedLatin.contains(w) ||
      RegExp(r'^[IVX]+$').hasMatch(w) ||
      w[0] == w[0].toUpperCase());
}

/// Every rendered string on screen, deduplicated. Text covers plain
/// labels; RichText covers Text.rich spans.
List<String> _renderedStrings(WidgetTester tester) {
  final out = <String>{};
  for (final w in tester.widgetList<Text>(find.byType(Text))) {
    final s = w.data ?? w.textSpan?.toPlainText();
    if (s != null && s.trim().isNotEmpty) out.add(s);
  }
  for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
    final s = w.text.toPlainText();
    if (s.trim().isNotEmpty) out.add(s);
  }
  return out.toList();
}

/// Rendered strings that contain hardcoded English, each annotated
/// with the offending words.
List<String> _englishHits(WidgetTester tester) {
  final hits = <String>[];
  for (final s in _renderedStrings(tester)) {
    if (_isAddressLike(s)) continue;
    final words = _englishWords(s);
    if (words.isNotEmpty) hits.add('$s  [${words.join(', ')}]');
  }
  return hits;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  const delegates = AppLocalizations.localizationsDelegates;
  const supported = AppLocalizations.supportedLocales;

  /// Pumps [screen] at 360px / 1.35x in [locale], captures the ambient
  /// [Directionality] and returns it with the English-scan hits.
  /// The harness itself fails the test on any overflow.
  Future<({TextDirection direction, List<String> englishHits})>
      pumpLocalized(
    WidgetTester tester,
    Widget screen,
    Locale locale,
  ) async {
    var direction = TextDirection.ltr;
    await TestHarness.pumpScreenWithOverflowCheck(
      tester: tester,
      screen: Builder(
        builder: (context) {
          direction = Directionality.of(context);
          return screen;
        },
      ),
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: delegates,
      supportedLocales: supported,
    );
    return (direction: direction, englishHits: _englishHits(tester));
  }

  final screens = <(String, Widget)>[
    ('Customer Home', const CustomerHomeView()),
    ('Customer Bookings', const CustomerBookingsView()),
    ('Customer Wallet', const CustomerWalletView()),
    ('Customer Support', const CustomerSupportView()),
    ('Customer Profile', const CustomerProfileView()),
    ('Owner Dashboard', const OwnerDashboardView()),
    ('Owner Fleet', const OwnerFleetView()),
    ('Owner Requests', const OwnerBookingRequestsView()),
    ('Owner Customers', const OwnerCustomersListView()),
    ('Owner Settings', const OwnerSettingsView()),
  ];

  group('Urdu locale: RTL + no overflow + no hardcoded English', () {
    for (final (name, screen) in screens) {
      testWidgets('$name in ur', (tester) async {
        final result =
            await pumpLocalized(tester, screen, const Locale('ur'));
        expect(result.direction, TextDirection.rtl,
            reason: '$name must mirror to RTL in the Urdu locale');
        expect(result.englishHits, isEmpty,
            reason: '$name still shows hardcoded English in Urdu:\n'
                '${result.englishHits.join('\n')}');
        // Multi-viewport overflow: long Urdu (Nastaliq) strings at
        // 320px / 1.25x, 360px / 1.35x and 412px / 1.5x.
        await TestHarness.pumpScreenMultiViewport(
          tester: tester,
          screen: screen,
          theme: AppTheme.lightTheme,
          locale: const Locale('ur'),
          localizationsDelegates: delegates,
          supportedLocales: supported,
        );
      });
    }
  });

  group('English locale: LTR + no overflow', () {
    for (final (name, screen) in screens) {
      testWidgets('$name in en', (tester) async {
        final result =
            await pumpLocalized(tester, screen, const Locale('en'));
        expect(result.direction, TextDirection.ltr,
            reason: '$name must stay LTR in the English locale');
      });
    }
  });

  group('Shell nav labels localize', () {
    testWidgets('customer tabs show Urdu labels in ur', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: AppShellNav(
            currentIndex: 0, onTap: (_) {}, items: AppRouter.customerTabs),
        theme: AppTheme.lightTheme,
        locale: const Locale('ur'),
        localizationsDelegates: delegates,
        supportedLocales: supported,
      );
      expect(find.text('ہوم'), findsOneWidget);
      expect(find.text('بکنگز'), findsOneWidget);
      expect(find.text('والیٹ'), findsOneWidget);
      expect(find.text('مدد'), findsOneWidget);
      expect(find.text('پروفائل'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Bookings'), findsNothing);
    });

    testWidgets('owner tabs show Urdu labels in ur', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: AppShellNav(
            currentIndex: 0, onTap: (_) {}, items: AppRouter.ownerTabs),
        theme: AppTheme.lightTheme,
        locale: const Locale('ur'),
        localizationsDelegates: delegates,
        supportedLocales: supported,
      );
      expect(find.text('ڈیش بورڈ'), findsOneWidget);
      expect(find.text('فلیٹ'), findsOneWidget);
      expect(find.text('درخواستیں'), findsOneWidget);
      expect(find.text('گاہک'), findsOneWidget);
      expect(find.text('ترتیبات'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Requests'), findsNothing);
    });
  });

  group('English-scan detector (negative controls)', () {
    test('the detector flags English and passes Urdu + data', () {
      expect(_englishWords('Show balance'), contains('Show'));
      expect(_englishWords('No booking in progress.'),
          containsAll(['booking', 'progress']));
      expect(_englishWords('ہیلو، احمد'), isEmpty);
      expect(_englishWords('KYC تصدیق شدہ'), isEmpty);
      expect(_englishWords('براہ کرم اپنے آلے پر GPS / لوکیشن سروس آن کریں۔'),
          isEmpty);
      expect(_englishWords('Rs. 125000'), isEmpty);
      expect(_englishWords('LEA-21-4820'), isEmpty);
      expect(_englishWords('35202-1234567-1'), isEmpty);
      expect(_englishWords('0300-1234567'), isEmpty);
      expect(_isAddressLike('Gulberg III, Lahore'), isTrue);
      expect(_isAddressLike('Find Verified Rental Shops'), isFalse);
      expect(_isAddressLike('Booking confirmed, thank you!'), isFalse);
    });

    testWidgets('a hardcoded English literal is caught on screen',
        (tester) async {
      // If this test ever goes green while the widget still shows
      // English, the detector is broken — not the screens.
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const Text('Show balance'),
        theme: AppTheme.lightTheme,
        locale: const Locale('ur'),
        localizationsDelegates: delegates,
        supportedLocales: supported,
      );
      final hits = _englishHits(tester);
      expect(hits, isNotEmpty);
      expect(hits.join(' '), contains('Show balance'));
    });
  });
}
