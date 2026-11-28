import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_kyc_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_list_card.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_sort_menu.dart';

/// Customer KYC review queue (super admin & operations).
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
  String _sort = 'dateNewest';
  int? _total;

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
      // Phase 3 (3.4): the total comes from the data source's
      // count, so the queue can say "Showing first N of M" at its
      // 100 cap; the test seam has no count, so it reports the
      // loaded rows as the total.
      final pending = AdminKycDataSource.sortKycSubmissions(
          await (widget.loadQueue?.call() ??
              sl<AdminKycDataSource>().getPendingKycSubmissions()),
          _sort);
      final total = widget.loadQueue != null
          ? pending.length
          : await sl<AdminKycDataSource>().countPendingKyc();
      if (mounted) {
        setState(() {
          _pending = pending;
          _total = total;
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
      subTabs: AdminSectionTabs.onlineCustomers(
        context,
        activeRoute: RouteNames.adminKycReview,
        canDecideKyc: _canReview,
      ),
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
                      : Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(
                                  windowSizeClassOf(context) ==
                                          WindowSizeClass.compact
                                      ? 16
                                      : 24),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AdminSortMenu(
                                        options: [
                                          AdminSortOption(
                                              id: 'dateNewest',
                                              label: l10n?.adminSortDateNewest ??
                                                  'Newest first'),
                                          AdminSortOption(
                                              id: 'dateOldest',
                                              label: l10n?.adminSortDateOldest ??
                                                  'Oldest first'),
                                          AdminSortOption(
                                              id: 'nameAsc',
                                              label: l10n?.adminSortNameAsc ??
                                                  'Name A–Z'),
                                          AdminSortOption(
                                              id: 'nameDesc',
                                              label: l10n?.adminSortNameDesc ??
                                                  'Name Z–A'),
                                        ],
                                        selectedId: _sort,
                                        onSelected: (sort) => setState(
                                            () => _sort = sort),
                                      ),
                                    ],
                                  ),
                                  AdminCountLine(
                                      shown: _pending.length, total: _total),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                          // Mobile-first: 16dp on a phone, 24dp on desktop.
                          padding: EdgeInsets.fromLTRB(
                              windowSizeClassOf(context) ==
                                      WindowSizeClass.compact
                                  ? 16
                                  : 24,
                              0,
                              windowSizeClassOf(context) ==
                                      WindowSizeClass.compact
                                  ? 16
                                  : 24,
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
                            // Phase 4 (4.1) — the shared [AdminListCard]
                            // shell.
                            return AdminListCard(
                              icon: Icons.badge_rounded,
                              title: name,
                              subtitle:
                                  'CNIC ${submission.cnicNumber.isEmpty ? '—' : submission.cnicNumber}'
                                  '${date.isEmpty ? '' : ' • $date'}',
                              trailing: adminListChevron,
                              onTap: () => context.go(
                                RouteNames.adminKycReviewDetail
                                    .replaceFirst(':customerId',
                                        submission.customerId),
                              ),
                            );
                          },
                              ),
                            ),
                          ],
                        ),
    );
  }
}
