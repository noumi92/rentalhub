import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CustomerStatsRow extends StatelessWidget {
  final int totalTrips;
  final int activeBookings;
  final double trustScore;

  const CustomerStatsRow({
    super.key,
    required this.totalTrips,
    required this.activeBookings,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'Total Trips',
            value: '$totalTrips',
            icon: Icons.history_rounded,
            color: AppColors.royalNavy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            label: 'Active',
            value: '$activeBookings',
            icon: Icons.directions_car_rounded,
            color: AppColors.sunsetOrange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            label: 'Trust Score',
            value: '${trustScore.toStringAsFixed(1)} ★',
            icon: Icons.verified_user_rounded,
            color: AppColors.emeraldGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
              color: AppColors.midnightNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

