import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/services/admin_session.dart';
import 'admin_desktop_header.dart';
import 'admin_sidebar_nav.dart';
import 'admin_sticky_action_bar.dart';

/// Phase A (A6) — the shared shell for the admin panel's real screens:
/// sidebar + header + content.
///
/// Phase 2 (2.2/2.3) — one breakpoint system, from the responsive
/// classes ([WindowSizeClass]): below 600dp (compact) the desktop
/// sidebar becomes a navigation drawer with the grouped full list and
/// the header becomes a minimal ~56dp app bar, plus a bottom nav
/// (Home / Queues / Shops / Bookings / More) — More opens the drawer,
/// which stays the fallback full list. At 600dp and up (medium and
/// expanded) the grouped sidebar shell is used, so the 840–899dp
/// range no longer gets the phone shell wrapping desktop-density
/// content. Customers is not a bottom-nav item on purpose: shops and
/// bookings are the daily operational lists, and customers are usually
/// reached from a booking, ticket or shop context (or the drawer).
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onRefresh,
    this.onBack,
    this.onSignOut,
    this.bottomBar,
  });

  final String activeRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onRefresh;

  /// AD-M3: desktop-header sign-out. When null the shell signs out
  /// itself (FirebaseAuth + AdminSession.clear + route to login).
  /// The sidebar footer always signs out (it has no override).
  final VoidCallback? onSignOut;

  /// Back button for detail screens. Admin routes are reached by `go`
  /// (the list is replaced, so there is nothing to pop); the caller
  /// supplies the callback that returns to its list route.
  final VoidCallback? onBack;

  /// Phase 4 (4.4a) — a sticky action bar for detail screens,
  /// rendered by [AdminStickyActionBar]: on compact screens it
  /// replaces the bottom nav (the back button and drawer still
  /// navigate), on desktop it sits under the content. Detail
  /// screens pass their primary actions here instead of leaving
  /// them at the bottom of a long scroll.
  final Widget? bottomBar;

  /// The bottom-nav index for the current route; anything that is
  /// not one of the four phone destinations highlights More (the
  /// drawer is where it lives).
  static int _bottomNavIndex(String activeRoute) {
    return switch (activeRoute) {
      RouteNames.adminDashboard => 0,
      RouteNames.adminQueues => 1,
      RouteNames.adminShops => 2,
      RouteNames.adminBookings => 3,
      _ => 4,
    };
  }

  Widget _bottomNav(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return Builder(
      builder: (scaffoldContext) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: _bottomNavIndex(activeRoute),
        onTap: (index) {
          if (index == 4) {
            Scaffold.of(scaffoldContext).openDrawer();
            return;
          }
          context.go(switch (index) {
            0 => RouteNames.adminDashboard,
            1 => RouteNames.adminQueues,
            2 => RouteNames.adminShops,
            _ => RouteNames.adminBookings,
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.admin2_navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fact_check_rounded),
            label: l10n.admin2_navQueues,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_rounded),
            label: l10n.admin2_navShops,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: l10n.admin2_navBookings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz_rounded),
            label: l10n.admin2_navMore,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The panel pumps without localizations delegates in tests, so
    // the tooltips fall back to English there (same pattern as the
    // other admin views) instead of crashing on a null check.
    final l10n = AppLocalizations.of(context);
    // Phase 2 (2.3): the shell follows the responsive classes, not
    // its own 900dp switch — compact (< 600dp) gets the phone shell,
    // medium (600–840dp) and expanded (>= 840dp) get the sidebar.
    if (windowSizeClassOf(context) != WindowSizeClass.compact) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSidebarNav(
              activeRoute: activeRoute,
              onNavigate: (route) => context.go(route),
            ),
            Expanded(child: _content(context, showHeader: true)),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        // AD-m3: long titles at large text scales wrap/clip in
        // the 56dp bar without this.
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: onBack == null
            ? null
            : IconButton(
                icon:
                    const Icon(Icons.arrow_back_rounded, size: 22),
                tooltip: l10n?.back ?? 'Back',
                onPressed: onBack,
              ),
        actions: [
          // Detail screens replace the hamburger with the back
          // button, so the drawer still needs an explicit opener.
          if (onBack != null)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                tooltip: l10n?.admin2_menu ?? 'Menu',
                onPressed: () =>
                    Scaffold.of(context).openDrawer(),
              ),
            ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: l10n?.dashboardRefreshTooltip ?? 'Refresh',
              onPressed: onRefresh,
            ),
        ],
      ),
      drawer: Drawer(
        width: 280,
        child: SafeArea(
          child: AdminSidebarNav(
            width: 280,
            activeRoute: activeRoute,
            onNavigate: (route) {
              Navigator.of(context).pop();
              context.go(route);
            },
          ),
        ),
      ),
      bottomNavigationBar: bottomBar != null
          ? AdminStickyActionBar(child: bottomBar!)
          : _bottomNav(context),
      body: _content(context, showHeader: false),
    );
  }

  Widget _content(BuildContext context, {required bool showHeader}) {
    final l10n = AppLocalizations.of(context);
    if (!showHeader) return child;
    return Column(
      children: [
        Row(
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  tooltip: l10n?.back ?? 'Back',
                  onPressed: onBack,
                ),
              ),
            Expanded(
              child: AdminDesktopHeader(
                title: title,
                subtitle: subtitle,
                onRefresh: onRefresh,
                onSignOut: onSignOut ?? () => _signOut(context),
              ),
            ),
          ],
        ),
        Expanded(child: child),
        if (bottomBar != null)
          AdminStickyActionBar(child: bottomBar!),
      ],
    );
  }

  /// AD-M3: the shell's default sign-out — clears the in-memory TOTP
  /// flag and role cache, signs out of Firebase Auth, and routes to
  /// the admin login.
  static Future<void> _signOut(BuildContext context) async {
    AdminSession.clear();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (context.mounted) context.go(RouteNames.adminLogin);
  }
}
