import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
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
    // Tests pump without localization delegates — fall back to
    // English instead of crashing on a null check.
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminDashboard,
      title: l10n?.admin2_navDashboard ?? 'Dashboard',
      subtitle: l10n?.admin2_dashboardSubtitle ??
          'The platform at a glance, counted live',
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n?.admin2_dashboardLoadFailed ??
                      'Could not load the dashboard.',
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
                    l10n?.admin2_dashboardDisputesTitle ??
                        'Open disputes need a decision',
                    l10n?.admin2_dashboardOpenCount(
                            _stats?.openDisputeCount ?? 0) ??
                        '${_stats?.openDisputeCount ?? 0} open',
                    Icons.report_problem_outlined,
                    l10n?.admin2_dashboardDisputesHint ??
                        'Open the disputes centre to decide them.',
                    onTap: () => context.go(RouteNames.adminDisputes),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    l10n?.admin2_dashboardTicketsTitle ??
                        'Support tickets waiting',
                    l10n?.admin2_dashboardOpenCount(
                            _stats?.openTicketCount ?? 0) ??
                        '${_stats?.openTicketCount ?? 0} open',
                    Icons.support_agent_rounded,
                    l10n?.admin2_dashboardTicketsHint ??
                        'Open the tickets inbox to reply.',
                    onTap: () => context.go(RouteNames.adminTickets),
                  ),
                  const SizedBox(height: 12),
                  // F-m1: the approvals queue is the most actionable
                  // queue on the platform, and it had no count on
                  // the dashboard — an admin had to open Approvals
                  // to learn a shop was waiting.
                  _infoCard(
                    AppLocalizations.of(context)
                            ?.adminAuditPendingApprovals ??
                        'Shops waiting for approval',
                    '${_stats?.pendingShopCount ?? 0} pending',
                    Icons.store_rounded,
                    AppLocalizations.of(context)
                            ?.adminAuditPendingApprovalsHint ??
                        'Open the approvals queue to decide them.',
                    onTap: () => context.go(RouteNames.adminApprovals),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _cards() {
    final l10n = AppLocalizations.of(context);
    final s = _stats ??
        const PlatformStats(
          shopCount: 0,
          activeBookingCount: 0,
          openDisputeCount: 0,
          openTicketCount: 0,
          pendingShopCount: 0,
        );
    return [
      AdminKpiCard(
        title: l10n?.admin2_dashboardKpiShops ?? 'Registered shops',
        value: '${s.shopCount}',
        changeLabel: l10n?.admin2_dashboardKpiLiveCount ?? 'Live count',
        icon: Icons.store_rounded,
      ),
      AdminKpiCard(
        title: l10n?.admin2_dashboardKpiBookings ?? 'Active bookings',
        value: '${s.activeBookingCount}',
        changeLabel: l10n?.admin2_dashboardKpiBookingsNote ??
            'Approved, paid or active',
        icon: Icons.calendar_month_rounded,
        accentColor:
            adminStatusColor(context, AdminStatusTone.success),
      ),
      AdminKpiCard(
        title: l10n?.admin2_dashboardKpiDisputes ?? 'Open disputes',
        value: '${s.openDisputeCount}',
        changeLabel: l10n?.admin2_dashboardKpiDisputesNote ??
            'Awaiting a decision',
        icon: Icons.report_problem_outlined,
        accentColor:
            adminStatusColor(context, AdminStatusTone.warning),
      ),
      AdminKpiCard(
        title: l10n?.admin2_dashboardKpiTickets ?? 'Open support tickets',
        value: '${s.openTicketCount}',
        changeLabel: l10n?.admin2_dashboardKpiTicketsNote ??
            'Awaiting a reply',
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
                )),
        subtitle: Text('$value • $note',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        // AD-m19: the card navigates on tap — the chevron says so.
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
