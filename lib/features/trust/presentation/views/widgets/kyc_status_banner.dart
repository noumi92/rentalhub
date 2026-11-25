import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import 'kyc_status_style.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final rejected = status == 'rejected';
    // One shared mapping (KycStatusStyle) — the Home card and the
    // hub header use the same label/colour/icon for this status.
    final color = KycStatusStyle.color(brightness, status);
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
                KycStatusStyle.icon(status),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.kycStatus(KycStatusStyle.label(l10n, status)),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
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
