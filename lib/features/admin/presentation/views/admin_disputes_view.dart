import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/dispute_decision_sheet.dart';

/// Phase D (D2) — the disputes centre: every dispute with its 72 h
/// SLA state. Tap one for the decision sheet (both statements, the
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final disputes = await sl<AdminPlatformDataSource>()
          .getDisputes(status: _filter);
      if (mounted) {
        setState(() {
          _disputes = disputes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
  Future<void> _markInReview(DisputeRecord d) async {
    final l10n = AppLocalizations.of(context);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DisputeDecisionSheet(
        dispute: d,
        onDecided: _load,
        // AD-M10: resolved rows open read-only — the decision sheet
        // is the way back into a decided dispute.
        readOnly: d.status == 'resolved',
      ),
    );
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
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
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
            SizedBox(height: 16),
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
                                  child: const Icon(Icons.gavel_rounded,
                                      ),
                                ),
                                title: Text(
                                    '${d.category} • ${d.bookingId}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        )),
                                subtitle: Text(
                                  '${d.description} — ${humanizeStatus(d.status, l10n)} • ${_slaText(d)}${_decisionLine(d)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
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
                                    const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16),
                                  ],
                                ),
                                onTap: () => _openDispute(d),
                              ),
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
