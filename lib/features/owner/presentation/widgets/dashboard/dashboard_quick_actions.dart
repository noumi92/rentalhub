import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/quick_action_tiles.dart';
import '../../../../../l10n/app_localizations.dart';

/// E1: the owner Dashboard quick actions, built on [QuickActionTiles].
/// Every tile pushes a route that already exists: Add Car → the
/// add-vehicle form, Scan QR → the booking QR scanner, New Booking →
/// the manual (walk-in) booking flow, Finance → the finance hub.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return QuickActionTiles(
      tiles: [
        QuickActionTile(
          icon: Icons.add_circle_outline_rounded,
          label: l10n.dashboardQuickAddCar,
          color: AppColors.secondary,
          onTap: () => context.push(RouteNames.ownerAddVehicle),
        ),
        QuickActionTile(
          icon: Icons.qr_code_scanner_rounded,
          label: l10n.dashboardQuickScanQr,
          // Audit fix: AppColors.primary is navy #1B1E5C — on a dark
          // surface the icon on its 15%-alpha tint is ~1.2:1,
          // effectively invisible. The theme primary is lavender in
          // dark mode and navy in light, so it reads in both.
          color: Theme.of(context).colorScheme.primary,
          onTap: () => context.push(RouteNames.ownerQrScan),
        ),
        QuickActionTile(
          icon: Icons.note_add_rounded,
          label: l10n.dashboardQuickNewBooking,
          color: AppColors.accentSuccess,
          onTap: () => context.push(RouteNames.ownerManualBooking),
        ),
        QuickActionTile(
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.dashboardQuickFinance,
          color: AppColors.warning,
          onTap: () => context.push(RouteNames.ownerFinance),
        ),
      ],
    );
  }
}
