import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              final isFilled = star <= rating;
              return IconButton(
                tooltip: l10n.rateStarLabel(star),
                onPressed: onRatingChanged == null
                    ? null
                    : () => onRatingChanged!(star),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 36,
                  color: isFilled
                      ? AppColors.warning
                      // §16: dividerColor (#23274D in dark) made
                      // unfilled stars nearly invisible in dark mode.
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
