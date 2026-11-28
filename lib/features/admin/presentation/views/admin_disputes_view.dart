import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_booking_kpis_banner.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_list_card.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_sort_menu.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/dispute_decision_panel.dart';

/// Phase D (D2) — the disputes centre: every dispute with its 72 h
/// SLA state. Tap one for its detail route (both statements, the
/// Full / Partial / Full-to-owner decision, the amount, the note).
class AdminDisputesView extends StatefulWidget {
  const AdminDisputesView({super.key});

  @override
  State<AdminDisputesView> createState() => _AdminDisputesViewState();
}

class _AdminDisputesViewState extends State<AdminDisputesView> {
  List<DisputeRecord> _disputes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all';
  String _sort = AdminListSort.dateNewest;
  int? _total;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final ds = sl<AdminPlatformDataSource>();
      final disputes = AdminPlatformDataSource.sortDisputes(
          await ds.getDisputes(status: _filter), _sort);
      final total = await ds.countDisputes(status: _filter);
      if (mounted) {
        setState(() {
          _disputes = disputes;
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

  void _onSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
  }

  String _slaText(DisputeRecord d) {
    final l10n = AppLocalizations.of(context)!;
    final created = d.createdAt;
    if (created == null) return l10n.admin2_disputesSlaUnknown;
    final left =
        created.add(const Duration(hours: 72)).difference(DateTime.now());
    if (left.isNegative) return l10n.admin2_disputesSlaOverdue(-left.inHours);
    return l10n.admin2_disputesSlaLeft(left.inHours);
  }

  /// F-m14: the triage step — moves an open dispute to `in_review`.
  /// Phase 1 (1.1): it used to fire on one tap — confirm first.
  Future<void> _markInReview(DisputeRecord d) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAdminConfirmDialog(
      context,
      title: l10n?.disputeMarkInReviewConfirmTitle ??
          'Mark this dispute in review?',
      body: l10n?.disputeMarkInReviewConfirmBody ??
          'The dispute will move to In review so a decision can be recorded.',
    );
    if (!confirmed) return;
    if (!mounted) return;
    final ok = await sl<AdminPlatformDataSource>()
        .markDisputeInReview(disputeId: d.id);
    if (!mounted) return;
    if (ok) {
      AppFeedback.showSuccess(
          context, l10n?.disputeMarkedInReview ?? 'Marked in review.');
      _load();
    } else {
      AppFeedback.showError(context,
          l10n?.disputeMarkInReviewFailed ?? 'Could not mark the dispute in review.');
    }
  }

  /// F-M9/AD-M10: what a resolved row says about its decision, so
  /// the outcome is visible without opening the row.
  String _decisionLine(DisputeRecord d) {
    if (d.status != 'resolved' || d.decision == null) return '';
    final l10n = AppLocalizations.of(context)!;
    final amount = d.decisionAmount;
    final amountText = amount == null
        ? ''
        : ' — ${l10n.amountRs(formatRs(amount))}';
    return ' • ${l10n.admin2_disputesDecidedLine(disputeDecisionLabel(d.decision!, l10n))}$amountText';
  }

  void _openDispute(DisputeRecord d) {
    context.go(RouteNames.adminDisputeDetail.replaceFirst(':disputeId', d.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminDisputes,
      title: l10n.admin2_disputesTitle,
      subtitle: l10n.admin2_disputesSubtitle,
      subTabs: AdminSectionTabs.bookings(
        context,
        activeRoute: RouteNames.adminDisputes,
      ),
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            const AdminBookingKpisBanner(),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in {
                    'all': l10n.filterAll,
                    'open': l10n.admin2_open,
                    'in_review': l10n.inReview,
                    'resolved': l10n.admin2_resolved,
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) {
                        setState(() {
                          _filter = entry.key;
                          _isLoading = true;
                        });
                        _load();
                      },
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminSortMenu(
                  options: [
                    AdminSortOption(
                        id: AdminListSort.dateNewest,
                        label: l10n.adminSortDateNewest),
                    AdminSortOption(
                        id: AdminListSort.dateOldest,
                        label: l10n.adminSortDateOldest),
                    AdminSortOption(
                        id: AdminListSort.statusAsc,
                        label: l10n.adminSortStatus),
                  ],
                  selectedId: _sort,
                  onSelected: _onSort,
                ),
              ],
            ),
            SizedBox(height: 16),
            if (!_isLoading && !_hasError && _disputes.isNotEmpty)
              AdminCountLine(shown: _disputes.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_disputesLoadFailed,
                          onRetry: _load,
                        )
                      : _disputes.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_disputesEmptyTitle,
                              message: l10n.admin2_disputesEmptyHint,
                            )
                          : ListView.separated(
                          itemCount: _disputes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = _disputes[i];
                            // Phase 4 (4.1) — the shared [AdminListCard]
                            // shell (the triage button stays in the
                            // trailing row, beside the chevron).
                            return AdminListCard(
                              icon: Icons.gavel_rounded,
                              title: '${d.category} • ${d.bookingId}',
                              subtitle:
                                  '${d.description} — ${humanizeStatus(d.status, l10n)} • ${_slaText(d)}${_decisionLine(d)}',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (d.status == 'open')
                                    IconButton(
                                      tooltip:
                                          AppLocalizations.of(context)
                                                  ?.disputeMarkInReview ??
                                              'Mark in review',
                                      icon: const Icon(
                                          Icons.rate_review_rounded,
                                          size: 20),
                                      onPressed: () => _markInReview(d),
                                    ),
                                  adminListChevron,
                                ],
                              ),
                              onTap: () => _openDispute(d),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
