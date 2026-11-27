import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_sort_menu.dart';
import '../widgets/admin_tribunal_case_actions.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/blacklist_appeal_dialog.dart';

class AdminBlacklistTribunalView extends StatefulWidget {
  const AdminBlacklistTribunalView({super.key});

  @override
  State<AdminBlacklistTribunalView> createState() => _AdminBlacklistTribunalViewState();
}

class _AdminBlacklistTribunalViewState extends State<AdminBlacklistTribunalView> {
  List<AdminBlacklistRecord> _cases = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _sort = 'dateNewest';

  @override
  void initState() {
    super.initState();
    _loadTribunalCases();
  }

  Future<void> _loadTribunalCases() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Phase C (C2): appeal-aware records — the shared entity does not
      // carry the appeal state, so the people data source wraps it.
      final records = AdminPeopleDataSource.sortBlacklistRecords(
          await sl<AdminPeopleDataSource>().getBlacklistRecords(), _sort);
      if (mounted) setState(() => _cases = records);
    } catch (_) {
      // Was silently swallowed: a failed load looked exactly like
      // an empty tribunal. Show the error state with a retry instead.
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Phase 3 (3.6a): the tribunal links back to the customer
  // record — the record carries a CNIC, not a customer id, so the
  // customer is resolved by CNIC first. When no customer record
  // matches, the admin is told so instead of opening a dead link.
  Future<void> _viewCustomer(AdminBlacklistRecord record) async {
    final customerId = await sl<AdminPeopleDataSource>()
        .getCustomerIdByCnic(record.entity.cnicNumber);
    if (!mounted) return;
    if (customerId == null) {
      AppFeedback.showError(
          context,
          (AppLocalizations.of(context) ?? AppLocalizationsEn())
              .admin2_tribunalCustomerNotFound);
      return;
    }
    context.go(RouteNames.adminCustomerDetail
        .replaceFirst(':customerId', customerId));
  }

  // Phase C (C2): the appeal decision — Keep or Remove, both with a
  // mandatory reason. Remove goes through the tribunal revert.
  void _showReversalDialog(AdminBlacklistRecord record) {
    showDialog(
      context: context,
      builder: (_) => BlacklistAppealDialog(
        record: record,
        onDecided: _loadTribunalCases,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    // Mobile-first: the shared AdminShell (not the 260dp desktop
    // sidebar this view used to build itself) so the tribunal fits a
    // 360px phone; the shell supplies the navigation drawer on
    // phones (and the 260dp sidebar on desktop).
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminBlacklist,
      // The full tribunal name on desktop (the pre-existing tests
      // and the product copy use it); shortened on phones, where
      // the 41-character title wraps to two lines in the fixed
      // 70dp shared header and overflows at 2.0x text scale.
      title: compact
          ? l10n.admin2_tribunalTitle
          : l10n.admin2_tribunalSubtitle,
      subtitle: l10n.admin2_tribunalSubtitle2,
      onRefresh: _loadTribunalCases,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_tribunalLoadFailed,
                  onRetry: _loadTribunalCases,
                )
              : _cases.isEmpty
                  ? AppEmptyState(
                      title: l10n.admin2_tribunalEmptyTitle,
                      message: l10n.admin2_tribunalEmptyHint,
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AdminSortMenu(
                                options: [
                                  AdminSortOption(
                                      id: 'dateNewest',
                                      label: l10n.adminSortDateNewest),
                                  AdminSortOption(
                                      id: 'dateOldest',
                                      label: l10n.adminSortDateOldest),
                                  AdminSortOption(
                                      id: 'statusAsc',
                                      label: l10n.adminSortStatus),
                                ],
                                selectedId: _sort,
                                onSelected: (sort) {
                                  if (sort == _sort) return;
                                  setState(() => _sort = sort);
                                  _loadTribunalCases();
                                },
                              ),
                            ],
                          ),
                          ..._cases.map((c) => _caseCard(c, compact)),
                        ],
                      ),
                    ),
    );
  }

  Widget _caseCard(AdminBlacklistRecord record, bool compact) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final item = record.entity;
    // Raw Colors.red / successTextFor (#10B981, 2.54:1) as 10px text
    // failed contrast; the shared tones are the dark, AA-passing ones.
    final tone = item.isActive ? AdminStatusTone.danger : AdminStatusTone.success;
    final toneColor = adminStatusColor(context, tone);
    // Phase 4 (4.1) — the status badge is the shared chip
    // (radius 20, 11sp w500); the old inline badge was radius 6 /
    // 10sp with the same tone.
    final badge = AdminStatusChip(
      label: item.isActive
          ? l10n.admin2_tribunalActive
          : l10n.admin2_tribunalReversed,
      tone: tone,
    );
    final idLine = Row(
      children: [
        Icon(item.isActive ? Icons.gavel_rounded : Icons.check_circle_rounded, color: toneColor, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(l10n.admin2_tribunalCaseLine(item.blacklistId, item.cnicNumber), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isActive ? toneColor.withValues(alpha: 0.4) : Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact: badge drops below the id line so the 360px card
          // never squeezes the CNIC text against the badge.
          if (compact) ...[
            idLine,
            const SizedBox(height: 8),
            badge,
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Expanded(child: idLine), badge],
            ),
          const SizedBox(height: 8),
          Text(l10n.admin2_tribunalReason(item.reasonCategory), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(item.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(l10n.admin2_tribunalReportedBy(item.reportedByShopId), style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (!item.isActive && item.revertedReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
              child: Text(l10n.admin2_tribunalReversal(item.revertedReason ?? ''), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
          if (item.isActive) ...[
            const Divider(height: 20),
            // F-m6: "Decide appeal" only when an appeal actually
            // exists (appealStatus 'pending'). With no appeal the
            // same dialog opens as "Review flag" — the revert path
            // stays available, but nothing claims an appeal was
            // filed when it was not.
            AdminTribunalCaseActions(
              record: record,
              compact: compact,
              onViewCustomer: () => _viewCustomer(record),
              onDecideAppeal: () => _showReversalDialog(record),
            ),
          ],
          if (record.appealStatus != 'none') ...[
            const SizedBox(height: 8),
            Text(l10n.admin2_tribunalAppealLine(record.appealStatus, record.appealReason),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
