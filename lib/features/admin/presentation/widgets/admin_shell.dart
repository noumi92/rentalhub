import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_desktop_header.dart';
import 'admin_sidebar_nav.dart';

/// Phase A (A6) — the shared shell for the admin panel's real screens:
/// sidebar + header + content.
///
/// Mobile-first (2026-11-10): below 900dp the desktop sidebar becomes
/// a navigation drawer with ALL 16 sections and the header becomes a
/// minimal ~56dp app bar — the old horizontal chip strip only listed 6
/// sections, so Customers, Approvals, Cars, Bookings, Disputes,
/// Reviews, Support, Announcements, Reports and Settings were
/// unreachable on a phone. The desktop layout is unchanged.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onRefresh,
    this.onBack,
  });

  final String activeRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onRefresh;

  /// Back button for detail screens. Admin routes are reached by `go`
  /// (the list is replaced, so there is nothing to pop); the caller
  /// supplies the callback that returns to its list route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
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
            title: Text(title),
            leading: onBack == null
                ? null
                : IconButton(
                    icon:
                        const Icon(Icons.arrow_back_rounded, size: 22),
                    tooltip: 'Back',
                    onPressed: onBack,
                  ),
            actions: [
              // Detail screens replace the hamburger with the back
              // button, so the drawer still needs an explicit opener.
              if (onBack != null)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 22),
                    tooltip: 'Menu',
                    onPressed: () =>
                        Scaffold.of(context).openDrawer(),
                  ),
                ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                ),
            ],
          ),
          drawer: Drawer(
            width: 280,
            child: AdminSidebarNav(
              width: 280,
              activeRoute: activeRoute,
              onNavigate: (route) {
                Navigator.of(context).pop();
                context.go(route);
              },
            ),
          ),
          body: _content(context, showHeader: false),
        );
      },
    );
  }

  Widget _content(BuildContext context, {required bool showHeader}) {
    if (!showHeader) return child;
    return Column(
      children: [
        Row(
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  tooltip: 'Back',
                  onPressed: onBack,
                ),
              ),
            Expanded(
              child: AdminDesktopHeader(
                title: title,
                subtitle: subtitle,
                onRefresh: onRefresh,
              ),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }
}
