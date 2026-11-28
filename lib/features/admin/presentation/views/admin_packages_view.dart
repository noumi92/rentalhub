import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_packages_data_source.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_mini_kpi_strip.dart';
import '../widgets/admin_packages_dialogs.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_shop_plans_tab.dart';
import '../widgets/admin_subscription_requests_tab.dart';
import '../widgets/admin_whatsapp_packages_tab.dart';

/// Packages & WhatsApp Credits management hub for Super Admin & Operations.
class AdminPackagesView extends StatefulWidget {
  const AdminPackagesView({
    super.key,
    this.initialTab = 'plans',
    this.dataSource,
    this.adminRole,
  });

  final String initialTab;
  final AdminPackagesDataSource? dataSource;
  final String? adminRole;

  @override
  State<AdminPackagesView> createState() => _AdminPackagesViewState();
}

class _AdminPackagesViewState extends State<AdminPackagesView> {
  static const _validTabs = {'plans', 'requests', 'whatsapp'};

  late String _activeTab;
  List<AdminShopPlanRow> _shops = [];
  List<AdminSubscriptionRequest> _subRequests = [];
  List<AdminCreditRequest> _creditRequests = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _role;

  AdminPackagesDataSource get _ds =>
      widget.dataSource ?? sl<AdminPackagesDataSource>();

  bool get _canManage =>
      AdminPermissions.can(_role, AdminPermission.manageSubscriptions);

  @override
  void initState() {
    super.initState();
    _activeTab =
        _validTabs.contains(widget.initialTab) ? widget.initialTab : 'plans';
    _role = widget.adminRole;
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminPackagesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final next =
          _validTabs.contains(widget.initialTab) ? widget.initialTab : 'plans';
      if (next != _activeTab) setState(() => _activeTab = next);
    }
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      _role ??= await AdminSession.resolveCurrentAdminRole();
      final results = await Future.wait([
        _ds.getShopPlans(),
        _ds.getSubscriptionRequests(),
        _ds.getCreditPurchaseRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _shops = results[0] as List<AdminShopPlanRow>;
        _subRequests = results[1] as List<AdminSubscriptionRequest>;
        _creditRequests = results[2] as List<AdminCreditRequest>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  void _reportResult(bool ok, String successMsg) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (ok) {
      AppFeedback.showSuccess(context, successMsg);
      _load();
    } else {
      AppFeedback.showError(
        context,
        l10n?.adminPackagesActionFailed ?? 'Could not save this change.',
      );
    }
  }

  Future<void> _changePlan(AdminShopPlanRow shop) async {
    final result = await showAdminChangePlanDialog(context, shop: shop);
    if (result == null || !mounted) return;
    final ok = await _ds.setShopPlan(
      shopId: shop.shopId,
      tier: result.tier,
      reason: result.reason,
      adminRole: _role,
    );
    if (!mounted) return;
    _reportResult(ok, AppLocalizations.of(context)?.adminPackagesPlanUpdated ?? 'Shop plan updated.');
  }

  Future<void> _grantCredits(AdminShopPlanRow shop) async {
    final result = await showAdminGrantCreditsDialog(context, shop: shop);
    if (result == null || !mounted) return;
    final ok = await _ds.adjustShopCredits(
      shopId: shop.shopId,
      deltaCredits: result.delta,
      reason: result.reason,
      adminRole: _role,
    );
    if (!mounted) return;
    _reportResult(ok, AppLocalizations.of(context)?.adminPackagesCreditsUpdated ?? 'WhatsApp credits updated.');
  }

  Future<void> _decideSub(AdminSubscriptionRequest req, bool approve) async {
    final reason = approve ? '' : (await showAdminReasonDialog(context, title: req.shopName) ?? '');
    if (!mounted) return;
    final ok = await _ds.decideSubscriptionRequest(
      requestId: req.requestId,
      shopId: req.shopId,
      tier: req.tier,
      approve: approve,
      reason: reason,
      adminRole: _role,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _reportResult(
      ok,
      approve
          ? (l10n?.adminPackagesRequestApproved ?? 'Request approved.')
          : (l10n?.adminPackagesRequestRejected ?? 'Request rejected.'),
    );
  }

  Future<void> _decideCredit(AdminCreditRequest req, bool approve) async {
    final reason = approve ? '' : (await showAdminReasonDialog(context, title: req.shopName) ?? '');
    if (!mounted) return;
    final ok = await _ds.decideCreditPurchaseRequest(
      requestId: req.requestId,
      shopId: req.shopId,
      packCredits: req.packCredits,
      approve: approve,
      reason: reason,
      adminRole: _role,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _reportResult(
      ok,
      approve
          ? (l10n?.adminPackagesRequestApproved ?? 'Request approved.')
          : (l10n?.adminPackagesRequestRejected ?? 'Request rejected.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = windowSizeClassOf(context) == WindowSizeClass.compact;
    final pendingSubs = _subRequests.where((r) => r.status == 'pending').length;
    final pendingCredits = _creditRequests.where((r) => r.status == 'pending').length;
    final paidCount = _shops.where((s) => s.tier != 'free').length;

    return AdminShell(
      activeRoute: RouteNames.adminSubscriptions,
      title: l10n?.adminNavPackagesCredits ?? 'Packages & Credits',
      subtitle: l10n?.adminPackagesSubtitle ??
          'Manage showroom plans, upgrade requests, and WhatsApp credit packs',
      subTabs: AdminSectionTabs.packagesAndCredits(
        context,
        activeTab: _activeTab,
        subscriptionsBadge: pendingSubs,
        creditsBadge: pendingCredits,
      ),
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: _isLoading
            ? const AppLoadingState()
            : _hasError
                ? AppErrorState(
                    message: l10n?.adminPackagesActionFailed ?? 'Could not load packages.',
                    onRetry: _load,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminMiniKpiStrip(items: [
                        AdminMiniKpi(
                          label: l10n?.adminKpiPaidPlans ?? 'Paid Plans',
                          value: '$paidCount',
                          icon: Icons.card_membership_rounded,
                        ),
                        AdminMiniKpi(
                          label: l10n?.adminTabUpgradeRequests ?? 'Upgrade Requests',
                          value: '$pendingSubs',
                          icon: Icons.upgrade_rounded,
                        ),
                        AdminMiniKpi(
                          label: l10n?.adminTabWhatsappPackages ?? 'WhatsApp Packages',
                          value: '$pendingCredits',
                          icon: Icons.chat_rounded,
                        ),
                      ]),
                      Expanded(
                        child: switch (_activeTab) {
                          'requests' => AdminSubscriptionRequestsTab(
                              requests: _subRequests,
                              canManage: _canManage,
                              onDecide: _decideSub,
                            ),
                          'whatsapp' => AdminWhatsappPackagesTab(
                              requests: _creditRequests,
                              canManage: _canManage,
                              onDecide: _decideCredit,
                            ),
                          _ => AdminShopPlansTab(
                              shops: _shops,
                              canManage: _canManage,
                              onChangePlan: _changePlan,
                              onGrantCredits: _grantCredits,
                            ),
                        },
                      ),
                    ],
                  ),
      ),
    );
  }
}
