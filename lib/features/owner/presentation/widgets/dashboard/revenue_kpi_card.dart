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
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.accentSuccess),
              const SizedBox(width: 4),
              Expanded(
                child: Text(changeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.successTextFor(Theme.of(context).brightness))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

