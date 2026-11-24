import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trust/domain/entities/kyc_document_entity.dart';

/// Customer rework (Worker C): the Home KYC banner — the customer's
/// real KYC state from `kyc_documents/{uid}`. The progress counts the
/// documents actually on the submission (CNIC number, CNIC front,
/// CNIC back, licence); the compact action always opens the real KYC
/// flow ([RouteNames.customerKyc]). Nothing here claims NADRA
/// verification — only the state of the customer's own submission.
///
/// Home redesign (2026-11-24): a slim horizontal banner, not the
/// old tall card with a full-width button — icon + title + status
/// pill on the first line, an orange progress bar with the ready
/// count below it, and a compact "View >" / "Submit >" text button
/// on the right. The solid orange CTA stays reserved for booking a
/// car. Colours are the brightness-aware status tokens in both
/// themes, never a hardcoded hex.
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
    final statusColor = _statusColor(context);
    return Container(
      decoration: AppCardDecoration.of(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(_statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.home2_kycShortTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
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
                                    color: statusColor,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ready / _totalDocuments,
                    minHeight: 4,
                    // The mock's orange progress fill — the token
                    // orange in both themes, never a hardcoded hex.
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.orangeFill),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.home2_kycProgress(ready, _totalDocuments),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.push(RouteNames.customerKyc),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              // CU-M3: 48dp minimum tap target.
              minimumSize: const Size(0, 48),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  needsAction
                      ? l10n.home2_kycSubmitShort
                      : l10n.home2_kycViewShort,
                ),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
