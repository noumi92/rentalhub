import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/quick_action_tiles.dart';
import '../../../../../l10n/app_localizations.dart';

/// E1: the owner Dashboard quick actions, built on [QuickActionTiles].
/// Two rows of three: Add Car, Scan QR, New Booking, Finance, Add
/// Customer (→ the add-customer form) and View Reports (→ the new
/// reports screen). Six tiles in one row would be too narrow, so the
/// row is split.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        QuickActionTiles(
          tiles: [
            QuickActionTile(
              icon: Icons.add_circle_outline_rounded,
              label: l10n.dashboardQuickAddCar,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.push(RouteNames.ownerAddVehicle),
            ),
            QuickActionTile(
              icon: Icons.qr_code_scanner_rounded,
              label: l10n.dashboardQuickScanQr,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.push(RouteNames.ownerQrScan),
            ),
            QuickActionTile(
              icon: Icons.note_add_rounded,
              label: l10n.dashboardQuickNewBooking,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.push(RouteNames.ownerManualBooking),
            ),
          ],
        ),
        const SizedBox(height: 8),
        QuickActionTiles(
          tiles: [
            QuickActionTile(
              icon: Icons.account_balance_wallet_rounded,
              label: l10n.dashboardQuickFinance,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.push(RouteNames.ownerFinance),
            ),
            QuickActionTile(
              icon: Icons.person_add_rounded,
              label: l10n.dashboardQuickAddCustomer,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.push(RouteNames.ownerAddCustomer),
            ),
            QuickActionTile(
              icon: Icons.bar_chart_rounded,
              label: l10n.dashboardQuickViewReports,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.push(RouteNames.ownerReports),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // FG-1 (UI/UX audit 2026-11-15): the triage shortcut the
        // quick actions lacked — the queue is one tap away from the
        // dashboard. A single tile stretches full width by design.
        QuickActionTiles(
          tiles: [
            QuickActionTile(
              icon: Icons.inbox_rounded,
              label: l10n.dashboardQuickRequests,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.go(RouteNames.ownerRequests),
            ),
          ],
        ),
      ],
    );
  }
}
