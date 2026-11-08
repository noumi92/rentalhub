import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/app_shell.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/features/customer/presentation/widgets/customer_support_badge.dart';
import 'package:rentalhub/features/owner/presentation/widgets/owner_requests_badge.dart';

// Phase C (C1–C3): the navigation rebuild — StatefulShellRoute shells,
// the single flush nav, badges, and the orphan-route scan.
//
// Phone-test #16/#17: the floating pill is gone — the bar is 56 px,
// flush to the bottom edge, no margin/radius/SafeArea — and it is
// visible only on the 10 tab roots (`AppShell.tabRootPaths`).

String _posix(String path) => path.replaceAll(r'\', '/');

void main() {
  group('Phase C: real router configuration', () {
    List<RouteBase> allRoutes(RouteBase route) {
      if (route is StatefulShellRoute) {
        return [
          for (final branch in route.branches)
            for (final r in branch.routes) ...allRoutes(r),
        ];
      }
      if (route is GoRoute) {
        return [route, for (final r in route.routes) ...allRoutes(r)];
      }
      return [route];
    }

    List<StatefulShellBranch> allBranches() {
      return [
        for (final route in AppRouter.router.configuration.routes)
          if (route is StatefulShellRoute) ...route.branches,
      ];
    }

    test('two shells, five branches each, ten tab roots', () {
      final branches = allBranches();
      expect(branches.length, 10);
      final firstPaths = <String?>[
        for (final branch in branches)
          (branch.routes.first as GoRoute).path,
      ];
      expect(
        firstPaths,
        containsAll([
          '/customer/home',
          '/customer/bookings',
          '/customer/wallet',
          '/customer/support',
          '/customer/profile',
          '/owner/dashboard',
          '/owner/fleet',
          '/owner/requests',
          '/owner/customers',
          '/owner/settings',
        ]),
      );
    });

    test('AppShell.tabRootPaths is exactly the 10 tab roots', () {
      expect(AppShell.tabRootPaths, {
        '/customer/home',
        '/customer/bookings',
        '/customer/wallet',
        '/customer/support',
        '/customer/profile',
        '/owner/dashboard',
        '/owner/fleet',
        '/owner/requests',
        '/owner/customers',
        '/owner/settings',
      });
    });

    test('Home has exactly one tab root; the map is branch-internal', () {
      final branches = allBranches();
      final homeRoots = branches
          .where((b) => (b.routes.first as GoRoute).path == '/customer/home')
          .length;
      expect(homeRoots, 1);
      final mapRoots = branches
          .where(
              (b) => (b.routes.first as GoRoute).path == '/customer/home/map')
          .length;
      expect(mapRoots, 0);
      // The map route still exists — inside the Home branch, not as a tab.
      final paths = <String?>[
        for (final route in AppRouter.router.configuration.routes)
          for (final r in allRoutes(route))
            if (r is GoRoute) r.path,
      ];
      expect(paths, contains('/customer/home/map'));
    });

    test('the orphaned /customer/dashboard route is gone', () {
      final paths = <String?>[
        for (final route in AppRouter.router.configuration.routes)
          for (final r in allRoutes(route))
            if (r is GoRoute) r.path,
      ];
      expect(paths, isNot(contains('/customer/dashboard')));
      expect(
        File('lib/core/routing/route_names.dart').readAsStringSync(),
        isNot(contains('customerDashboard')),
      );
    });

    test('owner tab 3 is labelled Requests, not Bookings', () {
      expect(AppRouter.ownerTabs[2].label, 'Requests');
      expect(AppRouter.ownerTabs.map((t) => t.label).toList(), [
        'Dashboard',
        'Fleet',
        'Requests',
        'Customers',
        'Settings',
      ]);
      expect(AppRouter.customerTabs.map((t) => t.label).toList(), [
        'Home',
        'Bookings',
        'Wallet',
        'Support',
        'Profile',
      ]);
    });
  });

  group('Phase C: shell mechanics (test router, real AppShell)', () {
    late ScrollController controllerA;
    late ScrollController controllerB;
    late GoRouter router;

    Widget stubList(String title, ScrollController controller) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView.builder(
          controller: controller,
          itemCount: 50,
          itemBuilder: (context, i) => ListTile(title: Text('$title item $i')),
        ),
      );
    }

    GoRouter buildRouter({String initialLocation = '/customer/home'}) {
      return GoRouter(
        initialLocation: initialLocation,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => AppShell(
              navigationShell: shell,
              tabs: const [
                ShellNavItem(icon: Icon(Icons.home_rounded), label: 'Tab A'),
                ShellNavItem(icon: Icon(Icons.list_rounded), label: 'Tab B'),
              ],
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    // Real tab-root path: AppShell hides the nav on any
                    // other path, so the test router must use one.
                    path: '/customer/home',
                    builder: (context, state) =>
                        stubList('Screen A', controllerA),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (context, state) => const Scaffold(
                          body: Center(child: Text('Detail A')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/customer/bookings',
                    builder: (context, state) =>
                        stubList('Screen B', controllerB),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    setUp(() {
      controllerA = ScrollController();
      controllerB = ScrollController();
      router = buildRouter();
    });

    tearDown(() {
      controllerA.dispose();
      controllerB.dispose();
      router.dispose();
    });

    testWidgets('exactly one nav widget per shell', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppShellNav), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tab switch preserves the previous tab scroll position',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      controllerA.jumpTo(300);
      await tester.pump();
      expect(controllerA.offset, 300);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();
      expect(find.text('Screen B'), findsOneWidget);

      await tester.tap(find.text('Tab A'));
      await tester.pumpAndSettle();
      expect(find.text('Screen A'), findsOneWidget);
      expect(controllerA.offset, 300);
    });

    testWidgets('the flush bar has no SafeArea around it', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppShellNav), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(AppShellNav),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
    });

    testWidgets('pushing a sub-screen hides the nav; popping brings it back',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byType(AppShellNav), findsOneWidget);

      router.push('/customer/home/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail A'), findsOneWidget);
      expect(find.byType(AppShellNav), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Screen A'), findsOneWidget);
      expect(find.byType(AppShellNav), findsOneWidget);
    });

    testWidgets(
        'deep-linking into a pushed screen hides the nav; popping restores it',
        (tester) async {
      router.dispose();
      router = buildRouter(initialLocation: '/customer/home/detail');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Detail A'), findsOneWidget);
      expect(find.byType(AppShellNav), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Screen A'), findsOneWidget);
      expect(find.byType(AppShellNav), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });
  });

  group('Phase C: flush nav geometry and colours', () {
    Future<void> pumpNav(
      WidgetTester tester, {
      required ThemeData theme,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: AppShellNav(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                ShellNavItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                ShellNavItem(
                    icon: Icon(Icons.receipt_long_rounded),
                    label: 'Bookings'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Container navContainer(WidgetTester tester, Color background) {
      return tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == background,
        ),
      );
    }

    testWidgets('light theme: 56 px flush bar, navy + orange, no margin/radius',
        (tester) async {
      await pumpNav(tester, theme: AppTheme.lightTheme);
      expect(AppShellNav.navHeight, 56);
      final container = navContainer(tester, AppColors.primary);
      expect(container.margin, isNull);
      // No radius, no shadow: a plain colour, no decoration at all.
      expect(container.decoration, isNull);
      expect(find.byType(ClipRRect), findsNothing);
      expect(
        tester.getSize(find.byWidget(container)).height,
        AppShellNav.navHeight,
      );
      expect(
        tester.getSize(find.byType(NavigationBar)).height,
        AppShellNav.navHeight,
      );
      final theme = Theme.of(
        tester.element(find.byType(NavigationBar)),
      );
      expect(theme.navigationBarTheme.indicatorColor, AppColors.secondary);
      expect(
        theme.navigationBarTheme.labelTextStyle
            ?.resolve({WidgetState.selected})
            ?.fontSize,
        12,
      );
    });

    testWidgets('dark theme: navy container, orange indicator',
        (tester) async {
      await pumpNav(tester, theme: AppTheme.darkTheme);
      final container = navContainer(tester, AppColors.primaryDarkOnDark);
      expect(container.margin, isNull);
      expect(container.decoration, isNull);
      final theme = Theme.of(
        tester.element(find.byType(NavigationBar)),
      );
      expect(theme.navigationBarTheme.indicatorColor, AppColors.secondaryDark);
    });
  });

  group('Phase C: tab badges', () {
    testWidgets('Requests badge shows a nonzero count, hides at zero',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OwnerRequestsBadge(
                icon: const Icon(Icons.receipt_long_rounded),
                countStream: Stream.value(3),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OwnerRequestsBadge(
                icon: const Icon(Icons.receipt_long_rounded),
                countStream: Stream.value(0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    });

    testWidgets('Support badge shows a nonzero count, hides at zero',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomerSupportBadge(
                icon: const Icon(Icons.support_agent_rounded),
                countStream: Stream.value(2),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomerSupportBadge(
                icon: const Icon(Icons.support_agent_rounded),
                countStream: Stream.value(0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
    });
  });

  group('Phase C: orphan-route scan', () {
    test('every route is reachable — tab root, navigated to, or listed', () {
      // Tab roots are reachable by construction: the shell nav switches
      // branches by index, never by route name.
      const tabRoots = {
        '/customer/home',
        '/customer/bookings',
        '/customer/wallet',
        '/customer/support',
        '/customer/profile',
        '/owner/dashboard',
        '/owner/fleet',
        '/owner/requests',
        '/owner/customers',
        '/owner/settings',
      };
      // Routes whose screens open via a dialog / direct MaterialPageRoute
      // instead of the router — the route is kept as a deep link only.
      // (Manual booking opens as a dialog from the customer scan view;
      // the contract opens as a dialog from the handover view; the
      // customer-rating screen opens via pushReplacement from the return
      // settlement view.)
      const directConstruction = {
        'ownerManualBooking',
        'ownerContract',
        'ownerRateCustomer',
      };

      final routeNames =
          File('lib/core/routing/route_names.dart').readAsStringSync();
      final constants = RegExp(r"static const String (\w+) = '([^']+)';")
          .allMatches(routeNames)
          .map((m) => (m.group(1)!, m.group(2)!))
          .toList();

      // All of lib/ as one haystack, minus each route's own `path:`
      // definition line — a route only "references itself" there —
      // and minus route_names.dart itself, which holds every literal
      // path as a definition.
      final buffer = StringBuffer();
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !_posix(f.path).endsWith(
              'lib/core/routing/route_names.dart'))) {
        buffer.writeln(file.readAsStringSync());
      }
      final haystack = buffer
          .toString()
          .replaceAll(RegExp(r'.*path: RouteNames\.\w+.*\n?'), '');

      final orphans = <String>[];
      for (final (name, path) in constants) {
        if (tabRoots.contains(path)) continue;
        if (directConstruction.contains(name)) continue;
        final byName = haystack.contains('RouteNames.$name');
        final byLiteral = haystack.contains("'$path'");
        if (!byName && !byLiteral) orphans.add('$name ($path)');
      }
      expect(
        orphans,
        isEmpty,
        reason: 'Phase C (C3): routes nobody can reach — wire an entry '
            'point or delete the route:\n${orphans.join('\n')}',
      );
    });
  });
}
