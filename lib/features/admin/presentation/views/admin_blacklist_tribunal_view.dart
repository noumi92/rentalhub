import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../blacklist/domain/entities/blacklist_entity.dart';
import '../widgets/admin_desktop_header.dart';
import '../widgets/admin_sidebar_nav.dart';
import 'admin_dashboard_view.dart';
import 'admin_shop_accreditation_view.dart';
import 'admin_subscriptions_view.dart';
import 'admin_settings_view.dart';

class AdminBlacklistTribunalView extends StatefulWidget {
  const AdminBlacklistTribunalView({super.key});

  @override
  State<AdminBlacklistTribunalView> createState() => _AdminBlacklistTribunalViewState();
}

class _AdminBlacklistTribunalViewState extends State<AdminBlacklistTribunalView> {
  List<BlacklistEntity> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTribunalCases();
  }

  Future<void> _loadTribunalCases() async {
    setState(() => _isLoading = true);
    try {
      final ds = sl<BlacklistRemoteDataSource>();
      final records = await ds.getAllRecords();
      if (mounted) setState(() => _cases = records);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleNavigation(String route) {
    if (route == 'blacklist') return;
    Widget destination;
    switch (route) {
      case 'dashboard':
        destination = const AdminDashboardView();
        break;
      case 'accreditation':
        destination = const AdminShopAccreditationView();
        break;
      case 'subscriptions':
        destination = const AdminSubscriptionsView();
        break;
      case 'settings':
        destination = const AdminSettingsView();
        break;
      default:
        destination = const AdminDashboardView();
        break;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  void _showReversalDialog(BlacklistEntity item) {
    final justController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tribunal Blacklist Reversal Verdict', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Case: ${item.blacklistId} • CNIC: ${item.cnicNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 10),
            const Text('Mandatory Legal Justification:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: justController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter formal audit settlement / court clearance justification...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldGreen, foregroundColor: Colors.white),
            onPressed: () async {
              if (justController.text.trim().isEmpty) {
                AppFeedback.showError(ctx, 'Mandatory audit justification is strictly required.');
                return;
              }
              Navigator.pop(ctx);
              try {
                final ds = sl<BlacklistRemoteDataSource>();
                await ds.revertBlacklistRecord(
                  blacklistId: item.blacklistId,
                  adminUid: 'super_admin_master',
                  justification: justController.text.trim(),
                );
                await _loadTribunalCases();
                if (mounted) AppFeedback.showSuccess(context, 'Blacklist flag reversed and archived to audit log.');
              } catch (e) {
                if (mounted) AppFeedback.showError(context, 'Reversal failed: $e');
              }
            },
            child: const Text('Authorize Reversal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminSidebarNav(activeRoute: 'blacklist', onNavigate: _handleNavigation),
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

  Widget _caseCard(BlacklistEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.isActive ? Colors.red.shade300 : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item.isActive ? Icons.gavel_rounded : Icons.check_circle_rounded, color: item.isActive ? Colors.red : AppColors.emeraldGreen, size: 22),
                  const SizedBox(width: 8),
                  Text('${item.blacklistId} • CNIC: ${item.cnicNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isActive ? Colors.red.withAlpha(20) : AppColors.emeraldGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isActive ? 'ACTIVE BLACKLIST' : 'REVERSED / CLEARED',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: item.isActive ? Colors.red : AppColors.emeraldGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Reason: ${item.reasonCategory}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.midnightNavy)),
          const SizedBox(height: 4),
          Text(item.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Reported by Showroom: ${item.reportedByShopId}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
          if (!item.isActive && item.revertedReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(6)),
              child: Text('Reversal Justification: ${item.revertedReason}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.midnightNavy)),
            ),
          ],
          if (item.isActive) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showReversalDialog(item),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.emeraldGreen),
                  child: const Text('Reverse Ban with Mandatory Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
