import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';

/// Phase 1 showroom redesign: the owner Dashboard quick actions as
/// a 4-column circular icon row (Add Car, Scan QR, New Booking, Add
/// Customer) above a 3-column row of compact cards (Finance,
/// Reports, Requests). The tiles are owner-local on purpose —
/// [QuickActionTiles] is shared with customer Home, so its look is
/// not touched for this redesign. Icons use the guide accent
/// (`accentOrangeFor`); the Requests badge is a filled `orangeFill`
/// pill (white on #C2410C is 5.18:1) with a weight-500 count, never
/// bold, and only renders while [waitingCount] is above zero.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key, this.waitingCount = 0});

  final int waitingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = AppColors.accentOrangeFor(Theme.of(context).brightness);
    return Column(
      children: [
        Row(
          children: [
            _CircleAction(
              icon: Icons.add_circle_outline_rounded,
              label: l10n.dashboardQuickAddCar,
              accent: accent,
              onTap: () => context.push(RouteNames.ownerAddVehicle),
            ),
            _CircleAction(
              icon: Icons.qr_code_scanner_rounded,
              label: l10n.dashboardQuickScanQr,
              accent: accent,
              onTap: () => context.push(RouteNames.ownerQrScan),
            ),
            _CircleAction(
              icon: Icons.note_add_rounded,
              label: l10n.dashboardQuickNewBooking,
              accent: accent,
              onTap: () => context.push(RouteNames.ownerManualBooking),
            ),
            _CircleAction(
              icon: Icons.person_add_rounded,
              label: l10n.dashboardQuickAddCustomer,
              accent: accent,
              onTap: () => context.push(RouteNames.ownerAddCustomer),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CompactAction(
              icon: Icons.account_balance_wallet_rounded,
              label: l10n.dashboardQuickFinance,
              accent: accent,
              onTap: () => context.push(RouteNames.ownerFinance),
            ),
            _CompactAction(
              icon: Icons.bar_chart_rounded,
              label: l10n.dashboardQuickViewReports,
              accent: accent,
              onTap: () => context.push(RouteNames.ownerReports),
            ),
            _CompactAction(
              icon: Icons.inbox_rounded,
              label: l10n.dashboardQuickRequests,
              accent: accent,
              badgeCount: waitingCount > 0 ? waitingCount : null,
              onTap: () => context.go(RouteNames.ownerRequests),
            ),
          ],
        ),
      ],
    );
  }
}

/// One circular primary action: a 56 dp tinted icon circle above a
/// short label. The whole column taps (well above the 48 dp minimum)
/// and carries a [Tooltip] with the same label.
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One compact secondary action: a canonical card (borderSubtle,
/// radius 16) with a 40 dp tinted icon circle above a short label.
/// [badgeCount] renders a filled pill at the card's end corner.
class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final badge = badgeCount;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: label,
          child: Container(
            decoration: AppCardDecoration.of(context),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 76),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, size: 22, color: accent),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (badge != null)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Container(
                            key: const Key('requests-waiting-badge'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orangeFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badge',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
