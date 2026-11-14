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
import '../widgets/admin_permission_check.dart';
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
                          _fact(l10n.admin2_shopDetailPlan, _shop!.plan),
                          // AD-M9: the raw `verificationStatus`
                          // ('pending'/'approved') was shown verbatim.
                          _fact(l10n.admin2_shopDetailStatus,
                              _shop!.suspended ? l10n.admin2_suspended : humanizeStatus(_shop!.verificationStatus, l10n)),
                          _fact(l10n.admin2_navCars, '$_vehicleCount'),
                          _fact(l10n.admin2_shopDetailLifetimeBookings, '$_bookingCount'),
                          // Honesty flag (Worker 1): no stored rating
                          // shows '—', never the display-only fallback.
                          _fact(l10n.admin2_shopDetailRating,
                              _shop!.hasRealRating ? _shop!.rating.toStringAsFixed(1) : '—'),
                          // F-m7: the real WhatsApp credits balance
                          // from `whatsapp_credits/{shopId}` — null
                          // means no credits document exists yet, so
                          // the fact says so instead of a 0 that was
                          // never stored.
                          _fact(
                              l10n.adminAuditCredits,
                              _creditsBalance == null
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
                      const SizedBox(height: 8),
                      ShopDetailActions(
                        shop: _shop!,
                        isWorking: _isWorking,
                        onToggleSuspend: () =>
                            _toggleSuspend(!_shop!.suspended),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _fact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  )),
        ],
      ),
    );
  }
}
