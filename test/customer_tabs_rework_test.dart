import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/app_shell.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/widgets/customer_support_badge.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/home_app_bar.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Customer rework (Worker A): the customer tabs are now Home, Shops,
// Bookings, Wallet, Profile. Support is no longer a tab — it is a
// top-level sub-screen (path/name unchanged) reached from Profile
// and from the home hero bell, with its unread badge on the Profile
// Support row. Owner tabs are unchanged.

List<RouteBase> _allRoutes(RouteBase route) {
  if (route is StatefulShellRoute) {
    return [
      for (final branch in route.branches)
        for (final r in branch.routes) ..._allRoutes(r),
    ];
  }
  if (route is GoRoute) {
    return [route, for (final r in route.routes) ..._allRoutes(r)];
  }
  return [route];
}

List<StatefulShellBranch> _allBranches() {
  return [
    for (final route in AppRouter.router.configuration.routes)
      if (route is StatefulShellRoute) ...route.branches,
  ];
}

void main() {
  group('customer tabs rework: tab order', () {
    test('customer tabs are Home, Shops, Bookings, Wallet, Profile', () {
      expect(AppRouter.customerTabs.length, 5);
      expect(AppRouter.customerTabs.map((t) => t.label).toList(), [
        'Home',
        'Shops',
        'Bookings',
        'Wallet',
        'Profile',
      ]);
      // Audit SH-N15: the leftover numbering artefact 'tab2_navShops'
      // was normalised to 'navShops' like every other tab key.
      expect(AppRouter.customerTabs[1].l10nKey, 'navShops');
      expect(
        AppRouter.customerTabs.map((t) => t.label),
        isNot(contains('Support')),
      );
    });

    test('owner tabs are unchanged', () {
      expect(AppRouter.ownerTabs.map((t) => t.label).toList(), [
        'Dashboard',
        'Fleet',
        'Bookings',
        'Customers',
        'Settings',
      ]);
    });

    test('tabRootPaths has the Shops root, not Support; still 10 roots',
        () {
      expect(AppShell.tabRootPaths.length, 10);
      expect(AppShell.tabRootPaths, contains(RouteNames.customerShops));
      expect(AppShell.tabRootPaths, contains('/customer/shops'));
      expect(AppShell.tabRootPaths, isNot(contains('/customer/support')));
      expect(AppShell.tabRootPaths, containsAll([
        '/customer/home',
        '/customer/bookings',
        '/customer/wallet',
        '/customer/profile',
        '/owner/dashboard',
        '/owner/fleet',
        '/owner/requests',
        '/owner/customers',
        '/owner/settings',
      ]));
    });

    test('Shops is a shell branch root; Support is top-level only', () {
      final branches = _allBranches();
      expect(branches.length, 10);
      final branchFirstPaths = [
        for (final b in branches) (b.routes.first as GoRoute).path,
      ];
      expect(branchFirstPaths, contains('/customer/shops'));
      expect(branchFirstPaths, isNot(contains('/customer/support')));

      // Support / SOS / Disputes exist as top-level routes (outside
      // any StatefulShellRoute), so they render with no tab bar.
      final topLevelPaths = [
        for (final r in AppRouter.router.configuration.routes)
          if (r is GoRoute) r.path,
      ];
      expect(topLevelPaths, contains('/customer/support'));
      expect(topLevelPaths, contains('/customer/sos'));
      expect(topLevelPaths, contains('/customer/disputes'));
      final branchPaths = [
        for (final route in AppRouter.router.configuration.routes)
          for (final r in _allRoutes(route))
            if (r is GoRoute) r.path,
      ];
      // The paths are reachable through the top-level routes, not
      // through a branch — the branch scan above already proves the
      // Support branch is gone; this pins the route names/paths.
      expect(branchPaths, contains('/customer/shops'));
      expect(RouteNames.customerSupport, '/customer/support');
      expect(RouteNames.customerShops, '/customer/shops');
    });

    test('Shops map is a branch-internal sub-screen, not a tab root', () {
      expect(RouteNames.customerShopsMap, '/customer/shops/map');
      expect(AppShell.tabRootPaths, isNot(contains('/customer/shops/map')));
      final shopsBranch = _allBranches().firstWhere(
        (b) => (b.routes.first as GoRoute).path == '/customer/shops',
      );
      final shopsPaths = [
        for (final r in shopsBranch.routes) (r as GoRoute).path,
      ];
      expect(shopsPaths, ['/customer/shops', '/customer/shops/map']);
    });

    testWidgets('Shops tab label renders in English', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: AppShellNav(
              currentIndex: 1,
              onTap: (_) {},
              items: AppRouter.customerTabs,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shops'), findsOneWidget);
      expect(find.text('Support'), findsNothing);
    });
  });

  group('customer tabs rework: Support from Profile', () {
    testWidgets('Profile has a Support row with the badge; tapping opens support',
        (tester) async {
      var openedSupport = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomerProfileView(
              onOpenSupport: () => openedSupport = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Support'), findsOneWidget);
      // The unread indicator moved with Support: the row's leading
      // icon is the live badge widget (plain icon at zero replies).
      expect(find.byType(CustomerSupportBadge), findsOneWidget);
      expect(find.byType(Badge), findsNothing);

      // The hub's Profile tab is taller than the old view (identity
      // card + trust section above the menu), so the Support row can
      // sit below the fold at the default test size.
      await tester.ensureVisible(find.text('Support'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Support'));
      await tester.pumpAndSettle();
      expect(openedSupport, isTrue);
    });
  });

  group('customer tabs rework: home bell + tab bar', () {
    late GoRouter router;

    // The AppBar title is deliberately different from the body text
    // so find.text(body) matches exactly one widget.
    Widget stub(String text) => Scaffold(
          appBar: AppBar(title: const Text('Stub screen')),
          body: Center(child: Text(text)),
        );

    GoRouter buildRouter() {
      return GoRouter(
        initialLocation: RouteNames.customerHome,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => AppShell(
              navigationShell: shell,
              tabs: AppRouter.customerTabs,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RouteNames.customerHome,
                    builder: (context, state) => Scaffold(
                      body: Column(
                        children: [
                          const CustomerHomeAppBar(
                            title: 'Home',
                            userInitial: 'G',
                          ),
                          const Expanded(
                            child: Center(child: Text('Home stub')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RouteNames.customerShops,
                    builder: (context, state) => stub('Shops stub'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RouteNames.customerBookings,
                    builder: (context, state) => stub('Bookings stub'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RouteNames.customerWallet,
                    builder: (context, state) => stub('Wallet stub'),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RouteNames.customerProfile,
                    builder: (context, state) => stub('Profile stub'),
                  ),
                ],
              ),
            ],
          ),
          // Support as a top-level sub-screen, like the real router.
          GoRoute(
            path: RouteNames.customerSupport,
            builder: (context, state) => stub('Support inbox'),
          ),
        ],
      );
    }

    setUp(() => router = buildRouter());
    tearDown(() => router.dispose());

    testWidgets('bell still opens the support inbox as a sub-screen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home stub'), findsOneWidget);
      expect(find.byType(AppShellNav), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Support inbox'), findsOneWidget);
      // A sub-screen: no tab bar, and the back arrow exists.
      expect(find.byType(AppShellNav), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);

      // Back returns to Home — the bell pushed, it did not replace
      // the shell (a `go` here would strand the user with no back).
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home stub'), findsOneWidget);
      expect(find.byType(AppShellNav), findsOneWidget);
      expect(
        tester.widget<AppShellNav>(find.byType(AppShellNav)).currentIndex,
        0,
      );
    });

    testWidgets('tapping the Shops tab switches to the Shops branch',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shops'));
      await tester.pumpAndSettle();
      expect(find.text('Shops stub'), findsOneWidget);
      expect(
        tester.widget<AppShellNav>(find.byType(AppShellNav)).currentIndex,
        1,
      );
      expect(find.text('Support'), findsNothing);
    });
  });
}
