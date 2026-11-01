import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class RevenueKpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final String changeLabel;
  final IconData icon;
  final Color color;

  const RevenueKpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.changeLabel,
    required this.icon,
    this.color = AppColors.sunsetOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.emeraldGreen),
              const SizedBox(width: 4),
              Text(changeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emeraldGreen)),
            ],
          ),
        ],
      ),
    );
  }
}
