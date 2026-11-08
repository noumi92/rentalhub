import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../widgets/blacklist_appeal_dialog.dart';
import '../widgets/admin_desktop_header.dart';
import '../widgets/admin_sidebar_nav.dart';

class AdminBlacklistTribunalView extends StatefulWidget {
  const AdminBlacklistTribunalView({super.key});

  @override
  State<AdminBlacklistTribunalView> createState() => _AdminBlacklistTribunalViewState();
}

class _AdminBlacklistTribunalViewState extends State<AdminBlacklistTribunalView> {
  List<AdminBlacklistRecord> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTribunalCases();
  }

  Future<void> _loadTribunalCases() async {
    setState(() => _isLoading = true);
    try {
      // Phase C (C2): appeal-aware records — the shared entity does not
      // carry the appeal state, so the people data source wraps it.
      final records = await sl<AdminPeopleDataSource>().getBlacklistRecords();
      if (mounted) setState(() => _cases = records);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Phase A (A6): the sidebar now passes real route paths — navigate
  // through the router instead of pushing the orphaned mock views.
  void _handleNavigation(String route) {
    if (route == RouteNames.adminBlacklist) return;
    context.go(route);
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
    return Scaffold(
      body: Row(
        children: [
          AdminSidebarNav(activeRoute: RouteNames.adminBlacklist, onNavigate: _handleNavigation),
          Expanded(
            child: Column(
              children: [
                const AdminDesktopHeader(
                  title: 'National Rental Fraud & Blacklist Tribunal',
                  subtitle: 'Central Arbitration Bench for Inter-Showroom Citizen Disputes',
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._cases.map((c) => _caseCard(c)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _caseCard(AdminBlacklistRecord record) {
    final item = record.entity;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isActive ? Colors.red.shade300 : Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(item.isActive ? Icons.gavel_rounded : Icons.check_circle_rounded, color: item.isActive ? Colors.red : AppColors.successTextFor(Theme.of(context).brightness), size: 22),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${item.blacklistId} • CNIC: ${item.cnicNumber}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isActive ? Colors.red.withAlpha(20) : AppColors.accentSuccess.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isActive ? 'ACTIVE BLACKLIST' : 'REVERSED / CLEARED',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: item.isActive ? Colors.red : AppColors.successTextFor(Theme.of(context).brightness)),
                ),
              ),
            ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showReversalDialog(record),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.successTextFor(Theme.of(context).brightness)),
                  child: const Text('Decide appeal — Keep or Remove', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
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

