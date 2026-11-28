import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_dashboard_kpi_sections.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';

/// Mobile-first Executive Admin Dashboard:
/// 1. Needs Attention (actionable queues at a glance)
/// 2. Platform Metrics (clean read-only KPI tiles — Shops, Customers, Bookings)
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, this.showKycCard});

  final bool? showKycCard;

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  PlatformStats? _stats;
  bool _isLoading = true;
  bool _hasError = false;
  bool _canReviewKyc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final stats = await sl<AdminRemoteDataSource>().getPlatformStats();
      final role = await AdminSession.resolveCurrentAdminRole();
      final canReviewKyc = widget.showKycCard ??
          AdminPermissions.can(role, AdminPermission.decideKyc);
      if (mounted) {
        setState(() {
          _stats = stats;
          _canReviewKyc = canReviewKyc;
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
    final l10n = AppLocalizations.of(context);
    final compact = windowSizeClassOf(context) == WindowSizeClass.compact;
    final stats = _stats ??
        const PlatformStats(
          shopCount: 0,
          activeBookingCount: 0,
          openDisputeCount: 0,
          openTicketCount: 0,
          pendingShopCount: 0,
        );

    return AdminShell(
      activeRoute: RouteNames.adminDashboard,
      title: l10n?.admin2_navDashboard ?? 'Dashboard',
      subtitle: l10n?.admin2_dashboardSubtitle ??
          'The platform at a glance, counted live',
      subTabs: AdminSectionTabs.overview(
        context,
        activeRoute: RouteNames.adminDashboard,
      ),
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
                  padding: EdgeInsets.all(compact ? 14 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (l10n?.adminDashboardActionRequired ??
                                'Needs Attention')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _actionList(context, l10n, stats),
                      const SizedBox(height: 22),
                      AdminDashboardKpiSections(
                        stats: stats,
                        canReviewKyc: _canReviewKyc,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _actionList(
    BuildContext context,
    AppLocalizations? l10n,
    PlatformStats stats,
  ) {
    final rows = <Widget>[
      _queueRow(
        context,
        title: l10n?.adminAuditPendingApprovals ?? 'Shops waiting for approval',
        count: stats.pendingShopCount,
        icon: Icons.store_rounded,
        onTap: () => context.go('${RouteNames.adminShops}?filter=pending'),
      ),
      if (_canReviewKyc)
        _queueRow(
          context,
          title: l10n?.admin2_dashboardKycTitle ??
              'KYC submissions waiting for review',
          count: stats.pendingKycCount,
          icon: Icons.badge_rounded,
          onTap: () => context.go(RouteNames.adminKycReview),
        ),
      _queueRow(
        context,
        title: l10n?.admin2_dashboardDisputesTitle ??
            'Open disputes need a decision',
        count: stats.openDisputeCount,
        icon: Icons.gavel_rounded,
        onTap: () => context.go(RouteNames.adminDisputes),
      ),
      _queueRow(
        context,
        title: l10n?.admin2_dashboardTicketsTitle ?? 'Support tickets waiting',
        count: stats.openTicketCount,
        icon: Icons.support_agent_rounded,
        onTap: () => context.go(RouteNames.adminTickets),
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _queueRow(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.comfortable,
      leading: Icon(icon, size: 20),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminStatusChip(
            label: '$count',
            tone: count > 0 ? AdminStatusTone.warning : AdminStatusTone.neutral,
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}
