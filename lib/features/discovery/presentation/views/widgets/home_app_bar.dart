import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/app_icon_chip.dart';
import '../../../../../core/widgets/minimal_app_bar.dart';
import '../../../../../l10n/app_localizations.dart';

/// Customer Home header (#5/#6/#16): the pinned [MinimalAppBar] with
/// the map, bell and avatar actions, each wired to a real destination.
/// Extracted from [CustomerHomeView] so that view stays under the
/// 250-line cap.
///
/// The subtitle is nullable: Home shows the greeting when the
/// signed-in user's name is known, and no subtitle when it is not
/// (a signed-out visitor has no name to greet).
class CustomerHomeAppBar extends StatelessWidget {
  const CustomerHomeAppBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.userInitial,
  });

  final String title;
  final String? subtitle;
  final String userInitial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MinimalAppBar(
      title: title,
      subtitle: subtitle,
      actions: [
        AppIconChip(
          icon: Icons.map_rounded,
          tooltip: l10n.homeSwitchToMap,
          background: Colors.white.withValues(alpha: 0.15),
          iconColor: Colors.white,
          onPressed: () => context.push(RouteNames.customerHomeMap),
        ),
        const SizedBox(width: 8),
        AppIconChip(
          icon: Icons.notifications_none_rounded,
          tooltip: l10n.notifications,
          background: Colors.white.withValues(alpha: 0.15),
          iconColor: Colors.white,
          // Customer rework: Support is a top-level sub-screen now,
          // not a tab — push (not go) so the back arrow exists and
          // returns to Home. Destination unchanged: the support inbox.
          onPressed: () => context.push(RouteNames.customerSupport),
        ),
        const SizedBox(width: 8),
        AppInitialChip(
          initial: userInitial,
          tooltip: l10n.navProfile,
          onPressed: () => context.go(RouteNames.customerProfile),
        ),
      ],
    );
  }
}
