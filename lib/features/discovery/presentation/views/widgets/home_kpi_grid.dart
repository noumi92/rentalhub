import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Customer rework (Worker C): the Home KPI strip — active bookings,
/// total trips, wallet balance and trust score, every value from the
/// real repositories. A value that could not be loaded renders as
/// '—', never an invented number.
///
/// Home redesign (2026-11-24): one horizontal strip of four equal
/// columns with hairline dividers, not the old 2x2 grid — the strip
/// costs a single row of vertical space. Labels are the short forms
/// ('Active', 'Trips', 'Wallet', 'Trust') so each column fits at
/// 360px; values and labels ellipsize instead of overflowing at
/// large text scales. The strip is the canonical card
/// ([AppCardDecoration]) — theme surface, 1px hairline, radius 16 —
/// in both themes, never a hardcoded colour.
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

  /// The trust column opens the reputation screen.
  final VoidCallback? onTrustTap;

  /// CU-m14: the bookings columns open the Bookings tab, the wallet
  /// column the Wallet tab — no column looks tappable without going
  /// anywhere.
  final VoidCallback? onBookingsTap;
  final VoidCallback? onWalletTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dividerColor =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.borderDark
            : AppColors.borderSubtle;
    return Container(
      decoration: AppCardDecoration.of(context),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: _KpiColumn(
              icon: Icons.directions_car_rounded,
              label: l10n.home2_kpiActiveShort,
              value: '$activeBookings',
              onTap: onBookingsTap,
              tileKey: const ValueKey('home-kpi-active'),
            ),
          ),
          _KpiDivider(color: dividerColor),
          Expanded(
            child: _KpiColumn(
              icon: Icons.history_rounded,
              label: l10n.home2_kpiTripsShort,
              value: '$totalTrips',
              onTap: onBookingsTap,
              tileKey: const ValueKey('home-kpi-trips'),
            ),
          ),
          _KpiDivider(color: dividerColor),
          Expanded(
            child: _KpiColumn(
              icon: Icons.account_balance_wallet_rounded,
              label: l10n.walletLabel,
              value: walletTotal == null
                  ? '—'
                  : l10n.amountRs(formatRs(walletTotal!)),
              onTap: onWalletTap,
              tileKey: const ValueKey('home-kpi-wallet'),
            ),
          ),
          _KpiDivider(color: dividerColor),
          Expanded(
            child: _KpiColumn(
              icon: Icons.verified_user_rounded,
              label: l10n.home2_kpiTrustShort,
              value: trustScore == null
                  ? '—'
                  : '${trustScore!.toStringAsFixed(1)} ★',
              onTap: onTrustTap,
              tileKey: const ValueKey('home-kpi-trust'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiDivider extends StatelessWidget {
  const _KpiDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: color);
  }
}

class _KpiColumn extends StatelessWidget {
  const _KpiColumn({
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
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryTextFor(Theme.of(context).brightness),
        ),
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
    );
    final onTap = this.onTap;
    if (onTap == null) return column;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: tileKey ?? const ValueKey('home-kpi-trust'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: column,
      ),
    );
  }
}
