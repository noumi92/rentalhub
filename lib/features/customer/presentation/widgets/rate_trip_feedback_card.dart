import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The optional comment field on the rate-trip screen. Extracted
/// from [CustomerRateTripView] so the view stays under the
/// 250-line cap (rulebook §2.2).
class RateTripFeedbackCard extends StatelessWidget {
  const RateTripFeedbackCard({
    super.key,
    required this.controller,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final bool readOnly;

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
          const Text(
            'Additional Feedback (Optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.midnightNavy,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText:
                  'Share any highlights or suggestions for future renters...',
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }
}
