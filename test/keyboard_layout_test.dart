import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/app_shell.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_wizard.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keyboard-layout regression (phone bug, run #51 APK, 2026-11-09):
// tapping any text field covered almost all of the screen with
// empty space, on every form screen in the app.
//
// Root cause: nested Scaffolds double-counting the keyboard.
// AppShell is a Scaffold and every in-shell view is itself a
// Scaffold (default resizeToAvoidBottomInset: true). Both resized
// for the same keyboard, so the inner body lost the keyboard
// height TWICE: on a 360x800 phone with a ~300px keyboard a
// sub-screen's inner body was 800-300-300 = 200px, and after the
// app bar + stepper + bottom buttons the scrollable form area
// collapsed to 0px — the 300px the inner Scaffold "reserved" for
// the keyboard sat as a blank band, because the keyboard was
// already below the outer body.
//
// Fix: AppShell sets resizeToAvoidBottomInset: false, so the inner
// Scaffold does the single resize. These tests pump the REAL
// AppShell (real go_router StatefulShellRoute) at 360x800 with
// simulated keyboard insets and assert the form area does NOT
// collapse and the focused field is actually visible above the
// keyboard. Before the fix the tab-root scroll area measured 88px
// and the wizard's 0px; after the fix they measure 332px and
// 294px, with the focused field fully visible.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const phoneSize = Size(360, 800);
  const keyboardHeight = 300.0;
  const keyboardTop = 800 - keyboardHeight; // 500

  void setPhone(WidgetTester tester) {
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  void openKeyboard(WidgetTester tester) {
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
  }

  GoRouter testRouter({required String path, required Widget screen}) {
    return GoRouter(
      initialLocation: path,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
            tabs: const [
              ShellNavItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              ShellNavItem(icon: Icon(Icons.directions_car), label: 'Fleet'),
              ShellNavItem(icon: Icon(Icons.inbox), label: 'Requests'),
              ShellNavItem(icon: Icon(Icons.people), label: 'Customers'),
              ShellNavItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: path, builder: (_, __) => screen),
            ]),
          ],
        ),
      ],
    );
  }

  /// A form screen shaped like the real in-shell views: Scaffold >
  /// Column[56px header, Expanded(SingleChildScrollView(form)),
  /// 56px button row]. [scrollKey] identifies the scroll area.
  Widget formScreen({required Key scrollKey, required int fieldCount}) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              height: 56,
              color: Colors.blueGrey,
              alignment: Alignment.center,
              child: const Text('Test form'),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: scrollKey,
                child: Column(
                  children: [
                    for (var i = 0; i < fieldCount; i++)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          key: ValueKey('field-$i'),
                          decoration:
                              InputDecoration(labelText: 'Field $i'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  group('AppShell keyboard layout (run #51 phone bug)', () {
    testWidgets('tab root: keyboard open keeps the form area usable',
        (tester) async {
      setPhone(tester);
      final router = testRouter(
        path: '/owner/dashboard',
        screen: formScreen(
          scrollKey: const Key('tab-root-scroll'),
          fieldCount: 6,
        ),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      // Sanity: the tab bar is visible on a tab root.
      expect(find.text('Dashboard'), findsWidgets);

      openKeyboard(tester);
      final lastField = find.byKey(const ValueKey('field-5'));
      await tester.showKeyboard(lastField);
      await tester.pumpAndSettle();

      final scrollRect =
          tester.getRect(find.byKey(const Key('tab-root-scroll')));
      final fieldRect = tester.getRect(lastField);
      final visibleFieldHeight = fieldRect.intersect(scrollRect).height;
      // The form area must not collapse: with one resize it is
      // 800-56(nav)-300(keyboard)-56(header)-56(buttons) = 332px.
      // With the double resize it collapses to ~32px.
      expect(scrollRect.height, greaterThanOrEqualTo(200),
          reason: 'form scroll area collapsed under the keyboard');
      expect(fieldRect.bottom, lessThanOrEqualTo(keyboardTop),
          reason: 'focused field must sit above the keyboard');
      expect(visibleFieldHeight, greaterThanOrEqualTo(40),
          reason: 'focused field must be actually visible, not clipped');
    });

    testWidgets(
        'wizard sub-screen: keyboard open keeps the form area usable',
        (tester) async {
      setPhone(tester);
      final router = testRouter(
        path: '/owner/customers/add',
        screen: OwnerAddCustomerWizard(prefilledCnic: '35201-1234567-1'),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      // Sanity: no tab bar on a sub-screen.
      expect(find.text('Dashboard'), findsNothing);
      expect(find.byType(OwnerAddCustomerWizard), findsOneWidget);

      openKeyboard(tester);
      final phoneField = find.widgetWithText(TextField, 'WhatsApp number');
      await tester.showKeyboard(phoneField);
      await tester.pumpAndSettle();

      final scrollRect =
          tester.getRect(find.byType(SingleChildScrollView).first);
      final fieldRect = tester.getRect(phoneField);
      final visibleFieldHeight = fieldRect.intersect(scrollRect).height;
      // With one resize the wizard scroll area is
      // 800-300(keyboard)-56(app bar)-~70(stepper)-~70(buttons) = ~304px.
      // With the double resize it collapses to ~4px.
      expect(scrollRect.height, greaterThanOrEqualTo(200),
          reason: 'wizard scroll area collapsed under the keyboard');
      expect(fieldRect.bottom, lessThanOrEqualTo(keyboardTop),
          reason: 'focused field must sit above the keyboard');
      expect(visibleFieldHeight, greaterThanOrEqualTo(40),
          reason: 'focused field must be actually visible, not clipped');
    });

    testWidgets(
        'control: a standalone single Scaffold keeps its form usable',
        (tester) async {
      // Same shape as LoginView: one Scaffold, no shell around it.
      // This passed before the fix and must keep passing.
      setPhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: formScreen(
            scrollKey: const Key('standalone-scroll'),
            fieldCount: 6,
          ),
        ),
      );
      await tester.pumpAndSettle();

      openKeyboard(tester);
      final lastField = find.byKey(const ValueKey('field-5'));
      await tester.showKeyboard(lastField);
      await tester.pumpAndSettle();

      final scrollRect =
          tester.getRect(find.byKey(const Key('standalone-scroll')));
      final fieldRect = tester.getRect(lastField);
      final visibleFieldHeight = fieldRect.intersect(scrollRect).height;
      expect(scrollRect.height, greaterThanOrEqualTo(200));
      expect(fieldRect.bottom, lessThanOrEqualTo(keyboardTop));
      expect(visibleFieldHeight, greaterThanOrEqualTo(40));
    });
  });
}
