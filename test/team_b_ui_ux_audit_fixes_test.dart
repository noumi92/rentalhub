import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/utils/booking_request_time.dart';
import 'package:rentalhub/features/customer/data/services/customer_home_service.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/customer_vehicle_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/home_kpi_grid.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/home_kyc_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shop_detail_header.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shop_vehicle_card.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_payment_verification_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_vehicle_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_kpis.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_live_notifications.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/dashboard_schedule_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/dashboard/needs_review_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/request_triage_card.dart';
import 'package:rentalhub/features/trust/data/datasources/kyc_remote_data_source.dart';
import 'package:rentalhub/features/trust/data/services/trust_score_service.dart';
import 'package:rentalhub/features/trust/domain/entities/kyc_document_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Team B (UI/UX audit 2026-11-15) fix batch: car cards, discovery,
// dashboard, triage. Pure widget tests — no DI, no live Firebase
// (FakeFirebaseFirestore only for the notifications-live helper).

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

Widget _wrap(Widget child, {Locale locale = const Locale('en'), ThemeData? theme}) {
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

VehicleEntity _vehicle({
  String make = 'Toyota',
  String model = 'Corolla Grande',
  String status = 'available',
  String? outCityMode,
  int? outCityPerKmPkr,
  String? outCityFixedRouteId,
}) {
  return VehicleEntity(
    vehicleId: 'veh-${make}_$model',
    shopId: 'shop-1',
    make: make,
    model: model,
    year: 2022,
    plateNumber: 'LEA-23-4567',
    status: status,
    rates: const VehicleRatesEntity(daily24: 8500),
    outCityMode: outCityMode,
    outCityPerKmPkr: outCityPerKmPkr,
    outCityFixedRouteId: outCityFixedRouteId,
  );
}

BookingEntity _booking({
  String id = 'RH-1',
  String status = 'requested',
  String customerId = 'cust-1',
  DateTime? pickup,
  DateTime? ret,
}) {
  final now = DateTime.now();
  return BookingEntity(
    bookingId: id,
    customerId: customerId,
    shopId: 'shop-1',
    vehicleId: 'veh-1',
    packageType: '24h',
    pickupTime: pickup ?? now.add(const Duration(days: 1)),
    returnTime: ret ?? now.add(const Duration(days: 2)),
    totalAmount: 18000,
    remainingBalance: 13500,
    status: status,
    customerName: 'Ali Raza',
    customerPhone: '03001234567',
    vehicleName: 'Toyota Corolla Grande',
  );
}

ShopEntity _shop({
  String? headerUrl,
  double rating = 4.8,
  bool hasRealRating = true,
  String phoneNumber = '03001234567',
}) {
  return ShopEntity(
    shopId: 'shop-1',
    ownerId: 'owner-1',
    shopName: 'Al-Falah Rent a Car',
    phoneNumber: phoneNumber,
    address: 'Gulberg III',
    city: 'Lahore',
    geoLocation: const GeoPointEntity(31.5, 74.3),
    rating: rating,
    hasRealRating: hasRealRating,
    headerUrl: headerUrl,
  );
}

TrustScoreResult _trustResult() {
  return const TrustScoreResult(
    breakdown: TrustScoreBreakdown(
      base: 2.5,
      kyc: 1.0,
      trips: 0.5,
      ratings: 0.2,
      punctuality: 0,
      conduct: 0,
      total: 4.2,
    ),
    bookings: [],
    completedTrips: 3,
    meanOwnerRating: null,
    kycStatus: 'verified',
  );
}

void main() {
  group('FG-2 customer card image mapping', () {
    testWidgets('Sportage resolves to the generic sedan, never a red Civic',
        (tester) async {
      await tester.pumpWidget(_wrap(CustomerVehicleCard(
        vehicle: _vehicle(make: 'Kia', model: 'Sportage'),
        onTap: () {},
      )));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/white_sedan_hero.png'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/red_civic.png'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('BR-V resolves to the generic sedan', (tester) async {
      await tester.pumpWidget(_wrap(CustomerVehicleCard(
        vehicle: _vehicle(make: 'Honda', model: 'BR-V'),
        onTap: () {},
      )));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/white_sedan_hero.png'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Civic still resolves to its own photo', (tester) async {
      await tester.pumpWidget(_wrap(CustomerVehicleCard(
        vehicle: _vehicle(make: 'Honda', model: 'Civic'),
        onTap: () {},
      )));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/honda_civic_hero.png'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-3 customer card status pill', () {
    testWidgets('pill text per status at 360px EN', (tester) async {
      for (final entry in {
        'available': 'Available',
        'rented': 'Rented Out',
        'maintenance': 'In Maintenance',
      }.entries) {
        await TestHarness.pumpScreenWithOverflowCheck(
          tester: tester,
          screen: DefaultAssetBundle(
            bundle: _TestAssetBundle(),
            child: Scaffold(
              body: CustomerVehicleCard(
                vehicle: _vehicle(status: entry.key),
                onTap: () {},
              ),
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('pill text in Urdu at 360px', (tester) async {
      final ur = await AppLocalizations.delegate.load(const Locale('ur'));
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: Scaffold(
            body: CustomerVehicleCard(
              vehicle: _vehicle(status: 'rented'),
              onTap: () {},
            ),
          ),
        ),
        locale: const Locale('ur'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text(ur.rentedOut), findsOneWidget);
    });

    testWidgets('pill renders in dark mode', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomerVehicleCard(vehicle: _vehicle(status: 'maintenance'), onTap: () {}),
        theme: AppTheme.darkTheme,
      ));
      await tester.pumpAndSettle();
      expect(find.text('In Maintenance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-6 fleet card action labels in Urdu', () {
    testWidgets('all three labels fully visible at 360px Urdu', (tester) async {
      final ur = await AppLocalizations.delegate.load(const Locale('ur'));
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: Scaffold(
            body: FleetVehicleCard(
              vehicle: _vehicle(),
              onEditRates: () {},
              onOutCityRules: () {},
              onEditDetails: () {},
            ),
          ),
        ),
        locale: const Locale('ur'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text(ur.outCityRulesTitle), findsOneWidget);
      expect(find.text(ur.vehicleDetailRatesTitle), findsOneWidget);
      expect(find.text(ur.vehicleDetailEdit), findsOneWidget);
      // Two lines allowed — the Urdu label no longer ellipsizes
      // out of a one-line slot.
      expect(
        tester.widget<Text>(find.text(ur.outCityRulesTitle)).maxLines,
        2,
      );
    });
  });

  group('FG-7 shop card image fills its container', () {
    testWidgets('asset image height is 130', (tester) async {
      await tester.pumpWidget(_wrap(ShopVehicleCard(vehicle: _vehicle())));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is Image && w.height == 130),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-8 fleet card status colours', () {
    Finder chipWith(Color color) => find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == color);

    testWidgets('maintenance is amber, not the rented orange', (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle(status: 'maintenance'),
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(chipWith(AppColors.warningOnContainer), findsOneWidget);
      expect(chipWith(AppColors.orangeFill), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rented stays orange, available stays green', (tester) async {
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle(status: 'rented'),
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(chipWith(AppColors.orangeFill), findsOneWidget);
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle(status: 'available'),
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(chipWith(AppColors.accentSuccessStrong), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PW-20 fleet card out-city chip', () {
    testWidgets('per-km and fixed-route chips show, unset shows none',
        (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle(outCityMode: 'perKm', outCityPerKmPkr: 30),
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text(en.fleetOutCityPerKm), findsOneWidget);
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle(outCityMode: 'fixedRoute', outCityFixedRouteId: 'r1'),
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text(en.fleetOutCityFixedRoute), findsOneWidget);
      await tester.pumpWidget(_wrap(FleetVehicleCard(
        vehicle: _vehicle(),
        onEditRates: () {},
        onOutCityRules: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Out-city:'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-9 fleet card actions is dead', () {
    test('zero references outside its own file', () {
      var references = 0;
      for (final dir in [Directory('lib'), Directory('test')]) {
        for (final file in dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
          if (file.path.endsWith('fleet_card_actions.dart')) continue;
          if (file.path.endsWith('team_b_ui_ux_audit_fixes_test.dart')) {
            continue;
          }
          if (file.readAsStringSync().contains('FleetCardActions')) {
            references++;
          }
        }
      }
      expect(references, 0);
    });
  });

  group('FG-1 dashboard needs-review card', () {
    testWidgets('decision card shows split + oldest wait and taps through',
        (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      var tapped = false;
      await tester.pumpWidget(_wrap(NeedsReviewCard(
        waitingCount: 3,
        newCount: 2,
        proofCount: 1,
        oldestWaitLabel: '6h 12m',
        onTap: () => tapped = true,
      )));
      await tester.pumpAndSettle();
      expect(find.text(en.dashboardNeedsReviewTitle), findsOneWidget);
      expect(
        find.text('3 · ${en.dashboardNeedsReviewSplit(2, 1)}'),
        findsOneWidget,
      );
      expect(
        find.text(en.dashboardOldestWait('6h 12m')),
        findsOneWidget,
      );
      await tester.tap(find.text(en.dashboardNeedsReviewTitle));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('decision card sits above revenue; waiting KPI taps',
        (tester) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      var tapped = false;
      // The real dashboard scrolls; the bare test Scaffold does
      // not, so the KPI column scrolls here too.
      await tester.pumpWidget(_wrap(SingleChildScrollView(
        child: DashboardKpis(
          totalRevenue: 100000,
          growthLabel: '—',
          activeCount: 1,
          completedCount: 2,
          settleLabel: '—',
          waitingCount: 3,
          newCount: 2,
          proofCount: 1,
          oldestWaitLabel: '6h 12m',
          onWaitingTap: () => tapped = true,
          fleetAvailable: 5,
          fleetTotal: 6,
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(NeedsReviewCard), findsOneWidget);
      final cardTop =
          tester.getTopLeft(find.text(en.dashboardNeedsReviewTitle)).dy;
      final kpiTop =
          tester.getTopLeft(find.text(en.dashboardRequestsWaiting)).dy;
      expect(cardTop, lessThan(kpiTop));
      expect(find.text(en.dashboardNeedsReviewSplit(2, 1)), findsOneWidget);
      await tester.tap(find.text(en.dashboardRequestsWaiting));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no decision card when nothing is waiting', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardKpis(
        totalRevenue: 0,
        growthLabel: '—',
        activeCount: 0,
        completedCount: 0,
        settleLabel: '—',
        waitingCount: 0,
        fleetAvailable: 0,
        fleetTotal: 0,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(NeedsReviewCard), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-4 triage wait time and ordering', () {
    test('waitDurationLabel formats minutes, hours and days', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(waitDurationLabel(l10n, const Duration(minutes: 45)), '45m');
      expect(
        waitDurationLabel(l10n, const Duration(hours: 6, minutes: 12)),
        '6h 12m',
      );
      expect(
        waitDurationLabel(l10n, const Duration(days: 2, hours: 3)),
        '2d 3h',
      );
    });

    test('sortByRequestAgeOldestFirst orders oldest first, unknown last',
        () {
      final now = DateTime(2026, 11, 15, 12);
      final a = _booking(id: 'RH-A');
      final b = _booking(id: 'RH-B');
      final c = _booking(id: 'RH-C');
      final d = _booking(id: 'RH-D');
      final times = <String, DateTime?>{
        'RH-A': now.subtract(const Duration(hours: 2)),
        'RH-B': now.subtract(const Duration(hours: 6)),
        'RH-C': now.subtract(const Duration(minutes: 30)),
      };
      final sorted = sortByRequestAgeOldestFirst([a, b, c, d], times);
      expect(
        sorted.map((e) => e.bookingId).toList(),
        ['RH-B', 'RH-A', 'RH-C', 'RH-D'],
      );
      expect(
        oldestWaitFor([a, b, c], times, now: now),
        const Duration(hours: 6),
      );
    });

    testWidgets('card renders Waiting Xh Ym from the request time',
        (tester) async {
      // 6h 12m 30s ago: the 30s slack keeps the truncated minute
      // stable while the fake clock advances during pumping.
      final requestedAt = DateTime.now()
          .subtract(const Duration(hours: 6, minutes: 12, seconds: 30));
      await tester.pumpWidget(_wrap(RequestTriageCard(
        booking: _booking(),
        requestedAt: requestedAt,
        onApprove: () {},
        onReject: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Waiting 6h 12m'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('card shows trust score, KYC badge and prior trips',
        (tester) async {
      await tester.pumpWidget(_wrap(RequestTriageCard(
        booking: _booking(),
        trustScore: 4.2,
        kycStatus: 'verified',
        completedTrips: 3,
        onApprove: () {},
        onReject: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Trust 4.2/5'), findsOneWidget);
      expect(find.text('KYC verified'), findsOneWidget);
      expect(find.text('3 prior trips'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('card renders no wait line without a request time',
        (tester) async {
      await tester.pumpWidget(_wrap(RequestTriageCard(
        booking: _booking(),
        onApprove: () {},
        onReject: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('Waiting'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-22 triage status chip colours', () {
    Finder chipWith(Color color) => find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == color);

    testWidgets('chip colour follows status', (tester) async {
      final lightScheme = AppTheme.lightTheme.colorScheme;
      final cases = {
        'requested': lightScheme.surfaceContainerHighest,
        'payment_submitted':
            AppColors.orangeContainerFor(Brightness.light),
        'approved': AppColors.successContainerFor(Brightness.light),
        'rejected': lightScheme.errorContainer,
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(_wrap(RequestTriageCard(
          booking: _booking(status: entry.key),
          onApprove: () {},
          onReject: () {},
        )));
        await tester.pumpAndSettle();
        expect(chipWith(entry.value), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('FG-10 vehicle detail booking chip label', () {
    testWidgets('payment_submitted renders localised, never raw',
        (tester) async {
      await tester.pumpWidget(_wrap(OwnerVehicleDetailView(
        vehicle: _vehicle(),
        bookings: [_booking(status: 'payment_submitted')],
      )));
      await tester.pumpAndSettle();
      expect(find.text('Proof submitted'), findsOneWidget);
      expect(find.text('payment_submitted'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('PW-18 payment verification risk header', () {
    testWidgets('trust score, KYC status and prior trips render',
        (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentVerificationView(
        booking: _booking(status: 'payment_submitted'),
        trustResult: _trustResult(),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Trust Score: 4.2 / 5.0'), findsOneWidget);
      expect(find.text('KYC status: Verified'), findsOneWidget);
      expect(find.text('3 prior trips'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PW-19 dashboard schedule rows and live badge', () {
    testWidgets('tapping a schedule row opens the booking detail',
        (tester) async {
      final now = DateTime.now();
      final booking = _booking(
        id: 'RH-9',
        pickup: DateTime(now.year, now.month, now.day, 15),
        ret: DateTime(now.year, now.month, now.day + 1, 11),
      );
      Widget stub(String text) => Scaffold(body: Center(child: Text(text)));
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: DashboardScheduleSection(bookings: [booking]),
              ),
            ),
          ),
          GoRoute(
            path: '/owner/requests/:id',
            builder: (context, state) => stub('Booking detail'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ali Raza — Toyota Corolla Grande'));
      await tester.pumpAndSettle();
      expect(find.text('Booking detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('unread badge count follows the notifications stream', () async {
      final fs = FakeFirebaseFirestore();
      Future<void> addNotification({required bool read}) async {
        await fs.collection('notifications').add({
          'shopId': 'shop_1',
          'title': 't',
          'body': 'b',
          'type': 'booking',
          'read': read,
          'createdAt': Timestamp.now(),
        });
      }

      await addNotification(read: false);
      await addNotification(read: false);
      await addNotification(read: true);
      final helper = DashboardLiveNotifications();
      final counts = <int>[];
      final ok = await helper.subscribe(
        shopId: 'shop_1',
        onUnreadCount: counts.add,
        firestore: fs,
      );
      expect(ok, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(counts.last, 2);
      await addNotification(read: false);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(counts.last, 3);
      helper.dispose();
    });
  });

  group('PW-7 shop detail header', () {
    testWidgets('real photo and rating show when real', (tester) async {
      await tester.pumpWidget(_wrap(ShopDetailHeader(
        shop: _shop(headerUrl: 'https://example.com/photo.jpg'),
      )));
      await tester.pumpAndSettle();
      // The real header photo is attempted as a network image (in
      // tests the HTTP request fails, so the error fallback — the
      // placeholder — also renders; in production a working URL
      // renders the photo alone).
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(
        images.any((w) =>
            w.image is NetworkImage &&
            (w.image as NetworkImage).url ==
                'https://example.com/photo.jpg'),
        isTrue,
      );
      expect(find.text('4.8'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no photo shows the generic placeholder; no rating shows nothing', (tester) async {
      await tester.pumpWidget(_wrap(ShopDetailHeader(
        shop: _shop(hasRealRating: false),
      )));
      await tester.pumpAndSettle();
      // Customer pass (2026-11-16): no header photo no longer means
      // no image — the generic showroom placeholder renders instead
      // of the dull grey storefront icon. The rating still shows
      // nothing when none is real.
      final placeholder = find.byType(Image);
      expect(placeholder, findsOneWidget);
      final image = tester.widget<Image>(placeholder).image;
      expect(image, isA<AssetImage>());
      expect((image as AssetImage).assetName,
          'assets/images/showroom_banner_1.jpg');
      expect(find.text('4.8'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('call and WhatsApp are disabled without a phone number',
        (tester) async {
      await tester.pumpWidget(_wrap(ShopDetailHeader(
        shop: _shop(phoneNumber: ''),
      )));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('call and WhatsApp callbacks fire', (tester) async {
      var called = false;
      var messaged = false;
      await tester.pumpWidget(_wrap(ShopDetailHeader(
        shop: _shop(),
        onCall: () => called = true,
        onWhatsApp: () => messaged = true,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Call'));
      await tester.tap(find.text('WhatsApp'));
      expect(called, isTrue);
      expect(messaged, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('PW-1 home title', () {
    test('homeTitle names the dashboard, not discovery', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final ur = await AppLocalizations.delegate.load(const Locale('ur'));
      expect(en.homeTitle, 'Home');
      expect(ur.homeTitle, 'ہوم');
    });
  });

  group('PW-9 signed-out home and DS-16 KYC order', () {
    // Fakes copied from customer_home_rework_test.dart: the rebuilt
    // Home renders from CustomerHomeService with in-memory sources.
    Future<CustomerHomeService> buildService({KycDocumentEntity? kycDoc}) async {
      final bookingsDs = BookingRemoteDataSource();
      final depositsDs = SecurityDepositDataSource();
      return CustomerHomeService(
        bookings: bookingsDs,
        wallet: CustomerWalletService(bookings: bookingsDs, deposits: depositsDs),
        kyc: _FakeKycDataSource(kycDoc),
        users: FirestoreService(),
      );
    }

    const verifiedKyc = KycDocumentEntity(
      userUid: 'cust-101',
      cnicNumber: '35202-1234567-1',
      cnicFrontKey: 'kyc/front',
      cnicBackKey: 'kyc/back',
      licenseKey: 'kyc/license',
      status: 'verified',
    );

    Widget stub(String text) => Scaffold(
          appBar: AppBar(title: Text(text)),
          body: Center(child: Text('$text body')),
        );

    GoRouter buildRouter({CustomerHomeService? service}) {
      return GoRouter(
        initialLocation: '/customer/home',
        routes: [
          GoRoute(
            path: '/customer/home',
            builder: (context, state) =>
                CustomerHomeView(homeService: service),
          ),
          GoRoute(path: '/auth', builder: (context, state) => stub('Login')),
          GoRoute(
              path: '/customer/bookings',
              builder: (context, state) => stub('Bookings')),
          GoRoute(
              path: '/customer/wallet',
              builder: (context, state) => stub('Wallet')),
          GoRoute(
              path: '/customer/reputation',
              builder: (context, state) => stub('Reputation')),
          GoRoute(
              path: '/customer/kyc',
              builder: (context, state) => stub('KYC')),
          GoRoute(
              path: '/customer/shops',
              builder: (context, state) => stub('Shops')),
        ],
      );
    }

    Future<GoRouter> pumpHome(WidgetTester tester, GoRouter router) async {
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('signed-out Home offers Sign in and reaches login',
        (tester) async {
      final router = buildRouter();
      await pumpHome(tester, router);
      expect(find.text('Sign in'), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Login body'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KYC card sits above the KPI grid when it needs action',
        (tester) async {
      final service = await buildService();
      final router = buildRouter(service: service);
      await pumpHome(tester, router);
      final kycTop = tester.getTopLeft(find.byType(HomeKycCard)).dy;
      final kpiTop = tester.getTopLeft(find.byType(HomeKpiGrid)).dy;
      expect(kycTop, lessThan(kpiTop));
      expect(tester.takeException(), isNull);
    });

    testWidgets('KYC card sits below the KPI grid when verified',
        (tester) async {
      final service = await buildService(kycDoc: verifiedKyc);
      final router = buildRouter(service: service);
      await pumpHome(tester, router);
      final kycTop = tester.getTopLeft(find.byType(HomeKycCard)).dy;
      final kpiTop = tester.getTopLeft(find.byType(HomeKpiGrid)).dy;
      expect(kycTop, greaterThan(kpiTop));
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeKycDataSource extends KycRemoteDataSource {
  _FakeKycDataSource(this._doc)
      : super(storageClient: CPanelStorageClient(apiSecretKey: 'test'));

  final KycDocumentEntity? _doc;

  @override
  Future<KycDocumentEntity?> getKyc(String userUid) async => _doc;
}
