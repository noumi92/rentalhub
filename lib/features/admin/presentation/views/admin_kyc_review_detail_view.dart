import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_kyc_data_source.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_shell.dart';
import '../widgets/kyc_review_detail_body.dart';
import '../widgets/kyc_review_document_tile.dart';

/// Item 6 — one customer KYC submission under review (the state half;
/// the presentation lives in [KycReviewDetailBody]): the CNIC
/// front/back and license images (the stored keys point at cPanel
/// `kyc` files and are resolved to signed media URLs, the same way
/// the owner KYC uploader resolves them), the CNIC number, and the
/// submission date — then Approve, or Reject with a mandatory reason
/// the customer sees in their KYC banner. Both decisions are
/// audit-logged by the data source.
///
/// The CNIC back-QR number is shown ONLY to a super admin: it lives
/// in the restricted `customer_qr_codes/{customerId}` doc, the rules
/// deny the read for anyone else, and this view never even requests
/// it for other roles — the same rule as the admin customer detail
/// screen.
class AdminKycReviewDetailView extends StatefulWidget {
  const AdminKycReviewDetailView({
    super.key,
    required this.customerId,
    this.loadSubmission,
    this.resolveAdminRole,
    this.loadQrCode,
    this.resolveImageUrl,
    this.decideKyc,
  });

  final String customerId;

  /// Test seams (data access). Defaults read the real data sources
  /// and session; tests pass fakes so no Firebase/DI is needed.
  final Future<KycReviewSubmission?> Function(String customerId)?
      loadSubmission;
  final Future<String?> Function()? resolveAdminRole;
  final Future<String?> Function(String customerId)? loadQrCode;
  final String Function(String key, String customerId)? resolveImageUrl;
  final Future<bool> Function({
    required String customerId,
    required String decision,
    required String reason,
  })? decideKyc;

  @override
  State<AdminKycReviewDetailView> createState() =>
      _AdminKycReviewDetailViewState();
}

class _AdminKycReviewDetailViewState
    extends State<AdminKycReviewDetailView> {
  final _reasonController = TextEditingController();
  KycReviewSubmission? _submission;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWorking = false;
  bool _canReview = false;
  bool _isSuperAdmin = false;
  String? _qrCode;

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

  static Future<String?> _defaultResolveRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await AdminSession.resolveAdminRole(user);
    } catch (_) {
      return null;
    }
  }

  String _defaultImageUrl(String key, String customerId) {
    try {
      return kycReviewImageUrl(
          key, sl<CPanelStorageClient>(), customerId);
    } catch (_) {
      return key.startsWith('http') ? key : '';
    }
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    final role = await (widget.resolveAdminRole?.call() ??
        _defaultResolveRole());
    if (!mounted) return;
    final canReview =
        AdminPermissions.can(role, AdminPermission.decideKyc);
    setState(() => _canReview = canReview);
    if (!canReview) {
      setState(() => _isLoading = false);
      return;
    }
    KycReviewSubmission? submission;
    try {
      submission = await (widget.loadSubmission?.call(widget.customerId) ??
          sl<AdminKycDataSource>().getKycSubmission(widget.customerId));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _submission = submission;
      _isLoading = false;
    });
    if (submission == null) return;
    // The QR number is requested ONLY for a super admin — the rules
    // would deny the read for anyone else, so it is not attempted.
    final isSuperAdmin = role == AdminPermissions.superAdmin;
    final qrCode = isSuperAdmin
        ? await (widget.loadQrCode?.call(widget.customerId) ??
            sl<AdminPeopleDataSource>()
                .getCustomerQrCode(widget.customerId))
        : null;
    if (!mounted) return;
    setState(() {
      _isSuperAdmin = isSuperAdmin;
      _qrCode = qrCode;
    });
  }

  Future<void> _decide(String decision) async {
    final reason = _reasonController.text.trim();
    if (decision == 'rejected' && reason.isEmpty) {
      AppFeedback.showError(
          context,
          AppLocalizations.of(context)?.adminKycReviewReasonRequired ??
              'A reason is required to reject — the customer sees it.');
      return;
    }
    setState(() => _isWorking = true);
    final synced = await (widget.decideKyc?.call(
            customerId: widget.customerId,
            decision: decision,
            reason: reason) ??
        sl<AdminKycDataSource>().decideKyc(
            customerId: widget.customerId,
            decision: decision,
            reason: reason));
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
          context,
          AppLocalizations.of(context)?.adminKycReviewDecisionSaved ??
              'Decision saved.');
      context.go(RouteNames.adminKycReview);
    } else {
      AppFeedback.showError(
          context,
          AppLocalizations.of(context)?.adminKycReviewDecisionFailed ??
              'Could not reach the server — try again.');
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submission = _submission;
    return AdminShell(
      activeRoute: RouteNames.adminKycReview,
      title: l10n?.adminKycReviewTitle ?? 'KYC Review',
      subtitle: l10n?.adminKycReviewSubtitle ??
          'Customer identity documents waiting for a decision',
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminKycReview),
      child: _isLoading
          ? const AppLoadingState()
          : !_canReview
              ? AppEmptyState(
                  title: l10n?.adminKycReviewNotPermitted ??
                      'Only super admins and operations can review KYC',
                  message: l10n?.adminKycReviewNotPermittedHint ??
                      'Ask a super admin or operations admin to review this submission.',
                  icon: Icons.lock_rounded,
                )
              : _hasError
                  ? AppErrorState(
                      message: l10n?.adminKycReviewLoadFailed ??
                          'Could not load the KYC queue.',
                      onRetry: _load,
                    )
                  : submission == null
                      ? AppEmptyState(
                          title: l10n?.adminKycReviewNotFound ??
                              'Submission not found.')
                      : KycReviewDetailBody(
                          submission: submission,
                          isSuperAdmin: _isSuperAdmin,
                          qrCode: _qrCode,
                          resolveImageUrl:
                              widget.resolveImageUrl ?? _defaultImageUrl,
                          reasonController: _reasonController,
                          isWorking: _isWorking,
                          onDecide: _decide,
                        ),
    );
  }
}
