import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import 'admin_desktop_header.dart';
import 'admin_sidebar_nav.dart';

/// Phase A (A6) — the shared shell for the admin panel's real screens:
/// sidebar + header + content. On narrow windows the sidebar becomes a
/// horizontal nav strip so the shell never overflows.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onRefresh,
  });

  final String activeRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final content = Column(
            children: [
              AdminDesktopHeader(
                title: title,
                subtitle: subtitle,
                onRefresh: onRefresh,
              ),
              Expanded(child: child),
            ],
          );
          if (!wide) {
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: _navButtons(context),
                  ),
                ),
                Expanded(child: content),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSidebarNav(
                activeRoute: activeRoute,
                onNavigate: (route) => context.go(route),
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _navButtons(BuildContext context) {
    const items = [
      ('Dashboard', '/admin/dashboard'),
      ('Shops', '/admin/shops'),
      ('Blacklist', '/admin/blacklist'),
      ('Admin Team', '/admin/team'),
      ('Activity Log', '/admin/activity'),
      ('Subscriptions', '/admin/subscriptions'),
    ];
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ChoiceChip(
                label: Text(item.$1),
                selected: activeRoute == item.$2,
                onSelected: (_) => context.go(item.$2),
              ),
            ))
        .toList();
  }
}
