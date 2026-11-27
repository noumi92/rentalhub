import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/data/repositories/platform_settings_repository.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_platform_settings_view.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/review_booking_request_view.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/booking_draft.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/package_tier_list.dart';
import 'package:rentalhub/features/bookings/utils/unverified_shop_gate.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

class _FakePlatformSettings extends PlatformSettingsRepository {
  _FakePlatformSettings({required this.display, required this.allow});

  final bool display;
  final bool allow;

  @override
  Future<bool> displayUnverifiedShops() async => display;

  @override
  Future<bool> allowBookingsFromUnverifiedShops() async => allow;
}

class _ThrowingPlatformSettings extends PlatformSettingsRepository {
  @override
  Future<bool> displayUnverifiedShops() async =>
      throw StateError('settings read failed');

  @override
  Future<bool> allowBookingsFromUnverifiedShops() async =>
      throw StateError('settings read failed');
}

class _FakeAdminSupportDataSource extends AdminSupportDataSource {
  _FakeAdminSupportDataSource({required this.initial});

  final PlatformSettings initial;
  PlatformSettings? saved;

  @override
  Future<PlatformSettings> getPlatformSettings() async => initial;

  @override
  Future<bool> savePlatformSettings(PlatformSettings settings,
      {String? adminRole}) async {
    saved = settings;
    return true;
  }
}

/// Value of the SwitchListTile with the given title label — looked
/// up by label, not by position, so reordering the settings form
/// (Step 4) does not break this test.
bool _switchValue(WidgetTester tester, String label) {
  return tester
      .widget<SwitchListTile>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(SwitchListTile),
        ),
      )
      .value;
}

