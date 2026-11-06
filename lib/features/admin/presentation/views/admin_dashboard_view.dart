import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/admin_shell.dart';

/// Phase A (A6) — the admin dashboard, real: live counts from the
/// platform collections. No growth percentages, no volume figures, no
/// MRR — those need history and the gated subscription phase, and the
/// old view invented all of them ("Rs. 4.82M, +22.8% MoM").
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  PlatformStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await sl<AdminRemoteDataSource>().getPlatformStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: RouteNames.adminDashboard,
      title: 'Dashboard',
      subtitle: 'The platform at a glance, counted live',
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth >= 900 ? 4 : 2;
                      final width = (constraints.maxWidth -
                              (columns - 1) * 16) /
                          columns;
                      final cards = _cards();
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: cards
                            .map((c) => SizedBox(width: width, child: c))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _infoCard(
                    'Open disputes need a decision',
                    '${_stats?.openDisputeCount ?? 0} open',
                    Icons.report_problem_outlined,
                    'The disputes centre arrives in Phase D.',
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    'Support tickets waiting',
                    '${_stats?.openTicketCount ?? 0} open',
                    Icons.support_agent_rounded,
                    'The tickets inbox arrives in Phase E.',
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _cards() {
    final s = _stats ??
        const PlatformStats(
          shopCount: 0,
          activeBookingCount: 0,
          openDisputeCount: 0,
          openTicketCount: 0,
        );
    return [
      AdminKpiCard(
        title: 'Registered shops',
        value: '${s.shopCount}',
        changeLabel: 'Live count',
        icon: Icons.store_rounded,
      ),
      AdminKpiCard(
        title: 'Active bookings',
        value: '${s.activeBookingCount}',
        changeLabel: 'Approved, paid or active',
        icon: Icons.calendar_month_rounded,
        accentColor: AppColors.emeraldGreen,
      ),
      AdminKpiCard(
        title: 'Open disputes',
        value: '${s.openDisputeCount}',
        changeLabel: 'Awaiting a decision',
        icon: Icons.report_problem_outlined,
        accentColor: Colors.amber.shade800,
      ),
      AdminKpiCard(
        title: 'Open support tickets',
        value: '${s.openTicketCount}',
        changeLabel: 'Awaiting a reply',
        icon: Icons.support_agent_rounded,
        accentColor: Colors.blue.shade700,
      ),
    ];
  }

  /// An informational card, not a link: the disputes centre (Phase D)
  /// and the tickets inbox (Phase E) are not built yet, so the counts
  /// are shown with an honest note instead of a misleading destination.
  Widget _infoCard(
      String title, String value, IconData icon, String note) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.royalNavy),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy)),
        subtitle: Text('$value • $note',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ),
    );
  }
}
