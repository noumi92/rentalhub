import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_shell_nav.dart';
import '../widgets/offline_banner.dart';
import 'route_names.dart';

/// Phase C (C1): the shell scaffold shared by the customer and owner
/// `StatefulShellRoute`s. One shell per module, five branches each —
/// customer (Home, Shops, Bookings, Wallet, Profile), owner
/// (Dashboard, Fleet, Requests, Customers, Settings). Each branch
/// keeps its own navigation stack and scroll state, so switching tabs
/// no longer rebuilds the destination or loses state.
///
/// The shell owns the navigation widget and the offline banner:
/// - the [OfflineBanner] lives here once (Phase B deferred the
///   full banner rollout to this shell) instead of once per tab
///   screen, so every tab root shows the same sync state;
/// - the [AppShellNav] is the single flush nav (C2, §4.4); the tab
///   screens no longer embed one.
///
/// Phone-test #17 (user rule: every screen with a back arrow is a
/// sub-screen and gets no bottom navigation): the bar is visible
/// exactly when the current screen is a tab root — which is exactly
/// when there is no back arrow. The check is ONE condition here, on
/// the current route path, instead of one route move per sub-screen:
/// 10 tab roots keep the bar, 45 mobile sub-screens lose it. From a
/// sub-screen the only way back is the back arrow / system back,
/// which returns to the tab root and the bar reappears.
///
/// The visibility reads the live route through
/// [GoRouterState.of] in [build], so the shell rebuilds (and the
/// bar appears/disappears) on every inner push/pop — the same
/// signal [MinimalAppBar] uses for its back button
/// (`Navigator.canPop`), expressed as a path set because the shell
/// sits above the branch navigators and cannot ask them directly.
///
/// Re-tapping the active tab pops that branch back to its root
/// (`goBranch` with `initialLocation: true`); tapping another tab
/// restores that branch's stack where the user left it.
class AppShell extends StatelessWidget {
  /// The 10 tab-root paths (rulebook §4.4). Any other path inside a
  /// shell branch is a sub-screen and hides the tab bar.
  /// Customer rework: the Shops tab root is /customer/shops; Support
  /// (/customer/support) is no longer a tab — it is a top-level
  /// sub-screen reached from Profile and the home bell, so it is
  /// deliberately NOT in this set.
  static const Set<String> tabRootPaths = {
    RouteNames.customerHome,
    RouteNames.customerShops,
    RouteNames.customerBookings,
    RouteNames.customerWallet,
    RouteNames.customerProfile,
    RouteNames.ownerDashboard,
    RouteNames.ownerFleet,
    RouteNames.ownerRequests,
    RouteNames.ownerCustomers,
    RouteNames.ownerSettings,
  };
  final StatefulNavigationShell navigationShell;
  final List<ShellNavItem> tabs;

  const AppShell({
    super.key,
    required this.navigationShell,
    required this.tabs,
  });

  void _onTap(int index) {
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
    } else {
      navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // #17: the bar is visible exactly on a tab root. The OfflineBanner
    // stays above the content either way (untouched).
    final showNav =
        tabRootPaths.contains(GoRouterState.of(context).uri.path);
    // Audit fix (C1 / dead band): the shell consumes the top inset
    // exactly once. This SafeArea adds it above the banner/content,
    // and removePadding strips it from the branch subtree, so
    // MinimalAppBar and each view's SafeArea cannot add it a second
    // time — no ~status-bar-height empty strip appears between the
    // banner and the header when the banner is visible, and the
    // header still clears the status bar when it is hidden.
    // Phone bug (run #51 APK): this outer Scaffold must NOT resize
    // for the keyboard. Every in-shell view is itself a Scaffold
    // (default resizeToAvoidBottomInset: true) and resizes its own
    // body for the keyboard; if this outer Scaffold resized too, the
    // inner body lost the keyboard height TWICE and the form's
    // scroll area collapsed to ~0 px — the screen was almost
    // entirely empty space while typing, with the focused field
    // invisible. With resize off here, the inner Scaffold does the
    // single resize; the tab bar stays at the screen bottom behind
    // the keyboard while typing, which is the standard behaviour.
    // (Regression: test/keyboard_layout_test.dart.)
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: navigationShell,
              ),
            ),
          ],
        ),
      ),
      // #16: the flush bar attaches to the bottom edge — no SafeArea
      // around it. It renders only on tab roots (see above).
      bottomNavigationBar: showNav
          ? AppShellNav(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
              items: tabs,
            )
          : null,
    );
  }
}
