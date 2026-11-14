import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_kyc_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_shell.dart';

/// Item 6 — the customer KYC review queue: every customer whose own
/// documents sit in `kyc_documents/{uid}` with status 'submitted',
/// newest first, with the review detail that decides them.
///
/// Permission: super admin + operations only ([AdminPermission.
/// decideKyc] — the matrix already carried this KYC permission for
/// the owner-side flow; no new permission was needed). Support
/// admins never see the sidebar entry, the route guard bounces a
/// direct URL to the dashboard, and this view itself shows the
/// not-permitted state as the backstop.
class AdminKycReviewView extends StatefulWidget {
  const AdminKycReviewView({
    super.key,
    this.loadQueue,
    this.resolveAdminRole,
  });

  /// Test seams (data access). Defaults read the real data source
  /// and session; tests pass fakes so no Firebase/DI is needed.
  final Future<List<KycReviewSubmission>> Function()? loadQueue;
  final Future<String?> Function()? resolveAdminRole;

  @override
  State<AdminKycReviewView> createState() => _AdminKycReviewViewState();
}

class _AdminKycReviewViewState extends State<AdminKycReviewView> {
  List<KycReviewSubmission> _pending = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    _load();
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
    try {
      final pending = await (widget.loadQueue?.call() ??
          sl<AdminKycDataSource>().getPendingKycSubmissions());
      if (mounted) {
        setState(() {
          _pending = pending;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminKycReview,
      title: l10n?.adminKycReviewTitle ?? 'KYC Review',
      subtitle: l10n?.adminKycReviewSubtitle ??
          'Customer identity documents waiting for a decision',
      onRefresh: _load,
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
                  : _pending.isEmpty
                      ? AppEmptyState(
                          title: l10n?.adminKycReviewEmpty ??
                              'No pending KYC submissions',
                          message: l10n?.adminKycReviewEmptyHint ??
                              'Every customer submission has been decided.',
                        )
                      : ListView.separated(
                          // Mobile-first: 16dp on a phone, 24dp on desktop.
                          padding: EdgeInsets.all(
                              windowSizeClassOf(context) ==
                                      WindowSizeClass.compact
                                  ? 16
                                  : 24),
                          itemCount: _pending.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final submission = _pending[i];
                            final name = submission.customerName.isEmpty
                                ? submission.customerId
                                : submission.customerName;
                            final date =
                                _formatDate(context, submission.submittedAt);
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: const Icon(Icons.badge_rounded),
                                ),
                                title: Text(name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  'CNIC ${submission.cnicNumber.isEmpty ? '—' : submission.cnicNumber}'
                                  '${date.isEmpty ? '' : ' • $date'}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16),
                                onTap: () => context.go(
                                  RouteNames.adminKycReviewDetail
                                      .replaceFirst(':customerId',
                                          submission.customerId),
                                ),
                              ),
                            );
                          },
                        ),
    );
  }
}
