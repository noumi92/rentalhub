import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/routing/shell_navigation.dart';

void main() {
  group('GoRouter duplicate page key regression tests', () {
    test('no GoRoute in AppRouter defines a custom pageBuilder that overrides state.pageKey', () {
      void checkRoutes(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is StatefulShellRoute) {
            for (final branch in route.branches) {
              checkRoutes(branch.routes);
            }
          } else if (route is ShellRoute) {
            checkRoutes(route.routes);
          } else if (route is GoRoute) {
            expect(
              route.pageBuilder,
              isNull,
              reason:
                  'Route ${route.path} should use builder (not a custom '
                  'pageBuilder with a deterministic ValueKey) so pushed pages '
                  'keep go_router unique state.pageKey values.',
            );
            checkRoutes(route.routes);
          }
        }
      }

      checkRoutes(AppRouter.router.configuration.routes);
    });

    test('customerEditProfile matches /customer/profile/edit directly', () {
      final matchList = AppRouter.router.configuration.findMatch(
        Uri.parse(RouteNames.customerEditProfile),
      );
      expect(matchList.isError, isFalse);
      expect(matchList.fullPath, RouteNames.customerEditProfile);
    });

    testWidgets(
      'pushing the same parameterized route twice in a StatefulShellBranch does not throw duplicate page key',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/owner/fleet',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => Scaffold(body: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/owner/fleet',
                      builder: (context, _) => Scaffold(
                        body: TextButton(
                          onPressed: () => context.push('/owner/rates/v1'),
                          child: const Text('Open Rates'),
                        ),
                      ),
                    ),
                    GoRoute(
                      path: '/owner/rates/:vehicleId',
                      builder: (context, state) => Scaffold(
                        body: TextButton(
                          onPressed: () => context.push('/owner/rates/v1'),
                          child: Text(
                            'Rates ${state.pathParameters['vehicleId']}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Rates'));
        await tester.pumpAndSettle();
        expect(find.text('Rates v1'), findsOneWidget);

        // Second push of the exact same vehicleId must not collide on Page.key.
        await tester.tap(find.text('Rates v1'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Rates v1'), findsOneWidget);
      },
    );

    testWidgets(
      'safePush from top-level route above StatefulShellRoute into shell route does not duplicate ShellRoutePageKey',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/customer/home',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => Scaffold(body: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/customer/home',
                      builder: (context, _) => Scaffold(
                        body: TextButton(
                          onPressed: () => context.push('/customer/support'),
                          child: const Text('Open Support'),
                        ),
                      ),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/customer/bookings',
                      builder: (_, __) => const Scaffold(
                        body: Text('Bookings Root'),
                      ),
                    ),
                    GoRoute(
                      path: '/customer/payment/:id',
                      builder: (context, state) => Scaffold(
                        body: Column(
                          children: [
                            Text('Payment ${state.pathParameters['id']}'),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Back'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/customer/support',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push('/customer/notifications'),
                  child: const Text('Open Notifications'),
                ),
              ),
            ),
            GoRoute(
              path: '/customer/notifications',
              builder: (context, _) => Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () =>
                          safePush(context, '/customer/payment/BK-1'),
                      child: const Text('Open Shell Payment'),
                    ),
                    TextButton(
                      onPressed: () => safePush(context, '/customer/disputes'),
                      child: const Text('Open Top-Level Dispute'),
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/customer/disputes',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Disputes Screen'),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Shell -> top-level Support -> top-level Notifications
        await tester.tap(find.text('Open Support'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Notifications'));
        await tester.pumpAndSettle();

        // Top-level -> top-level keeps Notifications on back stack.
        await tester.tap(find.text('Open Top-Level Dispute'));
        await tester.pumpAndSettle();
        expect(find.text('Disputes Screen'), findsOneWidget);
        await tester.tap(find.text('Disputes Screen'));
        await tester.pumpAndSettle();
        expect(find.text('Open Shell Payment'), findsOneWidget);

        // Top-level -> shell route must not throw !keyReservation.contains(key).
        await tester.tap(find.text('Open Shell Payment'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Payment BK-1'), findsOneWidget);

        // Popping returns cleanly to the shell root.
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Open Support'), findsOneWidget);
      },
    );
  });
}
