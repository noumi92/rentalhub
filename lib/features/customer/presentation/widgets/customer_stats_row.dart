import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

class CustomerStatsRow extends StatelessWidget {
  final int totalTrips;
  final int activeBookings;
  // E1: the customer's real trust score from their `users` record.
  // Null when no record exists yet — shown as '—', never invented.
  final double? trustScore;

  const CustomerStatsRow({
    super.key,
    required this.totalTrips,
    required this.activeBookings,
    this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(context, 
            label: l10n.profileTotalTrips,
            value: '$totalTrips',
            icon: Icons.history_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(context, 
            label: l10n.active,
            value: '$activeBookings',
            icon: Icons.directions_car_rounded,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(context, 
            label: l10n.profileTrustScore,
            value: trustScore == null ? '—' : '${trustScore!.toStringAsFixed(1)} ★',
            icon: Icons.verified_user_rounded,
            color: AppColors.successTextFor(Theme.of(context).brightness),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

