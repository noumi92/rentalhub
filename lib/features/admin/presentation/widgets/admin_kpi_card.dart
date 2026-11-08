import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String changeLabel;
  final IconData icon;
  final Color accentColor;

  const AdminKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.changeLabel,
    required this.icon,
    this.accentColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withAlpha(25),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(changeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.successTextFor(Theme.of(context).brightness))),
        ],
      ),
    );
  }
}
