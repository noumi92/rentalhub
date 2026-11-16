import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/app_icon_chip.dart';
import '../../../../../core/widgets/minimal_app_bar.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit impl (O29): the dashboard app bar — the title is the real
/// shop name (subtitle: the dashboard label), with only the bell
/// (unread badge) to notifications. The Settings and Refresh chips
/// are gone (user layout, 2026-11-16): Settings stays on its own
/// tab, and reload is pull-to-refresh on the body instead of a
/// button. Extracted from [OwnerDashboardView] so the view stays
/// under the 250-line cap.
class DashboardAppBar extends StatelessWidget {
  final String shopName;
  final int unreadNotifications;

  const DashboardAppBar({
    super.key,
    required this.shopName,
    required this.unreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MinimalAppBar(
      title: shopName.isNotEmpty ? shopName : l10n.dashboardMyShowroom,
      subtitle: l10n.dashboardTitle,
      actions: [
        AppIconChip(
          icon: Icons.notifications_rounded,
          tooltip: l10n.dashboardNotificationsTooltip,
          background: Colors.white.withValues(alpha: 0.15),
          iconColor: Colors.white,
          badgeCount: unreadNotifications > 0 ? unreadNotifications : null,
          onPressed: () => context.push(RouteNames.ownerNotifications),
        ),
      ],
    );
  }
}
