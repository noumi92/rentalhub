import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// G3: the KYC status banner on the documents screen — the real status
/// of the customer's submission from `kyc_documents/{uid}`.
///
/// CU-M10: a rejected KYC must not look like a pending one — it gets
/// the error icon and the danger colour. The admin's rejection reason
/// (stored on the `customers/{uid}` record as `rejectionReason`; no
/// such field exists on the KYC record itself) renders under the
/// banner when present; the submission form below is the upload-again
/// action.
class KycStatusBanner extends StatelessWidget {
  const KycStatusBanner({super.key, required this.status, this.rejectionReason});

  final String status;

  /// The admin's rejection reason from the customer record, if any.
  final String? rejectionReason;

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
    final brightness = Theme.of(context).brightness;
    final verified = status == 'verified';
    final rejected = status == 'rejected';
    final color = verified
        ? AppColors.successOnContainerFor(brightness)
        : rejected
            ? AppColors.dangerTextFor(brightness)
            : AppColors.warningOnContainerFor(brightness);
    final reason = rejectionReason?.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : rejected
                        ? Icons.error_outline_rounded
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
          if (rejected && reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.kycRejectionReason(reason),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
