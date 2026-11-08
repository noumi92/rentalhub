import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(context, 
            label: 'Total Trips',
            value: '$totalTrips',
            icon: Icons.history_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(context, 
            label: 'Active',
            value: '$activeBookings',
            icon: Icons.directions_car_rounded,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(context, 
            label: 'Trust Score',
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
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

