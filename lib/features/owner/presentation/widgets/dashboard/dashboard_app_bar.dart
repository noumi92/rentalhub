import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/app_icon_chip.dart';
import '../../../../../core/widgets/minimal_app_bar.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit impl (O29): the dashboard app bar — title + real shop
/// name, bell (with unread badge) to notifications, settings and
/// refresh. Extracted from [OwnerDashboardView] so the view stays
/// under the 250-line cap.
class DashboardAppBar extends StatelessWidget {
  final String shopName;
  final int unreadNotifications;
  final VoidCallback onRefresh;

  const DashboardAppBar({
    super.key,
    required this.shopName,
    required this.unreadNotifications,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MinimalAppBar(
      title: l10n.dashboardTitle,
      subtitle: shopName.isNotEmpty ? shopName : l10n.dashboardMyShowroom,
      actions: [
        AppIconChip(
          icon: Icons.notifications_rounded,
          tooltip: l10n.dashboardNotificationsTooltip,
          background: Colors.white.withValues(alpha: 0.15),
          iconColor: Colors.white,
          badgeCount: unreadNotifications > 0 ? unreadNotifications : null,
          onPressed: () => context.push(RouteNames.ownerNotifications),
        ),
        const SizedBox(width: 8),
        AppIconChip(
          icon: Icons.settings_rounded,
          tooltip: l10n.dashboardSettingsTooltip,
          background: Colors.white.withValues(alpha: 0.15),
          iconColor: Colors.white,
          onPressed: () => context.push(RouteNames.ownerSettings),
        ),
        const SizedBox(width: 8),
        AppIconChip(
          icon: Icons.refresh_rounded,
          tooltip: l10n.dashboardRefreshTooltip,
          background: Colors.white.withValues(alpha: 0.15),
          iconColor: Colors.white,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
