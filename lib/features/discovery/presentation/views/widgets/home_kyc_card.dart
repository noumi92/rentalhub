import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trust/domain/entities/kyc_document_entity.dart';

/// Customer rework (Worker C): the Home KYC card — the customer's
/// real KYC state from `kyc_documents/{uid}`. The progress counts the
/// documents actually on the submission (CNIC number, CNIC front,
/// CNIC back, licence); the CTA always opens the real KYC flow
/// ([RouteNames.customerKyc]). Nothing here claims NADRA
/// verification — only the state of the customer's own submission.
class HomeKycCard extends StatelessWidget {
  const HomeKycCard({super.key, required this.kyc});

  /// Null when the customer has not submitted anything yet.
  final KycDocumentEntity? kyc;

  static const int _totalDocuments = 4;

  int get _documentsReady {
    final doc = kyc;
    if (doc == null) return 0;
    var ready = 0;
    if (doc.cnicNumber.isNotEmpty) ready++;
    if (doc.cnicFrontKey.isNotEmpty) ready++;
    if (doc.cnicBackKey.isNotEmpty) ready++;
    if (doc.licenseKey.isNotEmpty) ready++;
    return ready;
  }

  String _statusLabel(AppLocalizations l10n) {
    final doc = kyc;
    if (doc == null) return l10n.home2_kycNotStarted;
    switch (doc.status) {
      case 'verified':
        return l10n.verified;
      case 'rejected':
        return l10n.kycStatusRejected;
      default:
        return l10n.kycStatusSubmitted;
    }
  }

  Color _statusColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final doc = kyc;
    if (doc == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    switch (doc.status) {
      case 'verified':
        return AppColors.successTextFor(brightness);
      case 'rejected':
        return AppColors.dangerTextFor(brightness);
      default:
        return AppColors.warningTextFor(brightness);
    }
  }

  IconData get _statusIcon {
    final doc = kyc;
    if (doc == null) return Icons.badge_outlined;
    switch (doc.status) {
      case 'verified':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.error_outline_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doc = kyc;
    final ready = _documentsReady;
    final needsAction = doc == null || doc.status == 'rejected';
    return Card(
      // Customer pass (2026-11-16): the theme Card is the canonical
      // showroom card (surface, 1px hairline, radius 16, elevation
      // 1.5) — no per-file elevation/shape override.
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor(context), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.kycTitle,
                    // At 200% text scale a single long word ('Driving')
                    // is wider than the space left beside the status
                    // chip — ellipsize instead of overflowing.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(l10n),
                      // At 200% text scale the long statuses
                      // ('Submitted — pending verification') are wider
                      // than the space beside the title — shrink and
                      // ellipsize instead of overflowing.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: _statusColor(context),
                              ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ready / _totalDocuments,
                minHeight: 6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.home2_kycProgress(ready, _totalDocuments),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.push(RouteNames.customerKyc),
                child: Text(
                  needsAction ? l10n.kycSubmit : l10n.home2_kycView,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
