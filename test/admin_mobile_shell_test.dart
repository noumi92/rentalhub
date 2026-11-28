import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_pagination.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customer_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customers_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_login_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shop_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shops_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_shell.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_totp_step.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Worker 2 — mobile-first adaptivity for the admin shell, dashboard,
// shops, customers and login/TOTP views: every view renders without
// overflow at a 360dp viewport (1.35x and 2.0x text scales), the
// drawer reaches all 16 sections, and the desktop layout still works.
void main() {
  ShopModel shop(
    String id,
    String name, {
    String city = 'Lahore',
    String status = 'approved',
    bool suspended = false,
  }) {
    return ShopModel(
      shopId: id,
      ownerId: 'owner-$id',
      shopName: name,
      phoneNumber: '03001234567',
      address: 'Main Boulevard, $city',
      city: city,
      geoLocation: const GeoPointEntity(31.5204, 74.3587),
      bankAccounts: const [],
      ownerName: 'Ahmed Raza',
      cnicNumber: '35202-1234567-1',
      verificationStatus: status,
      suspended: suspended,
      rating: 4.8,
    );
  }

  final shopA = shop('shop-1', 'Metro Car Rentals');
  final shopB = shop('shop-2', 'Lahore Motors',
      city: 'Karachi', suspended: true);
  final pendingShop =
      shop('shop-3', 'New Wheels Rent a Car', status: 'pending');

  CustomerModel customer(String id, String name) => CustomerModel(
        customerId: id,
        shopId: 'shop-1',
        name: name,
        phone: '03009876543',
        cnic: '35202-7654321-1',
        createdAt: DateTime(2026, 1, 5),
      );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    // Offline fakes: the real sources return empty lists with no
    // Firestore in tests, which would only exercise empty states.
    sl.unregister<AdminShopsDataSource>();
    sl.registerSingleton<AdminShopsDataSource>(_FakeShopsDataSource(
      shops: [shopA, shopB],
      pending: [pendingShop],
    ));
    sl.unregister<AdminPeopleDataSource>();
    sl.registerSingleton<AdminPeopleDataSource>(_FakePeopleDataSource(
      customers: [customer('c-1', 'Bilal Ahmed'), customer('c-2', 'Sara Khan')],
    ));
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  GoRouter routerFor() {
    Widget placeholder(String title) => AdminShell(
          activeRoute: '/admin/dashboard',
          title: title,
          subtitle: 'Placeholder section',
          child: Center(child: Text(title)),
        );
    return GoRouter(
      initialLocation: RouteNames.adminDashboard,
      routes: [
        GoRoute(
            path: RouteNames.adminDashboard,
            builder: (_, __) => const AdminDashboardView()),
        GoRoute(
            path: RouteNames.adminShops,
            builder: (_, __) => const AdminShopsView()),
        GoRoute(
            path: RouteNames.adminCars,
            builder: (_, __) => placeholder('Cars')),
        GoRoute(
            path: RouteNames.adminCustomers,
            builder: (_, __) => const AdminCustomersView()),
        GoRoute(
            path: RouteNames.adminBookings,
            builder: (_, __) => placeholder('Bookings')),
        GoRoute(
            path: RouteNames.adminDisputes,
            builder: (_, __) => placeholder('Disputes')),
        GoRoute(
            path: RouteNames.adminReviews,
            builder: (_, __) => placeholder('Reviews')),
        GoRoute(
            path: RouteNames.adminTickets,
            builder: (_, __) => placeholder('Support')),
        GoRoute(
            path: RouteNames.adminAnnouncements,
            builder: (_, __) => placeholder('Announcements')),
        GoRoute(
            path: RouteNames.adminReports,
            builder: (_, __) => placeholder('Reports')),
        GoRoute(
            path: RouteNames.adminSettings,
            builder: (_, __) => placeholder('Settings')),
        GoRoute(
            path: RouteNames.adminBlacklist,
            builder: (_, __) => placeholder('Blacklist')),
        GoRoute(
            path: RouteNames.adminTeam,
            builder: (_, __) => placeholder('Admin Team')),
        GoRoute(
            path: RouteNames.adminActivity,
            builder: (_, __) => placeholder('Activity Log')),
        GoRoute(
            path: RouteNames.adminSubscriptions,
            builder: (_, __) => placeholder('Subscriptions')),
      ],
    );
  }

  Future<void> pumpPhone(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.35,
  }) async {
    // Bare widgets (e.g. the TOTP step) need a Material ancestor and
    // a scroll view, as they have inside AdminShell in production.
    final screen = child is AdminTotpStep
        ? Scaffold(body: SingleChildScrollView(child: child))
        : child;
    await TestHarness.pumpScreenWithOverflowCheck(
      tester: tester,
      screen: screen,
      width: 360,
      height: 800,
      textScale: textScale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('admin_mobile shell — drawer navigation at 360dp', () {
    testWidgets('drawer lists all 7 primary sections on a phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp.router(routerConfig: routerFor()));
      await tester.pumpAndSettle();
      // No chip strip any more: the sections live in the drawer.
      expect(find.byType(ChoiceChip), findsNothing);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      for (final label in [
        'Overview',
        'Shops & Fleet',
        'Online Customers',
        'Packages & Credits',
        'Bookings',
        'Trust & Support',
        'Platform & System',
      ]) {
        expect(
          find.descendant(of: find.byType(Drawer), matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      // Bottom nav items remain visible behind the drawer.
      expect(find.text('Shops'), findsOneWidget);
      expect(find.text('Queues'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
    });

    testWidgets('drawer navigation reaches Customers on a phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp.router(routerConfig: routerFor()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      // Restructure (2026-11-27): the drawer item is labelled
      // 'Online Customers' now — tap that, not the bottom-nav
      // 'Customers' (the open drawer covers the nav bar).
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Online Customers'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Sara Khan'), findsOneWidget);
    });

    testWidgets('detail screen keeps a back button and a menu opener',
        (tester) async {
      await pumpPhone(tester, const AdminShopDetailView(shopId: 'shop-1'));
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.text('Metro Car Rentals'), findsOneWidget);
    });
  });

  group('admin_mobile dashboard at 360dp', () {
    testWidgets('renders without overflow at 1.35x', (tester) async {
      await pumpPhone(tester, const AdminDashboardView());
      expect(find.text('Registered shops'), findsOneWidget);
      expect(find.text('Active bookings'), findsOneWidget);
    });

    testWidgets('renders without overflow at 2.0x', (tester) async {
      await pumpPhone(tester, const AdminDashboardView(),
          textScale: 2.0);
      expect(find.text('Open disputes'), findsOneWidget);
      expect(find.text('Open support tickets'), findsOneWidget);
    });
  });

  group('admin_mobile shops at 360dp', () {
    testWidgets('list with rows renders without overflow at 1.35x',
        (tester) async {
      await pumpPhone(tester, const AdminShopsView());
      expect(find.text('Metro Car Rentals'), findsOneWidget);
      expect(find.text('Lahore Motors'), findsOneWidget);
      // Twice: horizontal sub-tab and suspended shop's chip (no duplicate filter chips).
      expect(find.text('Suspended'), findsNWidgets(2));
      // Phase 3 (3.1): no Approvals button any more — pending is a
      // filter on this list, and the decision lives on the detail.
      expect(find.text('Approvals'), findsNothing);
    });

    testWidgets('list renders without overflow at 2.0x', (tester) async {
      await pumpPhone(tester, const AdminShopsView(), textScale: 2.0);
      expect(find.text('Metro Car Rentals'), findsOneWidget);
    });

    testWidgets('desktop keeps the sidebar and the list', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(const AdminShopsView()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('RENTALHUB'), findsOneWidget);
      expect(find.text('Metro Car Rentals'), findsOneWidget);
    });

    testWidgets('detail stacks its actions at 360dp, 2.0x',
        (tester) async {
      await pumpPhone(tester,
          const AdminShopDetailView(shopId: 'shop-1'),
          textScale: 2.0);
      expect(find.text('Message owner'), findsOneWidget);
      expect(find.text('Suspend shop'), findsOneWidget);
      final messageY =
          tester.getCenter(find.text('Message owner')).dy;
      final suspendY =
          tester.getCenter(find.text('Suspend shop')).dy;
      expect(suspendY, greaterThan(messageY + 48));
    });

    testWidgets('detail keeps actions side by side on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          wrap(const AdminShopDetailView(shopId: 'shop-1')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final messageY =
          tester.getCenter(find.text('Message owner')).dy;
      final suspendY =
          tester.getCenter(find.text('Suspend shop')).dy;
      expect(suspendY, closeTo(messageY, 1.0));
    });

    testWidgets('pending filter + review sheet render at 360dp',
        (tester) async {
      // Phase 3 (3.1): Approvals is the Shops list with the Pending
      // filter, and the decision lives on the shop detail route.
      // NOTE: do NOT use the harness helper here — it resets the
      // viewport when it returns, and the sheet opens in the Overlay
      // after that, so it would lay out at the default 800dp width.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // The list navigates to the detail route on tap, so this
      // test needs a GoRouter (unlike the old Approvals screen,
      // which opened its review sheet in place).
      final router = GoRouter(
        initialLocation: RouteNames.adminShops,
        routes: [
          GoRoute(
              path: RouteNames.adminShops,
              builder: (_, __) =>
                  const AdminShopsView(initialFilter: 'pending')),
          GoRoute(
              path: RouteNames.adminShopDetail,
              builder: (_, state) => AdminShopDetailView(
                  shopId: state.pathParameters['shopId']!)),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(find.text('New Wheels Rent a Car'), findsOneWidget);
      expect(find.text('Metro Car Rentals'), findsNothing);
      await tester.tap(find.text('New Wheels Rent a Car'));
      await tester.pumpAndSettle();
      expect(find.text('Review application'), findsOneWidget);
      await tester.tap(find.text('Review application'));
      await tester.pumpAndSettle();
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Ask for more info'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      // Stacked, not side by side: each decision is full-width.
      final approveY = tester.getCenter(find.text('Approve')).dy;
      final rejectY = tester.getCenter(find.text('Reject')).dy;
      expect(rejectY, greaterThan(approveY + 48));
      expect(tester.takeException(), isNull);
    });
  });

  group('admin_mobile customers at 360dp', () {
    testWidgets('list with rows renders without overflow at 1.35x',
        (tester) async {
      await pumpPhone(tester, const AdminCustomersView());
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Sara Khan'), findsOneWidget);
    });

    testWidgets('detail renders without overflow at 2.0x',
        (tester) async {
      await pumpPhone(
        tester,
        AdminCustomerDetailView(
          customerId: 'c-1',
          loadDetail: (_) async => CustomerDetail(
            customer: customer('c-1', 'Bilal Ahmed'),
            storedTrustScore: 3.5,
            isBlacklisted: false,
            kycStatus: 'verified',
            bookings: [
              BookingEntity(
                bookingId: 'b-1',
                customerId: 'c-1',
                shopId: 'shop-1',
                vehicleId: 'v-1',
                packageType: '24h',
                pickupTime: DateTime(2026, 11, 8),
                returnTime: DateTime(2026, 11, 9),
                totalAmount: 9000,
                remainingBalance: 0,
                status: 'completed',
                vehicleName: 'Honda Civic Oriel',
                guarantorName: 'Ali Khan',
                guarantorCnic: '35202-1111111-1',
                guarantorPhone: '03001112233',
              ),
            ],
            completedTrips: 4,
            meanOwnerRating: 4.5,
            trustBreakdown: const TrustScoreBreakdown(
              base: 2.5,
              kyc: 1.0,
              trips: 0.3,
              ratings: 0.4,
              punctuality: 0.1,
              conduct: -1.0,
              total: 3.3,
            ),
            blacklistRecord: null,
            notes: const [],
          ),
          resolveAdminRole: () async => 'support',
        ),
        textScale: 2.0,
      );
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Trust score'), findsOneWidget);
      // Phase 4 (4.4a): the actions live in the sticky bar now,
      // reachable from every tab (the Notes tab keeps the composer).
      // The harness resets the viewport when it returns, so re-apply
      // it before tapping (the approvals-sheet test does the same).
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      // At 2.0x the third tab scrolls out of view — reveal it first.
      await tester.ensureVisible(find.text('Notes & flags'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notes & flags'));
      await tester.pumpAndSettle();
      expect(find.text('Report to blacklist'), findsOneWidget);
      // Stacked actions: the blacklist button sits below watchlist.
      final watchY =
          tester.getCenter(find.text('Add to watchlist')).dy;
      final blacklistY =
          tester.getCenter(find.text('Report to blacklist')).dy;
      expect(blacklistY, greaterThan(watchY + 48));
    });
  });

  group('admin_mobile login and TOTP at 360dp', () {
    testWidgets('login renders without overflow at 2.0x',
        (tester) async {
      await pumpPhone(tester, const AdminLoginView(), textScale: 2.0);
      expect(find.text('RentalHub Admin'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('TOTP enrol step renders without overflow at 2.0x',
        (tester) async {
      final codeController = TextEditingController();
      addTearDown(codeController.dispose);
      await pumpPhone(
        tester,
        AdminTotpStep(
          codeController: codeController,
          isWorking: false,
          error: null,
          onVerify: () {},
          otpauthUrl:
              'otpauth://totp/RentalHub:admin@rentalhub.pk?secret=JBSWY3DPEHPK3PXP&issuer=RentalHub',
        ),
        textScale: 2.0,
      );
      expect(find.text('Set up two-factor authentication'),
          findsOneWidget);
      expect(find.text('Confirm and finish setup'), findsOneWidget);
    });
  });
}

class _FakeShopsDataSource extends AdminShopsDataSource {
  _FakeShopsDataSource({required this.shops, required this.pending});

  final List<ShopModel> shops;
  final List<ShopModel> pending;

  ShopModel _byId(String id) =>
      shops.firstWhere((s) => s.shopId == id, orElse: () => pending
          .firstWhere((s) => s.shopId == id));

  @override
  Future<List<ShopModel>> getShops() async => [...shops, ...pending];

  @override
  Future<List<ShopModel>> getPendingShops() async => pending;

  @override
  Future<ShopModel?> getShop(String shopId) async {
    try {
      return _byId(shopId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> getShopVehicleCount(String shopId) async => 3;

  @override
  Future<int> getShopBookingCount(String shopId) async => 7;

  @override
  Future<bool> decideShopApplication({
    required String shopId,
    required String decision,
    String reason = '',
    String? adminRole,
  }) async =>
      true;

  @override
  Future<bool> setShopSuspended({
    required String shopId,
    required bool suspended,
    required String reason,
    String? adminRole,
  }) async =>
      true;
}

class _FakePeopleDataSource extends AdminPeopleDataSource {
  _FakePeopleDataSource({required this.customers});

  final List<CustomerModel> customers;

  @override
  Future<List<CustomerModel>> getCustomers() async => customers;

  // The customers view pages through getCustomersPage now (F-m2) —
  // the base implementation returns an empty page with no Firestore,
  // so the fake answers with the seeded customers as rows.
  @override
  Future<AdminPage<AdminCustomerRow>> getCustomersPage({
    int limit = 20,
    Object? cursor,
    String cnicFilter = 'all',
    String sort = 'nameAsc',
    bool onlineOnly = true,
  }) async =>
      AdminPage(
        items: AdminPeopleDataSource.sortCustomerRows(
            customers
                .map((c) => AdminCustomerRow(
                      customer: c,
                      storedTrustScore: null,
                      isBlacklisted: false,
                      watchlisted: false,
                    ))
                .toList(),
            sort),
        hasMore: false,
      );
}
