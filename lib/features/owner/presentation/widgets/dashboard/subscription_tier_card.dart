import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class SubscriptionTierCard extends StatelessWidget {
  final String title;
  final String price;
  final String billingPeriod;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final VoidCallback onSelect;

  const SubscriptionTierCard({
    super.key,
    required this.title,
    required this.price,
    required this.billingPeriod,
    required this.features,
    this.isCurrent = false,
    this.isPopular = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppColors.secondary : (isCurrent ? AppColors.accentSuccess : Theme.of(context).dividerColor),
          width: isPopular || isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(6)),
                  child: Text('MOST POPULAR', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                )
              else if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.accentSuccess, borderRadius: BorderRadius.circular(6)),
                  child: Text('CURRENT PLAN', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(billingPeriod, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Divider(height: 20),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.successTextFor(Theme.of(context).brightness)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? AppColors.secondary : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isCurrent ? 'Active Plan' : 'Upgrade to $title',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

