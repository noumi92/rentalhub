import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/data/sync_engine.dart';
import 'package:rentalhub/core/data/sync_status_cubit.dart';
import 'package:rentalhub/core/network/connectivity_service.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/app_shell.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_icon_chip.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/core/widgets/offline_banner.dart';
import 'package:rentalhub/features/customer/presentation/widgets/customer_support_badge.dart';
import 'package:rentalhub/features/owner/presentation/widgets/owner_requests_badge.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Phase C (C1–C3): the navigation rebuild — StatefulShellRoute shells,
// the single flush nav, badges, and the orphan-route scan.
//
// Phone-test #16/#17: the floating pill is gone — the bar is 56 px of
// content, flush to the bottom edge, no margin/radius/SafeArea — and it
// is visible only on the 10 tab roots (`AppShell.tabRootPaths`).
//
// Audit fix (gesture bar, §4.4 decision): the 56 px content height is
// kept, but `MediaQuery.padding.bottom` is added BELOW it, so the tab
// labels clear the Android system gesture pill. The bar stays flush —
// the extra height is system inset, not padding around the bar.

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
          '/customer/shops',
          '/customer/bookings',
          '/customer/wallet',
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
        '/customer/shops',
        '/customer/bookings',
        '/customer/wallet',
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

    test('owner tab 3 is labelled Bookings', () {
      expect(AppRouter.ownerTabs[2].label, 'Bookings');
      expect(AppRouter.ownerTabs.map((t) => t.label).toList(), [
        'Dashboard',
        'Fleet',
        'Bookings',
        'Customers',
        'Settings',
      ]);
      expect(AppRouter.customerTabs.map((t) => t.label).toList(), [
        'Home',
        'Shops',
        'Bookings',
        'Wallet',
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
      // Phone bug: the bar used to be a Material NavigationBar forced
      // to 56 px, which clipped the labels — the custom bar renders
      // every tab label fully inside the bar instead.
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
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
        tester.widget<AppShellNav>(find.byType(AppShellNav)).currentIndex,
        0,
      );
    });
  });

  group('Phase C: flush nav geometry and colours', () {
    Future<void> pumpNav(
      WidgetTester tester, {
      required ThemeData theme,
      double bottomPadding = 0,
      double textScale = 1.0,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 640),
              padding: EdgeInsets.only(bottom: bottomPadding),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
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
      // Phone bug: the old NavigationBar clipped the labels below
      // the 56 px edge — every label must sit fully inside the bar.
      final barRect = tester.getRect(find.byType(AppShellNav));
      for (final label in ['Home', 'Bookings']) {
        final labelRect = tester.getRect(find.text(label));
        expect(labelRect.top >= barRect.top, isTrue, reason: label);
        expect(labelRect.bottom <= barRect.bottom, isTrue, reason: label);
      }
      final theme = Theme.of(
        tester.element(find.byType(AppShellNav)),
      );
      expect(theme.navigationBarTheme.indicatorColor, AppColors.orangeFill);
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
        tester.element(find.byType(AppShellNav)),
      );
      expect(theme.navigationBarTheme.indicatorColor, AppColors.orangeFill);
    });

    testWidgets(
        'gesture inset: 24 px below the 56 px content, labels stay clear',
        (tester) async {
      await pumpNav(tester,
          theme: AppTheme.lightTheme, bottomPadding: 24);
      // 56 px of content + 24 px of system inset below it; the
      // destinations themselves are still exactly 56 px tall, so the
      // labels stay clear of the gesture pill.
      final container = navContainer(tester, AppColors.primary);
      expect(tester.getSize(find.byWidget(container)).height, 56 + 24);
      final barRect = tester.getRect(find.byType(AppShellNav));
      for (final label in ['Home', 'Bookings']) {
        final labelRect = tester.getRect(find.text(label));
        expect(labelRect.bottom <= barRect.top + AppShellNav.navHeight,
            isTrue,
            reason: label);
      }
      // The bar is still flush: no margin, no radius, no SafeArea.
      expect(container.margin, isNull);
      expect(container.decoration, isNull);
      expect(
        find.ancestor(
          of: find.byType(AppShellNav),
          matching: find.byType(SafeArea),
        ),
        findsNothing,
      );
    });

    testWidgets('tab bar grows past 56 px at 200% text scale, no overflow',
        (tester) async {
      await pumpNav(tester, theme: AppTheme.lightTheme, textScale: 2.0);
      expect(tester.takeException(), isNull);
      final container = navContainer(tester, AppColors.primary);
      expect(tester.getSize(find.byWidget(container)).height,
          greaterThan(AppShellNav.navHeight));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      // The labels still sit fully inside the grown bar.
      final barRect = tester.getRect(find.byType(AppShellNav));
      for (final label in ['Home', 'Bookings']) {
        final labelRect = tester.getRect(find.text(label));
        expect(labelRect.top >= barRect.top, isTrue, reason: label);
        expect(labelRect.bottom <= barRect.bottom, isTrue, reason: label);
      }
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

  group('Audit fix — shared chrome tap targets', () {
    testWidgets('AppIconChip: 40 dp visual, 48 dp hit area when tappable',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppIconChip(
              icon: Icons.notifications_rounded,
              tooltip: 'Notifications',
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The whole chip widget is the 48 dp tap target (§4.6).
      expect(tester.getSize(find.byType(AppIconChip)),
          const Size(48, 48));
      // The visual circle inside it is still 40 dp.
      final visual = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );
      expect(tester.getSize(visual), const Size(40, 40));
    });

    testWidgets('AppIconChip without onPressed stays a 40 dp visual',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIconChip(icon: Icons.notifications_rounded),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AppIconChip)),
          const Size(40, 40));
    });

    testWidgets('failed sync banner is at least 48 dp tall', (tester) async {
      // Drive a real cubit to the failed state (one exhausted entry),
      // the same path offline_sync_test uses.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      final controller = StreamController<List<ConnectivityResult>>();
      final service = ConnectivityService(
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: controller.stream,
        debounce: Duration.zero,
      );
      final cubit = SyncStatusCubit(connectivity: service, queue: queue);
      await service.start();
      await cubit.start();
      await queue.enqueue(kind: 'test', entityId: 'a', payload: {'x': 1});
      for (var i = 0; i < 5; i++) {
        await engine.drain();
        final entry = (await queue.pendingEntries()).first;
        await queue.updateEntry(entry.copyWith(
          nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ));
      }
      await cubit.refresh();
      expect(cubit.state.failedCount, 1);

      await tester.pumpWidget(
        BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: OfflineBanner()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Sync failed — tap to review'), findsOneWidget);
      expect(tester.getSize(find.byType(OfflineBanner)).height,
          greaterThanOrEqualTo(48));

      await tester.runAsync(() async {
        await cubit.close();
        await service.dispose();
        await controller.close();
      });
    });
  });

  group('Phase C: orphan-route scan', () {
    test('every route is reachable — tab root, navigated to, or listed', () {
      // Tab roots are reachable by construction: the shell nav switches
      // branches by index, never by route name.
      const tabRoots = {
        '/customer/home',
        '/customer/shops',
        '/customer/bookings',
        '/customer/wallet',
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
        // Next-step batch (2026-11-21): the Confirmed screen is
        // rendered inline by the detail route (paid / active) and by
        // the accounts view's defence-in-depth — never pushed to via
        // the router since Verify Confirm now lands on All Bookings.
        // The route stays as a deep link only.
        'ownerBookingConfirmed',
        // Launch-phase Coming Soon (packages_system_ui_ux_audit):
        // plan application & WhatsApp credit purchases/logs are
        // intentionally hidden during initial launch; routes stay
        // registered for Phase 2 activation.
        'ownerSubscriptionPlan',
        'ownerWhatsappLogs',
        'ownerWhatsappBuyCredits',
        'ownerWhatsappHistory',
        // Unified OwnerBookingDetailView handles /owner/requests/:id;
        // ownerPaymentProof stays registered as a deep-link route.
        'ownerPaymentProof',
        // Replaced by showCustomerAddedBottomSheet in the wizard;
        // route stays registered as a deep-link fallback.
        'ownerCustomerAdded',
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
