import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_kyc_data_source.dart';
import 'admin_confirm_dialog.dart';
import 'kyc_review_detail_body.dart';
import 'kyc_review_document_tile.dart';

/// Inline Customer KYC Review tab inside [AdminCustomerDetailView] for roles
/// with [AdminPermission.decideKyc] (Super Admin & Operations).
class CustomerDetailKycTab extends StatefulWidget {
  const CustomerDetailKycTab({
    super.key,
    required this.customerId,
    required this.isSuperAdmin,
    required this.qrCode,
    required this.onDecided,
  });

  final String customerId;
  final bool isSuperAdmin;
  final String? qrCode;
  final VoidCallback onDecided;

  @override
  State<CustomerDetailKycTab> createState() => _CustomerDetailKycTabState();
}

class _CustomerDetailKycTabState extends State<CustomerDetailKycTab> {
  final _reasonController = TextEditingController();
  KycReviewSubmission? _submission;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sub =
          await sl<AdminKycDataSource>().getKycSubmission(widget.customerId);
      if (mounted) setState(() { _submission = sub; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _resolveImageUrl(String key, String customerId) {
    try {
      return kycReviewImageUrl(key, sl<CPanelStorageClient>(), customerId);
    } catch (_) {
      return key.startsWith('http') ? key : '';
    }
  }

  Future<void> _decide(String decision) async {
    final l10n = AppLocalizations.of(context);
    final reason = _reasonController.text.trim();
    if (decision == 'rejected' && reason.isEmpty) {
      AppFeedback.showError(
        context,
        l10n?.adminKycReviewReasonRequired ??
            'A reason is required to reject — the customer sees it.',
      );
      return;
    }
    if (decision == 'verified') {
      final ok = await showAdminConfirmDialog(
        context,
        title: l10n?.adminKycReviewApproveConfirmTitle ??
            'Approve this KYC submission?',
        body: l10n?.adminKycReviewApproveConfirmBody ??
            'The customer will be marked verified and can start booking.',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _working = true);
    final synced = await sl<AdminKycDataSource>().decideKyc(
      customerId: widget.customerId,
      decision: decision,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _working = false);
    if (synced) {
      AppFeedback.showSuccess(
        context,
        l10n?.adminKycReviewDecisionSaved ?? 'Decision saved.',
      );
      widget.onDecided();
      _load();
    } else {
      AppFeedback.showError(
        context,
        l10n?.adminKycReviewDecisionFailed ??
            'Could not reach the server — try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) return const AppLoadingState();
    final sub = _submission;
    if (sub == null) {
      return AppEmptyState(
        title: l10n?.adminKycReviewNotFound ?? 'No KYC submission on file.',
        icon: Icons.badge_rounded,
      );
    }
    return KycReviewDetailBody(
      submission: sub,
      isSuperAdmin: widget.isSuperAdmin,
      qrCode: widget.qrCode,
      resolveImageUrl: _resolveImageUrl,
      reasonController: _reasonController,
      isWorking: _working,
      onDecide: _decide,
      showActions: true,
    );
  }
}
