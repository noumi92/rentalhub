import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../widgets/admin_shell.dart';
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
      final records = await sl<AdminPeopleDataSource>().getBlacklistRecords();
      if (mounted) setState(() => _cases = records);
    } catch (_) {
      // Was silently swallowed: a failed load looked exactly like
      // an empty tribunal. Show the error state with a retry instead.
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          ? 'Blacklist tribunal'
          : 'National Rental Fraud & Blacklist Tribunal',
      subtitle: 'Central arbitration bench for inter-showroom disputes',
      onRefresh: _loadTribunalCases,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: 'Could not load the blacklist cases.',
                  onRetry: _loadTribunalCases,
                )
              : _cases.isEmpty
                  ? const AppEmptyState(
                      title: 'No blacklist cases',
                      message: 'Tribunal records will appear here.',
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._cases.map((c) => _caseCard(c, compact)),
                        ],
                      ),
                    ),
    );
  }

  Widget _caseCard(AdminBlacklistRecord record, bool compact) {
    final item = record.entity;
    // Raw Colors.red / successTextFor (#10B981, 2.54:1) as 10px text
    // failed contrast; the shared tones are the dark, AA-passing ones.
    final tone = item.isActive ? AdminStatusTone.danger : AdminStatusTone.success;
    final toneColor = adminStatusColor(context, tone);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.isActive ? 'ACTIVE BLACKLIST' : 'REVERSED / CLEARED',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: toneColor),
      ),
    );
    final idLine = Row(
      children: [
        Icon(item.isActive ? Icons.gavel_rounded : Icons.check_circle_rounded, color: toneColor, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text('${item.blacklistId} • CNIC: ${item.cnicNumber}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
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
          Text('Reason: ${item.reasonCategory}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(item.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('Reported by Showroom: ${item.reportedByShopId}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (!item.isActive && item.revertedReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
              child: Text('Reversal Justification: ${item.revertedReason}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
          if (item.isActive) ...[
            const Divider(height: 20),
            if (compact)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showReversalDialog(record),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successTextFor(Theme.of(context).brightness),
                      minimumSize: const Size(0, 48)),
                  child: const Text('Decide appeal — Keep or Remove', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showReversalDialog(record),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.successTextFor(Theme.of(context).brightness),
                        minimumSize: const Size(0, 48)),
                    child: const Text('Decide appeal — Keep or Remove', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
                  ),
                ],
              ),
          ],
          if (record.appealStatus != 'none') ...[
            const SizedBox(height: 8),
            Text('Appeal: ${record.appealStatus} — ${record.appealReason}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
