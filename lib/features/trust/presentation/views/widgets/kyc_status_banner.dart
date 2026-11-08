import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// G3: the KYC status banner on the documents screen — the real status
/// of the customer's submission from `kyc_documents/{uid}`.
class KycStatusBanner extends StatelessWidget {
  const KycStatusBanner({super.key, required this.status});

  final String status;

  String _label(AppLocalizations l10n) {
    switch (status) {
      case 'verified':
        return l10n.verified;
      case 'rejected':
        return l10n.kycStatusRejected;
      default:
        return l10n.kycStatusSubmitted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verified = status == 'verified';
    final color = verified
        ? AppColors.successOnContainerFor(Theme.of(context).brightness)
        : AppColors.warningOnContainerFor(Theme.of(context).brightness);
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
              l10n.kycStatus(_label(l10n)),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