Map<String, dynamic> _draft({required bool shopIsVerified}) {
  return {
    'carId': 'car-corolla',
    'carName': 'Toyota Corolla Altis',
    'plateNumber': 'ICT-22-101',
    'shopId': 'shop-unverified',
    'shopName': 'Test Motors',
    'isWithDriver': false,
    'packageType': '24h',
    'pickupTime': DateTime.now().add(const Duration(hours: 4)),
    'returnTime': DateTime.now().add(const Duration(days: 1, hours: 4)),
    'totalAmount': 7500,
    'advanceRequired': 1875,
    'shopIsVerified': shopIsVerified,
  };
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    // CU-M12 / CU-m3: the review submit files the request under the
    // signed-in user and refuses a signed-out caller. Widget tests
    // cannot sign a Firebase user in, so stand in as 'cust-101' via
    // the SignedInUser test override.
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDownAll(() {
    SignedInUser.override = null;
  });

  group('PlatformSettings — unverified-shop toggles', () {
    test('both toggles default ON and round-trip', () {
      const settings = PlatformSettings();
      expect(settings.displayUnverifiedShops, isTrue);
      expect(settings.allowBookingsFromUnverifiedShops, isTrue);
      final restored = PlatformSettings.fromMap(settings.toMap());
      expect(restored.displayUnverifiedShops, isTrue);
      expect(restored.allowBookingsFromUnverifiedShops, isTrue);
    });

    test('a missing document/field reads as ON; explicit false survives',
        () {
      final missing = PlatformSettings.fromMap({});
      expect(missing.displayUnverifiedShops, isTrue);
      expect(missing.allowBookingsFromUnverifiedShops, isTrue);
      final off = PlatformSettings.fromMap({
        'displayUnverifiedShops': false,
        'allowBookingsFromUnverifiedShops': false,
      });
      expect(off.displayUnverifiedShops, isFalse);
      expect(off.allowBookingsFromUnverifiedShops, isFalse);
      final restored = PlatformSettings.fromMap(off.toMap());
      expect(restored.displayUnverifiedShops, isFalse);
      expect(restored.allowBookingsFromUnverifiedShops, isFalse);
    });
  });

  group('PlatformSettingsRepository — default-true contract', () {
    test('field parsing: only an explicit false turns a toggle off',
        () {
      expect(PlatformSettingsRepository.displayFromData(null), isTrue);
      expect(PlatformSettingsRepository.displayFromData({}), isTrue);
      expect(
          PlatformSettingsRepository.displayFromData(
              {'displayUnverifiedShops': false}),
          isFalse);
      expect(
          PlatformSettingsRepository.displayFromData(
              {'displayUnverifiedShops': 'no'}),
          isTrue);
      expect(
          PlatformSettingsRepository.allowBookingsFromData(null), isTrue);
      expect(
          PlatformSettingsRepository.allowBookingsFromData({}), isTrue);
      expect(
          PlatformSettingsRepository.allowBookingsFromData(
              {'allowBookingsFromUnverifiedShops': false}),
          isFalse);
    });

    test('no Firestore (missing doc / error) reads as ON, never throws',
        () async {
      const repo = PlatformSettingsRepository();
      expect(await repo.displayUnverifiedShops(), isTrue);
      expect(await repo.allowBookingsFromUnverifiedShops(), isTrue);
    });
  });

  group('shopVerifiedFromData', () {
    test('approved / verified / is_verified true pass; pending fails',
        () {
      expect(shopVerifiedFromData(null), isTrue);
      expect(shopVerifiedFromData({}), isTrue);
      expect(shopVerifiedFromData({'is_verified': true}), isTrue);
      expect(
          shopVerifiedFromData({'verification_status': 'approved'}),
          isTrue);
      expect(
          shopVerifiedFromData({'verification_status': 'verified'}),
          isTrue);
      expect(
          shopVerifiedFromData({'verification_status': 'pending'}),
          isFalse);
      expect(
          shopVerifiedFromData({'verification_status': 'rejected'}),
          isFalse);
      expect(shopVerifiedFromData({'is_verified': false}), isFalse);
    });
  });

  group('UnverifiedShopBookingGate', () {
    test('verified shop books even when the setting is OFF', () async {
      final gate = UnverifiedShopBookingGate(
        settings: _FakePlatformSettings(display: true, allow: false),
        shopVerifiedLookup: (_) async => true,
      );
      expect(
          await gate.isBookingAllowed(
              shopId: 'shop-1', shopIsVerified: true),
          isTrue);
    });

    test('unverified shop books when the setting is ON', () async {
      final gate = UnverifiedShopBookingGate(
        settings: _FakePlatformSettings(display: true, allow: true),
        shopVerifiedLookup: (_) async => false,
      );
      expect(
          await gate.isBookingAllowed(
              shopId: 'shop-1', shopIsVerified: false),
          isTrue);
    });

    test('unverified shop is blocked only when the setting is OFF',
        () async {
      final gate = UnverifiedShopBookingGate(
        settings: _FakePlatformSettings(display: true, allow: false),
        shopVerifiedLookup: (_) async => false,
      );
      expect(
          await gate.isBookingAllowed(
              shopId: 'shop-1', shopIsVerified: false),
          isFalse);
      // The draft flag is honoured; the lookup is the fallback.
      expect(
          await gate.isBookingAllowed(shopId: 'shop-1'), isFalse);
    });

    test('a failing lookup or settings read fails open (never blocks)',
        () async {
      final badLookup = UnverifiedShopBookingGate(
        settings: _FakePlatformSettings(display: true, allow: false),
        shopVerifiedLookup: (_) async => throw StateError('boom'),
      );
      expect(
          await badLookup.isBookingAllowed(shopId: 'shop-1'), isTrue);
      final badSettings = UnverifiedShopBookingGate(
        settings: _ThrowingPlatformSettings(),
        shopVerifiedLookup: (_) async => false,
      );
      expect(
          await badSettings.isBookingAllowed(
              shopId: 'shop-1', shopIsVerified: false),
          isTrue);
    });
  });

  group('BookingRemoteDataSource — unverified-shop backstop', () {
    test('online booking from an unverified shop throws when OFF',
        () async {
      final ds = BookingRemoteDataSource(
        unverifiedShopGate: UnverifiedShopBookingGate(
          settings: _FakePlatformSettings(display: true, allow: false),
          shopVerifiedLookup: (_) async => false,
        ),
      );
      await expectLater(
        ds.createBookingRequest(
          customerId: 'cust-1',
          shopId: 'shop-unverified',
          vehicleId: 'veh-1',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: DateTime.now(),
          returnTime: DateTime.now().add(const Duration(days: 1)),
          totalAmount: 5000,
          advanceRequired: 1000,
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('walk-in bookings are exempt from the gate', () async {
      final ds = BookingRemoteDataSource(
        unverifiedShopGate: UnverifiedShopBookingGate(
          settings: _FakePlatformSettings(display: true, allow: false),
          shopVerifiedLookup: (_) async => false,
        ),
      );
      final booking = await ds.createBookingRequest(
        customerId: 'walkin-1',
        shopId: 'shop-unverified',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 5000,
        advanceRequired: 1000,
      );
      expect(booking.status, 'requested');
    });

    test('no gate wired keeps the old behaviour', () async {
      final ds = BookingRemoteDataSource();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-unverified',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 5000,
        advanceRequired: 1000,
      );
      expect(booking.status, 'requested');
    });
  });

  group('buildBookingDraft carries shopIsVerified', () {
    const tier = PackageTierOption(
      label: '24h',
      hours: 24,
      title: 'Daily 24-Hours',
      subtitle: 'Full day',
      price: 7500,
      kmIncluded: '300 km',
    );

    test('flag is carried when known, omitted when unknown', () {
      final withFlag = buildBookingDraft(
        carId: 'car-1',
        carName: 'Corolla',
        plateNumber: 'ICT-1',
        shopId: 'shop-1',
        shopName: 'Test Motors',
        isWithDriver: false,
        tier: tier,
        kmLimit: 300,
        securityDepositPkr: 10000,
        tripType: 'in_city',
        fixedRouteId: null,
        fixedRouteSummary: null,
        destinationCity: null,
        outCityMode: null,
        outCityPerKmPkr: null,
        pickupDate: DateTime(2026, 11, 12),
        pickupTime: const TimeOfDay(hour: 10, minute: 0),
        durationDays: 1,
        totalAmount: 7500,
        advanceRequired: 1875,
        shopIsVerified: false,
      );
      expect(withFlag['shopIsVerified'], isFalse);
      final withoutFlag = buildBookingDraft(
        carId: 'car-1',
        carName: 'Corolla',
        plateNumber: 'ICT-1',
        shopId: 'shop-1',
        shopName: 'Test Motors',
        isWithDriver: false,
        tier: tier,
        kmLimit: 300,
        securityDepositPkr: 10000,
        tripType: 'in_city',
        fixedRouteId: null,
        fixedRouteSummary: null,
        destinationCity: null,
        outCityMode: null,
        outCityPerKmPkr: null,
        pickupDate: DateTime(2026, 11, 12),
        pickupTime: const TimeOfDay(hour: 10, minute: 0),
        durationDays: 1,
        totalAmount: 7500,
        advanceRequired: 1875,
      );
      expect(withoutFlag.containsKey('shopIsVerified'), isFalse);
    });
  });

  group('ReviewBookingRequestView — unverified-shop gate', () {
    testWidgets('unverified label shows; booking blocked when OFF',
        (tester) async {
      BookingEntity? created;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReviewBookingRequestView(
            bookingDraft: _draft(shopIsVerified: false),
            bookingGate: UnverifiedShopBookingGate(
              settings:
                  _FakePlatformSettings(display: true, allow: false),
              shopVerifiedLookup: (_) async => false,
            ),
            onRequestCreated: (b) => created = b,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unverified'), findsOneWidget);

      await tester.tap(find.text('Send Request to Owner'));
      await tester.pumpAndSettle();

      expect(created, isNull);
      expect(
          find.text(
              'Bookings from unverified shops are currently disabled by the platform.'),
          findsOneWidget);
    });

    testWidgets('unverified shop books when the setting is ON',
        (tester) async {
      BookingEntity? created;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReviewBookingRequestView(
            bookingDraft: _draft(shopIsVerified: false),
            bookingGate: UnverifiedShopBookingGate(
              settings: _FakePlatformSettings(display: true, allow: true),
              shopVerifiedLookup: (_) async => false,
            ),
            onRequestCreated: (b) => created = b,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unverified'), findsOneWidget);

      await tester.tap(find.text('Send Request to Owner'));
      await tester.pumpAndSettle();

      expect(created, isNotNull);
      expect(created!.status, 'requested');
    });

    testWidgets('verified shop shows no Unverified label and books',
        (tester) async {
      BookingEntity? created;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReviewBookingRequestView(
            bookingDraft: _draft(shopIsVerified: true),
            bookingGate: UnverifiedShopBookingGate(
              settings:
                  _FakePlatformSettings(display: true, allow: false),
              shopVerifiedLookup: (_) async => true,
            ),
            onRequestCreated: (b) => created = b,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unverified'), findsNothing);

      await tester.tap(find.text('Send Request to Owner'));
      await tester.pumpAndSettle();

      expect(created, isNotNull);
      expect(created!.status, 'requested');
    });
  });

  group('AdminPlatformSettingsView — unverified-shop toggles', () {
    testWidgets('toggles load OFF and saving persists both ON',
        (tester) async {
      final fake = _FakeAdminSupportDataSource(
        initial: const PlatformSettings(
          displayUnverifiedShops: false,
          allowBookingsFromUnverifiedShops: false,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: AdminPlatformSettingsView(dataSource: fake)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Display unverified shops'), findsOneWidget);
      expect(
          find.text('Allow bookings from unverified shops'),
          findsOneWidget);
      final switches =
          tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.length, 3);
      // The two unverified-shop toggles load OFF (maintenance is
      // untouched by this test).
      expect(_switchValue(tester, 'Display unverified shops'), isFalse);
      expect(
          _switchValue(tester, 'Allow bookings from unverified shops'),
          isFalse);

      await tester.ensureVisible(find.text('Display unverified shops'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Display unverified shops'));
      await tester.ensureVisible(
          find.text('Allow bookings from unverified shops'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow bookings from unverified shops'));
      await tester.pumpAndSettle();
      expect(_switchValue(tester, 'Display unverified shops'), isTrue);
      expect(
          _switchValue(tester, 'Allow bookings from unverified shops'),
          isTrue);
      await tester.ensureVisible(find.text('Save settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();

      expect(fake.saved, isNotNull);
      expect(fake.saved!.displayUnverifiedShops, isTrue);
      expect(fake.saved!.allowBookingsFromUnverifiedShops, isTrue);
      expect(find.text('Platform settings saved.'), findsOneWidget);
    });
  });
}
