// Back-navigation tests — the rule the user stated and the audit recorded:
//
//   "Main 5 tabs should NOT have a back button in header, all other
//    screens SHOULD have a button which navigate back to the relevant tab."
//
// The policy lives in CustomCurvedHeader: with no explicit leadingWidget
// it renders a back button exactly when the route can pop (a pushed
// screen) and never at a branch root. These tests pin that policy at
// three levels: the header alone in a plain Navigator, the header inside
// a real StatefulShellRoute shell, and statically — no tab-root view
// re-introduces a hand-copied back button or an onBack field.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/routing/app_shell.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/core/widgets/custom_curved_header.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_shell.dart';

const _backIcon = Icons.arrow_back_ios_new_rounded;

Widget _headerScreen(String title,
        {bool showBackButton = true, Widget? leadingWidget}) =>
    Scaffold(
      body: CustomCurvedHeader(
        titleWidget: Text(title),
        showBackButton: showBackButton,
        leadingWidget: leadingWidget,
      ),
    );

List<File> _tabRootFiles() => [
      'lib/features/discovery/presentation/views/customer_home_view.dart',
      'lib/features/customer/presentation/views/customer_bookings_view.dart',
      'lib/features/customer/presentation/views/customer_wallet_view.dart',
      'lib/features/customer/presentation/views/customer_support_view.dart',
      'lib/features/customer/presentation/views/customer_profile_view.dart',
      'lib/features/owner/presentation/views/owner_dashboard_view.dart',
      'lib/features/owner/presentation/views/owner_fleet_view.dart',
      'lib/features/owner/presentation/views/owner_booking_requests_view.dart',
      'lib/features/owner/presentation/views/owner_customers_list_view.dart',
      'lib/features/owner/presentation/views/owner_settings_view.dart',
    ].map(File.new).toList();

void main() {
  group('Header back policy in a plain Navigator', () {
    testWidgets('no back button at the root', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: _headerScreen('Root'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(_backIcon), findsNothing);
    });

    testWidgets('back button appears on a pushed screen and pops',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _headerScreen('Pushed'),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Pushed'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsOneWidget);

      await tester.tap(find.byIcon(_backIcon));
      await tester.pumpAndSettle();
      expect(find.text('Go'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsNothing);
    });

    testWidgets('showBackButton: false suppresses the button on a push',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _headerScreen(
                        'Pushed',
                        showBackButton: false,
                      ),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Pushed'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsNothing);
    });

    testWidgets('an explicit leadingWidget wins over the automatic button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _headerScreen(
                        'Pushed',
                        leadingWidget: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byIcon(_backIcon), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });

  group('Header back policy inside a StatefulShellRoute shell', () {
    late GoRouter router;

    GoRouter buildRouter() => GoRouter(
          initialLocation: '/a',
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
                      path: '/a',
                      builder: (context, state) => _headerScreen('Screen A'),
                      routes: [
                        GoRoute(
                          path: 'detail',
                          builder: (context, state) =>
                              _headerScreen('Detail A'),
                        ),
                      ],
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/b',
                      builder: (context, state) => _headerScreen('Screen B'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

    setUp(() => router = buildRouter());
    tearDown(() => router.dispose());

    testWidgets('branch roots show no back button', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen A'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsNothing);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();
      expect(find.text('Screen B'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsNothing);
    });

    testWidgets('a pushed screen in a branch shows back and pops to root',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();
      router.push('/a/detail');
      await tester.pumpAndSettle();
      expect(find.text('Detail A'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsOneWidget);

      await tester.tap(find.byIcon(_backIcon));
      await tester.pumpAndSettle();
      expect(find.text('Screen A'), findsOneWidget);
      expect(find.byIcon(_backIcon), findsNothing);
    });
  });

  group('Static guards: no tab root re-introduces its own back button', () {
    test('no tab-root view contains a hand-copied back button', () {
      final offenders = <String>[];
      for (final file in _tabRootFiles()) {
        if (file.readAsStringSync().contains('arrow_back')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Hand-copied back button in a tab root — the header '
              'policy owns back now:\n${offenders.join('\n')}');
    });

    test('no tab-root view declares an onBack field', () {
      final offenders = <String>[];
      for (final file in _tabRootFiles()) {
        if (file.readAsStringSync().contains('onBack')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Dead onBack in a tab root — the router never passes it '
              'and the header policy owns back now:\n${offenders.join('\n')}');
    });
  });

  group('Admin detail back button', () {
    testWidgets('AdminShell shows a back button only when onBack is given',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AdminShell(
            activeRoute: '/admin/shops',
            title: 'Shops',
            subtitle: 'All shops',
            onBack: () => tapped = true,
            child: const Text('Shop list body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(tapped, isTrue);
    });

    testWidgets('AdminShell without onBack shows no back button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminShell(
            activeRoute: '/admin/shops',
            title: 'Shops',
            subtitle: 'All shops',
            child: Text('Shop list body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  });
}
