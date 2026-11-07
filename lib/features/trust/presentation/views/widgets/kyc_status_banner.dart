import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// G3: the KYC status banner on the documents screen — the real status
/// of the customer's submission from `kyc_documents/{uid}`.
class KycStatusBanner extends StatelessWidget {
  const KycStatusBanner({super.key, required this.status});

  final String status;

  String get _label {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected — please resubmit';
      default:
        return 'Submitted — pending verification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    final color =
        verified ? AppColors.accentSuccess : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            verified
                ? Icons.verified_rounded
                : Icons.hourglass_top_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'KYC status: $_label',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
