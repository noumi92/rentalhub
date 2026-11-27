import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/services/admin_queue_counts_service.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_shell.dart';

/// Phase 2 (2.2) — the Queues hub: the phone bottom nav's Queues
/// tab, listing the six review queues with their live counts. Each
/// row navigates to its queue screen; the counts come from the same
/// [AdminQueueCountsService] the sidebar badges use, so the hub and
/// the sidebar never disagree.
///
/// Phase 3 (3.1): Approvals is no longer its own queue screen —
/// its row navigates to the Shops list with the Pending filter
/// applied, so the count still comes from the same service.
///
/// The KYC Review row is role-gated like the sidebar item
/// (decideKyc roles only); the hub loads with a spinner, so there is
/// no layout shift while the role resolves.
class AdminQueuesView extends StatefulWidget {
  const AdminQueuesView({super.key, this.loadCounts, this.showKycReview});

  /// Test seam: when non-null, supplies the queue counts instead of
  /// reading them from [AdminQueueCountsService].
  final Future<AdminQueueCounts> Function()? loadCounts;

  /// Test seam: when non-null, forces the KYC Review row visible
  /// (true) or hidden (false) without resolving the signed-in role.
  final bool? showKycReview;

  @override
  State<AdminQueuesView> createState() => _AdminQueuesViewState();
}

class _AdminQueuesViewState extends State<AdminQueuesView> {
  AdminQueueCounts? _counts;
  bool _isLoading = true;
  bool _hasError = false;
  bool _canReviewKyc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final canReviewKyc = widget.showKycReview ??
          AdminPermissions.can(
              await AdminSession.resolveCurrentAdminRole(),
              AdminPermission.decideKyc);
      final counts = widget.loadCounts != null
          ? await widget.loadCounts!()
          : await sl<AdminQueueCountsService>()
              .getCounts(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _canReviewKyc = canReviewKyc;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    final counts = _counts;
    final queues = <({String route, String label, IconData icon, int count})>[
      (
        route: '${RouteNames.adminShops}?filter=pending',
        label: l10n.admin2_navApprovals,
        icon: Icons.verified_user_rounded,
        count: counts?.approvals ?? 0,
      ),
      if (_canReviewKyc)
        (
          route: RouteNames.adminKycReview,
          label: l10n.adminKycReviewTitle,
          icon: Icons.badge_rounded,
          count: counts?.kyc ?? 0,
        ),
      (
        route: RouteNames.adminCars,
        label: l10n.admin2_navCars,
        icon: Icons.directions_car_rounded,
        count: counts?.cars ?? 0,
      ),
      (
        route: RouteNames.adminDisputes,
        label: l10n.admin2_navDisputes,
        icon: Icons.gavel_rounded,
        count: counts?.disputes ?? 0,
      ),
      (
        route: RouteNames.adminReviews,
        label: l10n.admin2_navReviews,
        icon: Icons.star_rounded,
        count: counts?.reviews ?? 0,
      ),
      (
        route: RouteNames.adminTickets,
        label: l10n.admin2_navSupport,
        icon: Icons.support_agent_rounded,
        count: counts?.tickets ?? 0,
      ),
    ];
    return AdminShell(
      activeRoute: RouteNames.adminQueues,
      title: l10n.admin2_queuesTitle,
      subtitle: l10n.admin2_queuesSubtitle,
      onRefresh: () => _load(forceRefresh: true),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_queuesLoadFailed,
                  onRetry: _load,
                )
              : ListView.separated(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  itemCount: queues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final q = queues[i];
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
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(q.icon, size: 20),
                        ),
                        title: Text(q.label,
                            style: const TextStyle(fontSize: 14)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.admin2_dashboardOpenCount(q.count),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16),
                          ],
                        ),
                        onTap: () => context.go(q.route),
                      ),
                    );
                  },
                ),
    );
  }
}
