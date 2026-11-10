import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_cars_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shop_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shops_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_desktop_header.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_shell.dart';
import 'package:rentalhub/features/customer/presentation/widgets/blacklist_appeal_sheet.dart';
import 'package:rentalhub/features/customer/presentation/widgets/profile_trust_card.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/notifications/presentation/views/announcement_detail_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Admin final pass (2026-11-10): the seven leftovers — rating honesty
// in the admin shop views, the blacklist appeal entry point, the
// announcement detail route, the admin cars audit, the stale
// dashboard copy, and the desktop header title at 2.0x.
void main() {
  ShopModel shopFromMap(String id, String name, Map<String, dynamic> data) =>
      ShopModel.fromMap({'shop_name': name, ...data}, id: id);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    sl.unregister<AdminShopsDataSource>();
    sl.registerSingleton<AdminShopsDataSource>(_FakeShopsDataSource(
      shops: [
        shopFromMap('shop-1', 'Metro Car Rentals', {
          'city': 'Lahore',
          'plan': 'pro',
          'rating': 4.2,
          'phone_number': '03001234567',
          'address': 'Main Boulevard',
          'verification_status': 'approved',
        }),
        shopFromMap('shop-2', 'No Ratings Motors', {
          'city': 'Karachi',
          'plan': 'free',
          'phone_number': '03007654321',
          'address': 'Clifton Block 4',
          'verification_status': 'approved',
        }),
      ],
    ));
  });

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    double width = 360,
    double height = 800,
    double textScale = 1.0,
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
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('item 1 — admin rating honesty', () {
    testWidgets('shops list shows a stored rating, hides an unstored one',
        (tester) async {
      await pumpAt(tester, const AdminShopsView());
      expect(find.text('Lahore • Plan pro • Rating 4.2'), findsOneWidget);
      expect(find.text('Karachi • Plan free'), findsOneWidget);
      // The display-only fallback 4.9 must never appear.
      expect(find.textContaining('4.9'), findsNothing);
      expect(find.text('No Ratings Motors'), findsOneWidget);
    });

    testWidgets('shop detail shows the stored rating', (tester) async {
      await pumpAt(
          tester, const AdminShopDetailView(shopId: 'shop-1'));
      expect(find.text('4.2'), findsOneWidget);
    });

    testWidgets('shop detail shows — when no rating is stored',
        (tester) async {
      await pumpAt(
          tester, const AdminShopDetailView(shopId: 'shop-2'));
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('4.9'), findsNothing);
    });
  });

  group('item 2 — blacklist appeal entry point', () {
    testWidgets('appeal sheet renders and files the appeal',
        (tester) async {
      String? capturedReason;
      // Pumped the way production opens it — a modal sheet over a
      // Scaffold — so the success pop closes the sheet and the
      // confirmation lands on the page behind it.
      await pumpAt(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showBlacklistAppealSheet(
                  context,
                  blacklistId: 'BLK-1',
                  onSubmit: (reason) async {
                    capturedReason = reason;
                    return true;
                  },
                ),
                child: const Text('Open appeal'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open appeal'));
      await tester.pumpAndSettle();
      expect(find.text('Appeal blacklist listing'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(
          find.byType(TextField), 'Wrong CNIC — this is not me.');
      await tester.tap(find.text('Submit appeal'));
      await tester.pumpAndSettle();
      expect(capturedReason, 'Wrong CNIC — this is not me.');
      expect(find.byType(BlacklistAppealSheet), findsNothing);
      expect(
          find.text('Appeal submitted. The tribunal will review it.'),
          findsOneWidget);
    });

    testWidgets('empty reason is refused and nothing is filed',
        (tester) async {
      var submitted = false;
      await pumpAt(
        tester,
        Scaffold(
          body: BlacklistAppealSheet(
            blacklistId: 'BLK-1',
            onSubmit: (_) async {
              submitted = true;
              return true;
            },
          ),
        ),
      );
      await tester.tap(find.text('Submit appeal'));
      await tester.pumpAndSettle();
      expect(submitted, isFalse);
      expect(find.text('Please write a reason for your appeal.'),
          findsOneWidget);
    });

    testWidgets('trust card shows the appeal action only when offered',
        (tester) async {
      await pumpAt(
        tester,
        const Scaffold(
          body: ProfileTrustCard(
            trustScore: 3.5,
            kycVerified: true,
            isBlacklisted: true,
            onAppeal: null,
          ),
        ),
      );
      expect(find.text('Appeal blacklist decision'), findsNothing);
      await pumpAt(
        tester,
        Scaffold(
          body: ProfileTrustCard(
            trustScore: 3.5,
            kycVerified: true,
            isBlacklisted: true,
            onAppeal: () {},
          ),
        ),
      );
      expect(find.text('Appeal blacklist decision'), findsOneWidget);
    });
  });

  group('item 3 — announcement detail route', () {
    test('the push id resolves to the detail path', () {
      expect(
        RouteNames.customerAnnouncement.replaceFirst(':id', 'ann-1'),
        '/customer/announcement/ann-1',
      );
    });

    Future<void> pumpAnnouncement(
      WidgetTester tester,
      Future<Map<String, dynamic>?> Function(String id) loader,
    ) async {
      final router = GoRouter(
        initialLocation: '/customer/announcement/ann-1',
        routes: [
          GoRoute(
            path: RouteNames.customerAnnouncement,
            builder: (context, state) => AnnouncementDetailView(
              announcementId: state.pathParameters['id']!,
              loader: loader,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the route renders the announcement', (tester) async {
      await pumpAnnouncement(tester, (_) async => {
            'title_en': 'Eid offer',
            'body_en': 'All cars 20% off this weekend.',
            'created_at': '2026-11-09T10:00:00Z',
          });
      expect(find.text('Eid offer'), findsOneWidget);
      expect(find.text('All cars 20% off this weekend.'), findsOneWidget);
    });

    testWidgets('a missing announcement is an honest empty state',
        (tester) async {
      await pumpAnnouncement(tester, (_) async => null);
      expect(find.text('This announcement is no longer available.'),
          findsOneWidget);
    });

    testWidgets('a failed read is an honest error state',
        (tester) async {
      await pumpAnnouncement(tester, (_) async => throw Exception('no net'));
      expect(find.text('Could not load the announcement. Please try again.'),
          findsOneWidget);
    });
  });

  group('item 4 — admin cars view at 360px', () {
    for (final scale in [1.0, 1.35, 2.0]) {
      testWidgets('cars view 360dp @ ${scale}x', (tester) async {
        await pumpAt(tester, const AdminCarsView(),
            width: 360, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Toyota Corolla'), findsOneWidget);
        // The list is lazy: at larger scales the second car starts
        // below the fold, so scroll it into view before asserting.
        await tester.scrollUntilVisible(
          find.textContaining('Honda Civic'),
          200,
          scrollable: find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Honda Civic'), findsOneWidget);
      });
    }

    testWidgets('cars view desktop 1280dp', (tester) async {
      await pumpAt(tester, const AdminCarsView(), width: 1280);
      expect(tester.takeException(), isNull);
    });
  });

  group('item 5 — dashboard copy', () {
    testWidgets('disputes/tickets cards point at the real screens',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.adminDashboard,
        routes: [
          GoRoute(
            path: RouteNames.adminDashboard,
            builder: (_, __) => const AdminDashboardView(),
          ),
          GoRoute(
            path: RouteNames.adminDisputes,
            builder: (_, __) =>
                const Scaffold(body: Text('Disputes centre')),
          ),
          GoRoute(
            path: RouteNames.adminTickets,
            builder: (_, __) =>
                const Scaffold(body: Text('Tickets inbox')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Open the disputes centre to decide them.'),
          findsOneWidget);
      expect(find.textContaining('Open the tickets inbox to reply.'),
          findsOneWidget);
      expect(find.textContaining('arrives in Phase'), findsNothing);
      await tester.tap(find.text('Open disputes need a decision'));
      await tester.pumpAndSettle();
      expect(find.text('Disputes centre'), findsOneWidget);
    });
  });

  group('item 7 — header titles', () {
    testWidgets('desktop header, longest title, 900dp @ 2.0x',
        (tester) async {
      await pumpAt(
        tester,
        const Scaffold(
          body: AdminDesktopHeader(
            title: 'National Rental Fraud & Blacklist Tribunal',
            subtitle: 'Central arbitration bench for inter-showroom disputes',
          ),
        ),
        width: 900,
        height: 800,
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact AppBar, full tribunal title, 360dp @ 2.0x',
        (tester) async {
      await pumpAt(
        tester,
        const AdminShell(
          activeRoute: '/admin/blacklist',
          title: 'National Rental Fraud & Blacklist Tribunal',
          subtitle: 'Central arbitration bench',
          child: Center(child: Text('body')),
        ),
        width: 360,
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeShopsDataSource extends AdminShopsDataSource {
  _FakeShopsDataSource({required this.shops});

  final List<ShopModel> shops;

  @override
  Future<List<ShopModel>> getShops() async => shops;

  @override
  Future<ShopModel?> getShop(String shopId) async {
    for (final shop in shops) {
      if (shop.shopId == shopId) return shop;
    }
    return null;
  }

  @override
  Future<int> getShopVehicleCount(String shopId) async => 3;

  @override
  Future<int> getShopBookingCount(String shopId) async => 7;

  @override
  Future<List<VehicleEntity>> getCars() async => const [
        VehicleEntity(
          vehicleId: 'v-1',
          shopId: 'shop-1',
          make: 'Toyota',
          model: 'Corolla Grande CVT-i',
          year: 2023,
          plateNumber: 'LEA-23-1234',
          rates: VehicleRatesEntity(daily24: 8500),
          status: 'available',
        ),
        VehicleEntity(
          vehicleId: 'v-2',
          shopId: 'shop-1',
          make: 'Honda',
          model: 'Civic RS Turbo',
          year: 2024,
          plateNumber: 'LHR-24-9876',
          rates: VehicleRatesEntity(daily24: 12000),
          status: 'rented',
        ),
      ];

  @override
  Future<Map<String, CarReview>> getCarReviews() async => const {
        'v-1': CarReview(vehicleId: 'v-1', status: 'approved', reason: ''),
        'v-2': CarReview(vehicleId: 'v-2', status: 'pending', reason: ''),
      };
}
