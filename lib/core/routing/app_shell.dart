import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_shell_nav.dart';
import '../widgets/offline_banner.dart';

/// Phase C (C1): the shell scaffold shared by the customer and owner
/// `StatefulShellRoute`s. One shell per module, five branches each —
/// customer (Home, Bookings, Wallet, Support, Profile), owner
/// (Dashboard, Fleet, Requests, Customers, Settings). Each branch
/// keeps its own navigation stack and scroll state, so switching tabs
/// no longer rebuilds the destination or loses state.
///
/// The shell owns the navigation widget and the offline banner:
/// - the [OfflineBanner] lives here once (Phase B deferred the
///   full banner rollout to this shell) instead of once per tab
///   screen, so every tab root shows the same sync state;
/// - the [AppShellNav] is the single floating nav (C2); the tab
///   screens no longer embed one.
///
/// Re-tapping the active tab pops that branch back to its root
/// (`goBranch` with `initialLocation: true`); tapping another tab
/// restores that branch's stack where the user left it.
class AppShell extends StatelessWidget {
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
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      // Phase D (D2): with edge-to-edge the floating pill must clear
      // the bottom system inset (gesture bar / 3-button nav) instead
      // of sitting on top of the system buttons. The SafeArea adds
      // only the bottom inset; the pill's own geometry is untouched.
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: AppShellNav(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          items: tabs,
        ),
      ),
    );
  }
}
