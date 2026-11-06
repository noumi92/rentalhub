import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StarRatingBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final int rating;

  /// Null makes the stars read-only — used to show an already
  /// submitted rating (H4, one rating per booking).
  final ValueChanged<int>? onRatingChanged;

  const StarRatingBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.midnightNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              final isFilled = star <= rating;
              return IconButton(
                onPressed: onRatingChanged == null
                    ? null
                    : () => onRatingChanged!(star),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 36,
                  color: isFilled ? AppColors.amberGold : AppColors.border,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

