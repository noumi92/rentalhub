import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_suspend_dialog.dart';
import '../widgets/shop_application_detail_sheet.dart';
import '../widgets/shop_detail_actions.dart';
import '../widgets/shop_detail_management_tabs.dart';
import '../widgets/shop_detail_overview_tab.dart';

/// One-stop Shop Management Hub: executive KPIs + 5 horizontal tabs
/// (Overview, KYC & Docs, Fleet Cars, Bookings, Packages & Credits)
/// with sticky owner actions.
class AdminShopDetailView extends StatefulWidget {
  const AdminShopDetailView({super.key, required this.shopId});

  final String shopId;

  @override
  State<AdminShopDetailView> createState() => _AdminShopDetailViewState();
}

class _AdminShopDetailViewState extends State<AdminShopDetailView> {
  ShopModel? _shop;
  int _vehicleCount = 0;
  int _bookingCount = 0;
  int? _creditsBalance;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final ds = sl<AdminShopsDataSource>();
      final shop = await ds.getShop(widget.shopId);
      final vehicles = await ds.getShopVehicleCount(widget.shopId);
      final bookings = await ds.getShopBookingCount(widget.shopId);
      final credits = await ds.getShopCreditsBalance(widget.shopId);
      if (mounted) {
        setState(() {
          _shop = shop;
          _vehicleCount = vehicles;
          _bookingCount = bookings;
          _creditsBalance = credits;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goScoped(String path) => context.go(
        Uri(path: path, queryParameters: {'shopId': widget.shopId}).toString(),
      );

  void _reviewApplication() {
    final shop = _shop;
    if (shop == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ShopApplicationDetailSheet(shop: shop, onDecided: _load),
    );
  }

  Future<void> _toggleSuspend(bool suspend) async {
    final reason = await showSuspendDialog(context, suspend: suspend);
    if (reason == null || !mounted) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    if (reason.isEmpty) {
      AppFeedback.showError(context, l10n.admin2_reasonRequired);
      return;
    }
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.decideVendor);
    if (!check.proceed || !mounted) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().setShopSuspended(
      shopId: widget.shopId,
      suspended: suspend,
      reason: reason,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
        context,
        suspend
            ? l10n.admin2_shopDetailSuspended
            : l10n.admin2_shopDetailSuspensionLifted,
      );
      await _load();
    } else {
      AppFeedback.showError(context, l10n.admin2_serverUnreachable);
    }
    setState(() => _isWorking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final padding = EdgeInsets.all(
      windowSizeClassOf(context) == WindowSizeClass.compact ? 16 : 24,
    );
    final shop = _shop;
    return AdminShell(
      activeRoute: RouteNames.adminShops,
      title: l10n.admin2_shopDetailTitle,
      subtitle: l10n.admin2_shopDetailSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminShops),
      bottomBar: shop == null
          ? null
          : ShopDetailActions(
              shop: shop,
              isWorking: _isWorking,
              onToggleSuspend: () => _toggleSuspend(!shop.suspended),
              onReviewApplication:
                  shop.verificationStatus == 'pending' ? _reviewApplication : null,
            ),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_shopDetailLoadFailed,
                  onRetry: _load,
                )
              : shop == null
                  ? AppEmptyState(title: l10n.admin2_shopDetailNotFound)
                  : DefaultTabController(
                      length: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: padding.copyWith(bottom: 0),
                            child: ShopDetailHeaderKpis(
                              shop: shop,
                              vehicleCount: _vehicleCount,
                              bookingCount: _bookingCount,
                              creditsBalance: _creditsBalance,
                            ),
                          ),
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              Tab(text: l10n.admin2_sidebarGroupOverview),
                              Tab(text: l10n.admin2_shopDetailKycDocs),
                              Tab(text: l10n.adminTabFleetCars),
                              Tab(text: l10n.admin2_navBookings),
                              Tab(text: l10n.adminNavPackagesCredits),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                ShopDetailOverviewTab(
                                  shop: shop,
                                  padding: padding,
                                  onViewCars: () => _goScoped(RouteNames.adminCars),
                                  onViewBookings: () =>
                                      _goScoped(RouteNames.adminBookings),
                                ),
                                ShopDetailKycTab(
                                  shop: shop,
                                  padding: padding,
                                  onReviewApplication: _reviewApplication,
                                ),
                                ShopDetailCarsTab(
                                  shopId: shop.shopId,
                                  padding: padding,
                                ),
                                ShopDetailBookingsTab(
                                  shopId: shop.shopId,
                                  padding: padding,
                                ),
                                ShopDetailPackagesTab(
                                  shop: shop,
                                  creditsBalance: _creditsBalance,
                                  padding: padding,
                                  onUpdated: _load,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
