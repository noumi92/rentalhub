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

/// Executive Admin Dashboard: live KPIs grouped into Shops & Fleet,
/// Online vs. Walk-in Customers (walk-in KPI-only), and Bookings & Support.
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key, this.showKycCard});

  /// Test seam: forces the KYC queue card visible/hidden when non-null.
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
    final stats = _stats ??
        const PlatformStats(
          shopCount: 0,
          activeBookingCount: 0,
          openDisputeCount: 0,
          openTicketCount: 0,
          pendingShopCount: 0,
        );
    final pendingPackages =
        stats.pendingSubscriptionCount + stats.pendingCreditRequestCount;

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
                  padding: EdgeInsets.all(
                    windowSizeClassOf(context) == WindowSizeClass.compact
                        ? 16
                        : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminDashboardKpiSections(
                        stats: stats,
                        canReviewKyc: _canReviewKyc,
                      ),
                      const SizedBox(height: 24),
                      _infoCard(
                        l10n?.adminAuditPendingApprovals ??
                            'Shops waiting for approval',
                        '${stats.pendingShopCount} pending',
                        Icons.store_rounded,
                        l10n?.adminAuditPendingApprovalsHint ??
                            'Open the approvals queue to decide them.',
                        onTap: () =>
                            context.go('${RouteNames.adminShops}?filter=pending'),
                      ),
                      if (_canReviewKyc) ...[
                        const SizedBox(height: 12),
                        _infoCard(
                          l10n?.admin2_dashboardKycTitle ??
                              'KYC submissions waiting for review',
                          l10n?.admin2_dashboardOpenCount(
                                  stats.pendingKycCount) ??
                              '${stats.pendingKycCount} open',
                          Icons.badge_rounded,
                          l10n?.admin2_dashboardKycHint ??
                              'Open the KYC review queue to decide them.',
                          onTap: () => context.go(RouteNames.adminKycReview),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _infoCard(
                        l10n?.adminKpiPendingPackageRequests ??
                            'Package Requests',
                        '$pendingPackages pending',
                        Icons.card_membership_rounded,
                        l10n?.adminPackagesSubtitle ??
                            'Manage showroom plans, upgrade requests, and WhatsApp credit packs',
                        onTap: () => context
                            .go('${RouteNames.adminSubscriptions}?tab=requests'),
                      ),
                      const SizedBox(height: 12),
                      _infoCard(
                        l10n?.admin2_dashboardDisputesTitle ??
                            'Open disputes need a decision',
                        l10n?.admin2_dashboardOpenCount(
                                stats.openDisputeCount) ??
                            '${stats.openDisputeCount} open',
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
                                stats.openTicketCount) ??
                            '${stats.openTicketCount} open',
                        Icons.support_agent_rounded,
                        l10n?.admin2_dashboardTicketsHint ??
                            'Open the tickets inbox to reply.',
                        onTap: () => context.go(RouteNames.adminTickets),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
    IconData icon,
    String note, {
    VoidCallback? onTap,
  }) {
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
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          '$value • $note',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
