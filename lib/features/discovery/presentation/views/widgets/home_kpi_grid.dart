import 'package:flutter/material.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Customer rework (Worker C): the Home KPI grid — active bookings,
/// total trips, wallet balance and trust score, every value from the
/// real repositories. A value that could not be loaded renders as
/// '—', never an invented number. Two columns of two, so a wallet
/// balance such as "Rs. 125,000" still fits at 360px / 1.35x text
/// scale; the tile decoration matches [CustomerStatsRow].
class HomeKpiGrid extends StatelessWidget {
  const HomeKpiGrid({
    super.key,
    required this.activeBookings,
    required this.totalTrips,
    required this.walletTotal,
    required this.trustScore,
    this.onTrustTap,
    this.onBookingsTap,
    this.onWalletTap,
  });

  final int activeBookings;
  final int totalTrips;

  /// Null when the wallet could not be loaded.
  final int? walletTotal;

  /// Null when the customer's `users` doc has no trust score yet.
  final double? trustScore;

  /// The trust tile opens the reputation screen.
  final VoidCallback? onTrustTap;

  /// CU-m14: the bookings tiles open the Bookings tab, the wallet
  /// tile the Wallet tab — no tile looks tappable without going
  /// anywhere.
  final VoidCallback? onBookingsTap;
  final VoidCallback? onWalletTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.directions_car_rounded,
                label: l10n.home2_kpiActive,
                value: '$activeBookings',
                onTap: onBookingsTap,
                tileKey: const ValueKey('home-kpi-active'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                icon: Icons.history_rounded,
                label: l10n.profileTotalTrips,
                value: '$totalTrips',
                onTap: onBookingsTap,
                tileKey: const ValueKey('home-kpi-trips'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.account_balance_wallet_rounded,
                label: l10n.home2_kpiWallet,
                value: walletTotal == null
                    ? '—'
                    : l10n.amountRs(formatRs(walletTotal!)),
                onTap: onWalletTap,
                tileKey: const ValueKey('home-kpi-wallet'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiTile(
                icon: Icons.verified_user_rounded,
                label: l10n.profileTrustScore,
                value: trustScore == null
                    ? '—'
                    : '${trustScore!.toStringAsFixed(1)} ★',
                onTap: onTrustTap,
                tileKey: const ValueKey('home-kpi-trust'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.tileKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final ValueKey<String>? tileKey;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: AppCardDecoration.of(context, radius: 14),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: tileKey ?? const ValueKey('home-kpi-trust'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: tile,
      ),
    );
  }
}
