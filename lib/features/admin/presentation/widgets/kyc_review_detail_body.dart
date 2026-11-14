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
  });

  final KycReviewSubmission submission;
  final bool isSuperAdmin;
  final String? qrCode;
  final String Function(String key, String customerId) resolveImageUrl;
  final TextEditingController reasonController;
  final bool isWorking;

  /// 'verified' to approve, 'rejected' to reject.
  final Future<void> Function(String decision) onDecide;

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
          const SizedBox(height: 16),
          // Mobile-first: the two decisions stack full-width on a
          // phone — side by side each is ~160dp and "Reject" wraps.
          // 48dp touch targets.
          if (windowSizeClassOf(context) == WindowSizeClass.compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _approveButton(l10n),
                const SizedBox(height: 8),
                _rejectButton(l10n),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _approveButton(l10n)),
                const SizedBox(width: 8),
                Expanded(child: _rejectButton(l10n)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _approveButton(AppLocalizations? l10n) => FilledButton(
        onPressed: isWorking ? null : () => onDecide('verified'),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        child: Text(l10n?.adminKycReviewApprove ?? 'Approve'),
      );

  Widget _rejectButton(AppLocalizations? l10n) => OutlinedButton(
        onPressed: isWorking ? null : () => onDecide('rejected'),
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            minimumSize: const Size(0, 48)),
        child: Text(l10n?.adminKycReviewReject ?? 'Reject'),
      );
}
