import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_list_card.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/shop_application_detail_sheet.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/admin_suspend_dialog.dart';
import '../widgets/shop_detail_actions.dart';

/// Phase B (B2) — one shop: plan, cars, lifetime bookings, rating,
/// KYC and bank summary, and the admin actions — suspend/unsuspend
/// with a reason, and message the owner on WhatsApp.
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

  /// Step 2 — open the existing Cars / Bookings list for this shop.
  void _goScoped(String path) => context.go(Uri(
      path: path, queryParameters: {'shopId': widget.shopId}).toString());

  /// Phase 3 (3.1): a pending shop's application is decided here
  /// — the Approvals screen is gone, so the review sheet opens
  /// from the detail route and reloads the shop on a decision.
  void _reviewApplication() {
    final shop = _shop;
    if (shop == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ShopApplicationDetailSheet(
        shop: shop,
        onDecided: _load,
      ),
    );
  }

  Future<void> _toggleSuspend(bool suspend) async {
    final reason = await showSuspendDialog(context, suspend: suspend);
    if (reason == null) return;
    if (!mounted) return;
    if (reason.isEmpty) {
      AppFeedback.showError(context, (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_reasonRequired);
      return;
    }
    // F-C1: super admin + operations only (decideVendor). See the
    // shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.decideVendor);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().setShopSuspended(
      shopId: widget.shopId,
      suspended: suspend,
      reason: reason,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
      AppFeedback.showSuccess(
          context, suspend ? l10n.admin2_shopDetailSuspended : l10n.admin2_shopDetailSuspensionLifted);
      await _load();
    } else {
      AppFeedback.showError(context, (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_serverUnreachable);
    }
    setState(() => _isWorking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return AdminShell(
      activeRoute: RouteNames.adminShops,
      title: l10n.admin2_shopDetailTitle,
      subtitle: l10n.admin2_shopDetailSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminShops),
      // Phase 4 (4.4a) — the actions (review / message / suspend)
      // are the sticky bar now, not the bottom of the scroll.
      bottomBar: _shop == null
          ? null
          : ShopDetailActions(
              shop: _shop!,
              isWorking: _isWorking,
              onToggleSuspend: () => _toggleSuspend(!_shop!.suspended),
              onReviewApplication: _shop!.verificationStatus == 'pending'
                  ? _reviewApplication
                  : null,
            ),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_shopDetailLoadFailed,
                  onRetry: _load,
                )
              : _shop == null
                  ? AppEmptyState(title: l10n.admin2_shopDetailNotFound)
                  : SingleChildScrollView(
                  // Mobile-first: 16dp on a phone, 24dp on desktop.
                  padding: EdgeInsets.all(
                      windowSizeClassOf(context) ==
                              WindowSizeClass.compact
                          ? 16
                          : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_shop!.shopName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.admin2_shopDetailContact(_shop!.city, _shop!.address, _shop!.ownerName ?? '—', _shop!.phoneNumber),
                        style: const TextStyle(
                            fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AdminFactTile(label: l10n.admin2_shopDetailPlan, value: _shop!.plan),
                          // AD-M9: the raw `verificationStatus`
                          // ('pending'/'approved') was shown verbatim.
                          AdminFactTile(
                              label: l10n.admin2_shopDetailStatus,
                              value: _shop!.suspended ? l10n.admin2_suspended : humanizeStatus(_shop!.verificationStatus, l10n)),
                          AdminFactTile(label: l10n.admin2_navCars, value: '$_vehicleCount'),
                          AdminFactTile(label: l10n.admin2_shopDetailLifetimeBookings, value: '$_bookingCount'),
                          // Honesty flag (Worker 1): no stored rating
                          // shows '—', never the display-only fallback.
                          AdminFactTile(
                              label: l10n.admin2_shopDetailRating,
                              value: _shop!.hasRealRating ? _shop!.rating.toStringAsFixed(1) : '—'),
                          // F-m7: the real WhatsApp credits balance
                          // from `whatsapp_credits/{shopId}` — null
                          // means no credits document exists yet, so
                          // the fact says so instead of a 0 that was
                          // never stored.
                          AdminFactTile(
                              label: l10n.adminAuditCredits,
                              value: _creditsBalance == null
                                  ? l10n.adminAuditCreditsNone
                                  : '$_creditsBalance'),
                        ],
                      ),
                      if (_shop!.suspended &&
                          (_shop!.suspensionReason ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(l10n.admin2_shopDetailSuspensionReason(_shop!.suspensionReason ?? ''),
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.error)),
                      ],
                      // Step 2 — entry points into the existing
                      // Cars / Bookings screens, scoped to this shop.
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('admin2_shopDetailViewCars'),
                        onPressed: () => _goScoped(RouteNames.adminCars),
                        child: Text(l10n.admin2_shopDetailViewCars),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('admin2_shopDetailViewBookings'),
                        onPressed: () => _goScoped(RouteNames.adminBookings),
                        child: Text(l10n.admin2_shopDetailViewBookings),
                      ),
                      const SizedBox(height: 20),
                      AdminDetailSection(
                          title: l10n.admin2_shopDetailKycDocs,
                          lines: _shop!.kycDocuments.isEmpty
                              ? [l10n.admin2_shopDetailNoneUploaded]
                              : _shop!.kycDocuments.keys.toList()),
                      AdminDetailSection(
                          title: l10n.admin2_shopDetailBankAccounts,
                          lines: _shop!.bankAccounts.isEmpty
                              ? [l10n.admin2_shopDetailNoneOnFile]
                              : _shop!.bankAccounts
                                  .map((a) =>
                                      '${a['type'] ?? l10n.admin2_shopDetailAccountType} — ${a['title'] ?? a['account'] ?? ''}')
                                  .toList()),
                    ],
                  ),
                ),
    );
  }

}
