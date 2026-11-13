// Audit 2026-11-13, SH-N6 — nav visibility is a hardcoded path set.
//
// `AppShell.tabRootPaths` is a second source of truth next to the
// shell branches: adding an 11th tab root, or renaming a route, would
// silently lose the tab bar with no compile error. This test pins the
// two to each other — the set must equal the set of branch initial
// locations, so a new tab root (or a rename) fails here first.
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/routing/app_shell.dart';

void main() {
  test('tabRootPaths equals the set of shell branch initial locations (SH-N6)', () {
    // A branch's initialLocation is null unless set explicitly, so it
    // cannot be the tab root — the root is the first route of each
    // branch (the same derivation ui_navigation_test uses).
    final branchLocations = AppRouter.router.configuration.routes
        .whereType<StatefulShellRoute>()
        .expand((route) => route.branches)
        .map((branch) => (branch.routes.first as GoRoute).path)
        .toSet();
    expect(branchLocations.length, 10,
        reason: 'Expected 10 tab roots (5 customer + 5 owner).');
    expect(AppShell.tabRootPaths, branchLocations,
        reason:
            'tabRootPaths drifted from the shell branches — a tab root was added or renamed without updating AppShell.tabRootPaths (or vice versa).');
  });
}
