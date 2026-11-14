import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';

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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final stats = await sl<AdminRemoteDataSource>().getPlatformStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: 'Could not load the dashboard.',
                  onRetry: _load,
                )
              : SingleChildScrollView(
              // Mobile-first: 16dp side padding on a phone, 24dp on
              // desktop — 24dp each side leaves 312dp of content on
              // a 360dp screen.
              padding: EdgeInsets.all(
                  windowSizeClassOf(context) == WindowSizeClass.compact
                      ? 16
                      : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Two columns on a phone (each ~156dp at 360dp);
                      // four on desktop. The cards wrap their text,
                      // so large text scales grow them, never clip.
                      final columns = columnsFor<int>(context,
                          compact: 2, medium: 2, expanded: 4);
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
                    'Open the disputes centre to decide them.',
                    onTap: () => context.go(RouteNames.adminDisputes),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    'Support tickets waiting',
                    '${_stats?.openTicketCount ?? 0} open',
                    Icons.support_agent_rounded,
                    'Open the tickets inbox to reply.',
                    onTap: () => context.go(RouteNames.adminTickets),
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
        accentColor:
            adminStatusColor(context, AdminStatusTone.success),
      ),
      AdminKpiCard(
        title: 'Open disputes',
        value: '${s.openDisputeCount}',
        changeLabel: 'Awaiting a decision',
        icon: Icons.report_problem_outlined,
        accentColor:
            adminStatusColor(context, AdminStatusTone.warning),
      ),
      AdminKpiCard(
        title: 'Open support tickets',
        value: '${s.openTicketCount}',
        changeLabel: 'Awaiting a reply',
        icon: Icons.support_agent_rounded,
        accentColor: adminStatusColor(context, AdminStatusTone.info),
      ),
    ];
  }

  /// A link card: the disputes centre (Phase D) and the tickets
  /// inbox (Phase E) both exist, so the card opens its destination
  /// instead of describing it as arriving later.
  Widget _infoCard(
      String title, String value, IconData icon, String note,
      {VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                )),
        subtitle: Text('$value • $note',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
