import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/quick_action_tiles.dart';
import '../../../../../l10n/app_localizations.dart';

/// Customer rework (Worker C): the customer Home quick actions.
///
/// Customer pass (2026-11-16): "Book a Car" left this row — it is
/// the Home's primary action and now lives on the extended floating
/// button in [CustomerHomeView], same destination (the Shops tab).
///
/// Destinations (all real, no dead tiles):
/// - Wallet → the wallet tab ([RouteNames.customerWallet]).
/// - Support → the support inbox ([RouteNames.customerSupport]) as
///   a sub-screen (pushed, so back returns to Home — Support is no
///   longer a tab).
/// - SOS → the SOS screen ([RouteNames.customerSos]).
class CustomerHomeQuickActions extends StatelessWidget {
  const CustomerHomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return QuickActionTiles(
      tiles: [
        QuickActionTile(
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.walletLabel,
          color: AppColors.primary,
          onTap: () => context.go(RouteNames.customerWallet),
        ),
        QuickActionTile(
          icon: Icons.support_agent_rounded,
          label: l10n.home2_support,
          color: AppColors.accentSuccess,
          onTap: () => context.push(RouteNames.customerSupport),
        ),
        QuickActionTile(
          icon: Icons.sos_rounded,
          label: l10n.sos,
          color: AppColors.accentDanger,
          onTap: () => context.push(RouteNames.customerSos),
        ),
      ],
    );
  }
}
