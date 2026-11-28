import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_kyc_data_source.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_qr_code_row.dart';
import '../widgets/kyc_review_document_tile.dart';

/// The presentation half of the KYC review detail: the customer's
/// name, CNIC number and submission date, the CNIC back-QR number
/// (super admin only, via [AdminQrCodeRow]), the license number and
/// expiry, the four document images, and the reason field with the
/// Approve / Reject decisions. State, loading and the decision
/// itself live in [AdminKycReviewDetailView].
/// Phase 4 (4.4a) — the Approve / Reject buttons, shared by the
/// body (when the detail route does not use a sticky bar) and the
/// detail view's sticky action bar. Mobile-first: the two decisions
/// stack full-width on a phone — side by side each is ~160dp and
/// "Reject" wraps. 48dp touch targets.
class KycDecisionButtons extends StatelessWidget {
  const KycDecisionButtons({
    super.key,
    required this.isWorking,
    required this.onDecide,
    this.approveDisabled = false,
  });

  final bool isWorking;
  final bool approveDisabled;

  /// 'verified' to approve, 'rejected' to reject.
  final Future<void> Function(String decision) onDecide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    Widget approveButton() => FilledButton(
          onPressed: (isWorking || approveDisabled)
              ? null
              : () => onDecide('verified'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(approveDisabled
              ? (l10n?.adminKycAlreadyApproved ?? 'Approved')
              : (l10n?.adminKycReviewApprove ?? 'Approve')),
        );
    Widget rejectButton() => OutlinedButton(
          onPressed: isWorking ? null : () => onDecide('rejected'),
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              minimumSize: const Size(0, 48)),
          child: Text(l10n?.adminKycReviewReject ?? 'Reject'),
        );
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          approveButton(),
          const SizedBox(height: 8),
          rejectButton(),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: approveButton()),
        const SizedBox(width: 8),
        Expanded(child: rejectButton()),
      ],
    );
  }
}

class KycReviewDetailBody extends StatelessWidget {
  const KycReviewDetailBody({
    super.key,
    required this.submission,
    required this.isSuperAdmin,
    required this.qrCode,
    required this.resolveImageUrl,
    required this.reasonController,
    required this.isWorking,
    required this.onDecide,
    this.showActions = true,
  });

  final KycReviewSubmission submission;
  final bool isSuperAdmin;
  final String? qrCode;
  final String Function(String key, String customerId) resolveImageUrl;
  final TextEditingController reasonController;
  final bool isWorking;

  /// 'verified' to approve, 'rejected' to reject.
  final Future<void> Function(String decision) onDecide;

  /// False when the caller renders [KycDecisionButtons] in a
  /// sticky action bar instead (the detail route).
  final bool showActions;

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final noDocument = l10n?.customerDetailNoDocument ?? 'Not provided';
    final date = _formatDate(context, submission.submittedAt);
    final approvedDate = _formatDate(context, submission.reviewedAt);
    return SingleChildScrollView(
      padding: EdgeInsets.all(
          windowSizeClassOf(context) == WindowSizeClass.compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              submission.customerName.isEmpty
                  ? submission.customerId
                  : submission.customerName,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              '${l10n?.adminKycReviewCnicNumber ?? 'CNIC number'}: ${submission.cnicNumber.isEmpty ? '—' : submission.cnicNumber}'
              '${date.isEmpty ? '' : ' • ${l10n?.adminKycReviewSubmittedOn ?? 'Submitted on'} $date'}',
              style: const TextStyle(fontSize: 13)),
          if (submission.isApproved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(90)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    approvedDate.isEmpty
                        ? (l10n?.adminKycAlreadyApproved ?? 'Approved')
                        : (l10n?.adminKycApprovedOn(approvedDate) ??
                            'Approved on $approvedDate'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
          AdminQrCodeRow(isSuperAdmin: isSuperAdmin, qrCode: qrCode),
          const SizedBox(height: 16),
          AdminDetailSection(
              title: l10n?.adminKycReviewLicenseNumber ?? 'License number',
              lines: [
                submission.licenseNumber.isEmpty
                    ? '—'
                    : submission.licenseNumber
              ]),
          AdminDetailSection(
              title: l10n?.adminKycReviewLicenseExpiry ?? 'License expiry',
              lines: [
                submission.licenseExpiry.isEmpty
                    ? '—'
                    : submission.licenseExpiry
              ]),
          const SizedBox(height: 4),
          Wrap(
            children: [
              KycReviewDocumentTile(
                  label: l10n?.customerDetailCnicFront ?? 'CNIC front',
                  imageUrl: resolveImageUrl(
                      submission.cnicFrontKey, submission.customerId),
                  noDocumentLabel: noDocument),
              KycReviewDocumentTile(
                  label: l10n?.customerDetailCnicBack ?? 'CNIC back',
                  imageUrl: resolveImageUrl(
                      submission.cnicBackKey, submission.customerId),
                  noDocumentLabel: noDocument),
              KycReviewDocumentTile(
                  label: l10n?.customerDetailLicenseFront ?? 'License front',
                  imageUrl: resolveImageUrl(
                      submission.licenseKey, submission.customerId),
                  noDocumentLabel: noDocument),
              KycReviewDocumentTile(
                  label: l10n?.customerDetailLicenseBack ?? 'License back',
                  imageUrl: resolveImageUrl(
                      submission.licenseBackKey, submission.customerId),
                  noDocumentLabel: noDocument),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n?.adminKycReviewReasonLabel ??
                  'Reason (required to reject — the customer sees it)',
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            KycDecisionButtons(
              isWorking: isWorking,
              onDecide: onDecide,
              approveDisabled: submission.isApprovedAndUnchanged,
            ),
          ],
        ],
      ),
    );
  }
}
