import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_pagination.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_platform_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/data/services/admin_queue_counts_service.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dispute_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_disputes_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_queues_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_ticket_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_tickets_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customer_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_team_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_shell.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sidebar_nav.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Phase 2 — admin panel regrouping: grouped sidebar with queue
// badges, phone bottom nav + Queues hub, the 600/840 breakpoint,
// dispute/ticket detail routes, and the tabbed customer detail and
// team views.
void main() {
  const counts = AdminQueueCounts(
    approvals: 3,
    kyc: 2,
    cars: 0,
    disputes: 5,
    reviews: 1,
    tickets: 0,
  );

  final dispute = DisputeRecord(
    id: 'DSP-1',
    bookingId: 'RH-123',
    category: 'Damage claim',
    description: 'The shop charged me for damage I did not cause.',
    status: 'open',
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    shopId: 'shop-1',
    customerName: 'Ahmed Raza',
    customerId: 'customer-1',
  );

  final ticket = SupportTicket(
    id: 'T-1',
    customerId: 'customer-1',
    message: 'The showroom charged me extra for fuel.',
    status: 'open',
    priority: 'high',
    createdAt: DateTime.now(),
  );

  CustomerModel customer(String id, String name) => CustomerModel(
        customerId: id,
        shopId: 'shop-1',
        name: name,
        phone: '03009876543',
        cnic: '35202-7654321-1',
        createdAt: DateTime(2026, 1, 5),
      );

  CustomerDetail detailFor(String id, String name) => CustomerDetail(
        customer: customer(id, name),
        storedTrustScore: 3.5,
        isBlacklisted: false,
        kycStatus: 'verified',
        bookings: [
          BookingEntity(
            bookingId: 'b-1',
            customerId: id,
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
      );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    sl.unregister<AdminPlatformDataSource>();
    sl.registerSingleton<AdminPlatformDataSource>(
        _FakePlatformDataSource(disputes: [dispute]));
    sl.unregister<AdminSupportDataSource>();
    sl.registerSingleton<AdminSupportDataSource>(
        _FakeSupportDataSource(tickets: [ticket]));
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  Future<void> pumpSidebar(
    WidgetTester tester, {
    Future<AdminQueueCounts> Function()? loadCounts,
    bool? showKycReview,
    bool? showApkDownload,
  }) async {
    await tester.pumpWidget(wrap(Scaffold(
        body: AdminSidebarNav(
      activeRoute: RouteNames.adminDashboard,
      onNavigate: (_) {},
      loadCounts: loadCounts,
      showKycReview: showKycReview,
      showApkDownload: showApkDownload,
    ))));
    await tester.pumpAndSettle();
  }

  group('2.1 — streamlined 7-section sidebar with queue badges', () {
    testWidgets('shows the seven primary sections in order', (tester) async {
      await pumpSidebar(tester,
          loadCounts: () async => counts,
          showKycReview: true,
          showApkDownload: true);
      final labels = [
        'Overview',
        'Shops & Fleet',
        'Online Customers',
        'Packages & Credits',
        'Disputes & Reviews',
        'Trust & Support',
        'Platform & System',
      ];
      double? prevY;
      for (final label in labels) {
        expect(find.text(label), findsOneWidget, reason: label);
        final y = tester.getCenter(find.text(label)).dy;
        if (prevY != null) {
          expect(y, greaterThan(prevY), reason: '$label below previous');
        }
        prevY = y;
      }
      expect(find.text('Approvals'), findsNothing);
      expect(find.text('Customers'), findsNothing);
    });

    testWidgets('badges show combined live counts, hidden at zero',
        (tester) async {
      await pumpSidebar(tester,
          loadCounts: () async => counts,
          showKycReview: true,
          showApkDownload: true);
      expect(find.text('3'), findsOneWidget); // Shops & Fleet (approvals 3 + cars 0)
      expect(find.text('2'), findsOneWidget); // Online Customers (KYC 2)
      expect(find.text('6'), findsOneWidget); // Bookings (disputes 5 + reviews 1)
      // Packages & Support are zero — no badge, so no bare '0'.
      expect(find.text('0'), findsNothing);
    });

    testWidgets('KYC badge stays hidden without the decideKyc role',
        (tester) async {
      await pumpSidebar(tester,
          loadCounts: () async => counts,
          showKycReview: false,
          showApkDownload: false);
      expect(find.text('2'), findsNothing); // KYC badge hidden
      expect(find.text('Online Customers'), findsOneWidget);
      expect(find.text('Approvals'), findsNothing);
    });
  });

  group('2.1 — queue counts service', () {
    test('composes platform stats, car reviews and review signals',
        () async {
      final service = AdminQueueCountsService(
        remote: _FakeRemoteDataSource(),
        shops: _FakeShopsDataSource(),
        platform: _FakePlatformCountsDataSource(),
      );
      final got = await service.getCounts();
      expect(got.approvals, 3);
      expect(got.kyc, 2);
      expect(got.disputes, 4);
      expect(got.tickets, 7);
      // Two cars: one approved, one pending (no review doc).
      expect(got.cars, 1);
      // Three reviews: one flagged + visible, one flagged + hidden,
      // one with no signals.
      expect(got.reviews, 1);
    });

    test('caches for 60s — a second call does not re-read', () async {
      final remote = _FakeRemoteDataSource();
      final service = AdminQueueCountsService(
        remote: remote,
        shops: _FakeShopsDataSource(),
        platform: _FakePlatformCountsDataSource(),
      );
      await service.getCounts();
      await service.getCounts();
      expect(remote.statsCalls, 1);
    });
  });

  group('2.2 — Queues hub', () {
    Future<void> pumpPhone(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(Scaffold(body: child)));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the six queues with live counts', (tester) async {
      await pumpPhone(
          tester,
          AdminQueuesView(
            loadCounts: () async => counts,
            showKycReview: true,
          ));
      await tester.pumpAndSettle();
      for (final label in [
        'Approvals',
        'KYC Review',
        'Cars',
        'Disputes',
        'Reviews',
        'Support',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('3 open'), findsOneWidget);
      expect(find.text('2 open'), findsOneWidget);
      expect(find.text('0 open'), findsNWidgets(2)); // Cars, Support
      expect(find.text('5 open'), findsOneWidget);
      expect(find.text('1 open'), findsOneWidget);
    });

    testWidgets('hides the KYC row without the decideKyc role',
        (tester) async {
      await pumpPhone(
          tester,
          AdminQueuesView(
            loadCounts: () async => counts,
            showKycReview: false,
          ));
      expect(find.text('KYC Review'), findsNothing);
      expect(find.text('Approvals'), findsOneWidget);
    });

    testWidgets('tapping a queue row opens its screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: RouteNames.adminQueues,
        routes: [
          GoRoute(
              path: RouteNames.adminQueues,
              builder: (_, __) => AdminQueuesView(
                    loadCounts: () async => counts,
                    showKycReview: false,
                  )),
          GoRoute(
              path: RouteNames.adminDisputes,
              builder: (_, __) =>
                  const Scaffold(body: Text('Disputes centre'))),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disputes'));
      await tester.pumpAndSettle();
      expect(find.text('Disputes centre'), findsOneWidget);
    });
  });

  group('2.2/2.3 — shell breakpoint and phone bottom nav', () {
    Future<void> pumpShell(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(const AdminShell(
        activeRoute: RouteNames.adminDashboard,
        title: 'Dashboard',
        subtitle: 'Subtitle',
        child: Text('Body'),
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('850dp (medium) keeps the sidebar, no bottom nav',
        (tester) async {
      await pumpShell(tester, 850);
      expect(find.text('RENTALHUB'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('360dp shows the bottom nav, not the sidebar',
        (tester) async {
      await pumpShell(tester, 360);
      expect(find.text('RENTALHUB'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      for (final label in ['Home', 'Queues', 'Shops', 'Customers', 'More']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // Restructure (2026-11-27): Bookings left the bottom nav for
      // Customers — it stays reachable via the drawer/sidebar.
      expect(find.text('Bookings'), findsNothing);
    });

    testWidgets('bottom nav Queues opens the hub', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: RouteNames.adminDashboard,
        routes: [
          GoRoute(
              path: RouteNames.adminDashboard,
              builder: (_, __) => const AdminShell(
                    activeRoute: RouteNames.adminDashboard,
                    title: 'Dashboard',
                    subtitle: 'Subtitle',
                    child: Text('Dashboard body'),
                  )),
          GoRoute(
              path: RouteNames.adminQueues,
              builder: (_, __) => AdminQueuesView(
                    loadCounts: () async => counts,
                    showKycReview: false,
                  )),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Queues'));
      await tester.pumpAndSettle();
      expect(find.text('Review queues'), findsWidgets);
      expect(find.text('Approvals'), findsOneWidget);
    });
  });

  group('2.4 — dispute and ticket detail routes', () {
    testWidgets('tapping a dispute row opens its detail route',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.adminDisputes,
        routes: [
          GoRoute(
              path: RouteNames.adminDisputes,
              builder: (_, __) => const AdminDisputesView()),
          GoRoute(
              path: RouteNames.adminDisputeDetail,
              builder: (_, state) => AdminDisputeDetailView(
                    disputeId: state.pathParameters['disputeId'] ?? '',
                  )),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Damage claim'), findsOneWidget);
      await tester.tap(find.textContaining('Damage claim'));
      await tester.pumpAndSettle();
      // The detail route, not a sheet: the decision form is on the
      // route, with a back button to the centre.
      expect(find.text('Dispute DSP-1'), findsWidgets);
      expect(find.textContaining('Customer statement'), findsOneWidget);
      expect(find.text('Save decision'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('tapping a ticket opens its detail route', (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.adminTickets,
        routes: [
          GoRoute(
              path: RouteNames.adminTickets,
              builder: (_, __) => const AdminTicketsView()),
          GoRoute(
              path: RouteNames.adminTicketDetail,
              builder: (_, state) => AdminTicketDetailView(
                    ticketId: state.pathParameters['ticketId'] ?? '',
                  )),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(
          find.text('The showroom charged me extra for fuel.'),
          findsOneWidget);
      await tester
          .tap(find.text('The showroom charged me extra for fuel.'));
      await tester.pumpAndSettle();
      expect(find.text('Ticket T-1'), findsWidgets);
      expect(find.text('Send reply'), findsOneWidget);
      expect(find.text('Close ticket'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
    });

    testWidgets('dispute detail shows the not-found state', (tester) async {
      await tester.pumpWidget(wrap(AdminDisputeDetailView(
        disputeId: 'no-such-dispute',
        loadDispute: (_) async => null,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Dispute not found.'), findsOneWidget);
    });

    testWidgets('ticket detail shows the not-found state', (tester) async {
      await tester.pumpWidget(wrap(AdminTicketDetailView(
        ticketId: 'no-such-ticket',
        loadTicket: (_) async => null,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Ticket not found.'), findsOneWidget);
    });

    testWidgets('resolved dispute detail is read-only', (tester) async {
      final resolved = DisputeRecord(
        id: 'DSP-2',
        bookingId: 'RH-124',
        category: 'Damage claim',
        description: 'Decided already.',
        status: 'resolved',
        createdAt: DateTime.now().subtract(const Duration(hours: 50)),
        decision: 'partial',
        decisionAmount: 4000,
        adminNote: 'Split the cost.',
      );
      await tester.pumpWidget(wrap(AdminDisputeDetailView(
        disputeId: 'DSP-2',
        loadDispute: (_) async => resolved,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Dispute DSP-2'), findsWidgets);
      expect(find.text('Save decision'), findsNothing);
    });
  });

  group('2.5 — tabbed customer detail', () {
    testWidgets('Profile tab first, Notes reachable (Bookings tab removed)',
        (tester) async {
      await tester.pumpWidget(wrap(AdminCustomerDetailView(
        customerId: 'c-1',
        loadDetail: (_) async => detailFor('c-1', 'Bilal Ahmed'),
        resolveAdminRole: () async => 'support',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Trust score'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bookings'), findsNothing);
      await tester.tap(find.text('Notes & flags'));
      await tester.pumpAndSettle();
      expect(find.text('Add note'), findsOneWidget);
      expect(find.text('Add to watchlist'), findsOneWidget);
      expect(find.text('Report to blacklist'), findsOneWidget);
    });

    testWidgets('Step 3 — Profile tab KYC entry point is decideKyc-gated',
        (tester) async {
      await tester.pumpWidget(wrap(AdminCustomerDetailView(
        key: const ValueKey('step3-super-admin'),
        customerId: 'c-1',
        loadDetail: (_) async => detailFor('c-1', 'Bilal Ahmed'),
        resolveAdminRole: () async => 'super_admin',
      )));
      await tester.pumpAndSettle();
      expect(find.text('View KYC documents'), findsOneWidget);
      await tester.pumpWidget(wrap(AdminCustomerDetailView(
        key: const ValueKey('step3-support'),
        customerId: 'c-1',
        loadDetail: (_) async => detailFor('c-1', 'Bilal Ahmed'),
        resolveAdminRole: () async => 'support',
      )));
      await tester.pumpAndSettle();
      expect(find.text('View KYC documents'), findsNothing);
      expect(find.widgetWithText(Tab, 'Profile'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bookings'), findsNothing);
      expect(find.widgetWithText(Tab, 'Notes & flags'), findsOneWidget);
    });
  });

  group('2.5 — tabbed team view', () {
    testWidgets('Members first, Invites and Security reachable',
        (tester) async {
      await tester.pumpWidget(
          wrap(const AdminTeamView(adminRole: 'super_admin')));
      await tester.pumpAndSettle();
      expect(find.text('Team members'), findsOneWidget);
      // The invite form is not on the Members tab any more.
      expect(find.text('Save invite'), findsNothing);
      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();
      expect(find.text('Pending invites'), findsOneWidget);
      expect(find.text('Invite an admin'), findsOneWidget);
      expect(find.text('Save invite'), findsOneWidget);
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      expect(find.text('Two-factor authentication'), findsOneWidget);
    });

    testWidgets('Security tab lists the 2FA-off members', (tester) async {
      await tester.pumpWidget(
          wrap(const AdminTeamView(adminRole: 'super_admin')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      // No members in the test backend — the all-on state, not a
      // crash or an empty tab.
      expect(
          find.text('Every admin has two-factor authentication on.'),
          findsOneWidget);
    });
  });
}

class _FakeRemoteDataSource extends AdminRemoteDataSource {
  int statsCalls = 0;

  @override
  Future<PlatformStats> getPlatformStats() async {
    statsCalls++;
    return const PlatformStats(
      shopCount: 1,
      activeBookingCount: 2,
      openDisputeCount: 4,
      openTicketCount: 7,
      pendingShopCount: 3,
      pendingKycCount: 2,
    );
  }
}

class _FakeShopsDataSource extends AdminShopsDataSource {
  VehicleEntity _car(String id) => VehicleEntity(
        vehicleId: id,
        shopId: 'shop-1',
        make: 'Honda',
        model: 'Civic',
        year: 2022,
        plateNumber: 'LEA-22-$id',
        rates: const VehicleRatesEntity(daily24: 5000),
      );

  @override
  Future<List<VehicleEntity>> getCars() async =>
      [_car('v-1'), _car('v-2')];

  @override
  Future<Map<String, CarReview>> getCarReviews() async => {
        'v-1': const CarReview(
            vehicleId: 'v-1', status: 'approved', reason: ''),
      };
}

class _FakePlatformCountsDataSource extends AdminPlatformDataSource {
  AdminReview _review(String id,
          {required List<String> signals, String status = 'visible'}) =>
      AdminReview(
        id: id,
        bookingId: 'b-1',
        shopId: 'shop-1',
        customerId: 'c-1',
        customerName: 'Bilal Ahmed',
        vehicleName: 'Honda Civic',
        shopRating: 1,
        vehicleRating: 1,
        customerComment: '',
        ownerPunctuality: 5,
        ownerCare: 5,
        ownerBehavior: 5,
        ownerComment: '',
        moderationStatus: status,
        moderationReason: '',
        signals: signals,
      );

  @override
  Future<List<AdminReview>> getReviews() async => [
        _review('r-1', signals: ['Fake review: 1-star with no comment']),
        _review('r-2',
            signals: ['Abusive / fake wording'], status: 'hidden'),
        _review('r-3', signals: []),
      ];
}

class _FakePlatformDataSource extends AdminPlatformDataSource {
  _FakePlatformDataSource({required this.disputes});

  final List<DisputeRecord> disputes;

  @override
  Future<List<DisputeRecord>> getDisputes({String status = 'all'}) async =>
      status == 'all'
          ? disputes
          : disputes.where((d) => d.status == status).toList();

  @override
  Future<DisputeRecord?> getDispute(String disputeId) async {
    try {
      return disputes.firstWhere((d) => d.id == disputeId);
    } catch (_) {
      return null;
    }
  }
}

class _FakeSupportDataSource extends AdminSupportDataSource {
  _FakeSupportDataSource({required this.tickets});

  final List<SupportTicket> tickets;

  @override
  Future<AdminPage<SupportTicket>> getTicketsPage({
    String status = 'all',
    int limit = 50,
    Object? cursor,
    String sort = 'dateNewest',
  }) async =>
      AdminPage(
        items: AdminSupportDataSource.sortTickets(
            status == 'all'
                ? tickets
                : tickets.where((t) => t.status == status).toList(),
            sort),
        hasMore: false,
      );

  @override
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      return tickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TicketMessage>> getTicketReplies(String ticketId) async => [];

  @override
  Future<List<TicketMessage>> getTicketNotes(String ticketId) async => [];
}
