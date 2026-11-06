import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// H3: one reputation score bar (label, stars, progress). Extracted
/// from [CustomerReputationView] so the view stays under the
/// 250-line cap.
class ReputationScoreBar extends StatelessWidget {
  const ReputationScoreBar({
    super.key,
    required this.label,
    required this.ratio,
    required this.score,
  });

  final String label;
  final double ratio;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midnightNavy)),
            Text('${score.toStringAsFixed(1)} ★',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sunsetOrange)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.backgroundLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
          ),
        ),
      ],
    );
  }
}
