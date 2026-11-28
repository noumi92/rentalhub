import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/signature_profile_service.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../core/widgets/profile_signature_card.dart';
import '../../cubit/kyc_cubit.dart';
import '../../../domain/entities/kyc_document_entity.dart';
import 'kyc_status_banner.dart';
import 'kyc_submission_form.dart';
import '../../../../../l10n/app_localizations.dart';

/// The documents/KYC content, shared by the standalone
/// [CustomerDocumentsView] and the profile hub's KYC tab.
///
/// State machine (Profile hub, 2026-11-25):
/// * no record / rejected / submitted — the submission form, as
///   before (a pending submission can still be corrected);
/// * verified — a read-only summary of the documents on file plus an
///   explicit "Update documents" action. Re-submitting from there
///   becomes 'resubmitted', never 'submitted', and keeps the stored
///   file keys (see KycRemoteDataSource);
/// * resubmitted — the updated submission is already in review, so
///   the summary shows and the form stays hidden until the admin
///   decides.
class KycDocumentsPanel extends StatefulWidget {
  const KycDocumentsPanel({
    super.key,
    required this.existing,
    required this.initialCnic,
    required this.rejectionReason,
    required this.loading,
    required this.signedOut,
    required this.userUid,
    required this.onSubmitted,
    required this.onRetry,
  });

  final KycDocumentEntity? existing;
  final String initialCnic;
  final String? rejectionReason;
  final bool loading;
  final bool signedOut;
  final String userUid;
  final void Function(String cnic) onSubmitted;
  final VoidCallback onRetry;

  @override
  State<KycDocumentsPanel> createState() => _KycDocumentsPanelState();
}

class _KycDocumentsPanelState extends State<KycDocumentsPanel> {
  /// Verified users only see the form after explicitly choosing to
  /// update their documents.
  bool _updating = false;

  @override
  void didUpdateWidget(KycDocumentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh submission landed (status moved to submitted /
    // resubmitted): back to the summary, the form must not linger.
    if (widget.existing?.status != oldWidget.existing?.status) {
      _updating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.loading) return const AppLoadingState();
    if (widget.signedOut) {
      return AppErrorState(
        message: l10n.signInRequiredGeneric,
        onRetry: widget.onRetry,
      );
    }
    final existing = widget.existing;
    final status = existing?.status ?? '';
    final showForm = existing == null ||
        status == 'rejected' ||
        status == 'submitted' ||
        _updating;
    return BlocProvider.value(
      value: sl<KycCubit>(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (existing != null) ...[
            KycStatusBanner(
              status: status,
              rejectionReason: widget.rejectionReason,
            ),
            const SizedBox(height: 14),
          ],
          if (showForm)
            KycSubmissionForm(
              initialCnic: widget.initialCnic,
              existing: existing,
              userUid: widget.userUid,
              onSubmitted: widget.onSubmitted,
            )
          else ...[
            Text(
              l10n.kycDocumentsOnFile,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _StoredDocRow(
              label: l10n.kycCnicFront,
              // The else-branch only runs with a record (showForm is
              // false), so the analyzer promotes `existing` here.
              present: existing.cnicFrontKey.isNotEmpty,
            ),
            _StoredDocRow(
              label: l10n.kycCnicBack,
              present: existing.cnicBackKey.isNotEmpty,
            ),
            if (existing.licenseKey.isNotEmpty ||
                existing.licenseNumber.isNotEmpty)
              _StoredDocRow(
                label: l10n.kycLicense,
                present: true,
              ),
            if (status == 'verified') ...[
              const SizedBox(height: 12),
              Text(
                l10n.kycVerifiedUpdateIntro,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _updating = true),
                  icon: const Icon(Icons.edit_document, size: 18),
                  label: Text(l10n.kycUpdateDocuments),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          ProfileSignatureCard(
            key: ValueKey('online_customer_kyc_sig_${widget.userUid}'),
            title: l10n.handoverCustomerSignature,
            onLoad: () async =>
                (await SignatureProfileService.loadCustomerSignature(
                        widget.userUid))
                    .pngBytes,
            onSave: (bytes) => SignatureProfileService.saveCustomerSignature(
              widget.userUid,
              bytes,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoredDocRow extends StatelessWidget {
  const _StoredDocRow({required this.label, required this.present});

  final String label;
  final bool present;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            present ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: present
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
