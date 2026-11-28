import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_packages_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../domain/admin_permissions.dart';
import 'admin_booking_list_tile.dart';
import 'admin_list_card.dart';
import 'admin_packages_dialogs.dart';
import 'admin_permission_check.dart';
import 'admin_status_chip.dart';
import 'car_review_detail_sheet.dart';

/// Inline Fleet Cars tab inside [AdminShopDetailView].
class ShopDetailCarsTab extends StatefulWidget {
  const ShopDetailCarsTab({
    super.key,
    required this.shopId,
    required this.padding,
  });

  final String shopId;
  final EdgeInsetsGeometry padding;

  @override
  State<ShopDetailCarsTab> createState() => _ShopDetailCarsTabState();
}

class _ShopDetailCarsTabState extends State<ShopDetailCarsTab> {
  List<VehicleEntity> _cars = [];
  Map<String, CarReview> _reviews = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = sl<AdminShopsDataSource>();
      final cars = await ds.getCars();
      final reviews = await ds.getCarReviews();
      if (!mounted) return;
      setState(() {
        _cars = cars.where((c) => c.shopId == widget.shopId).toList();
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    if (_loading) return const AppLoadingState();
    if (_cars.isEmpty) {
      return AppEmptyState(
        title: l10n.admin2_carsEmptyTitle,
        icon: Icons.directions_car_rounded,
      );
    }
    return ListView.separated(
      padding: widget.padding,
      itemCount: _cars.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final car = _cars[i];
        final review = _reviews[car.vehicleId]?.status ?? 'pending';
        return AdminListCard(
          icon: Icons.directions_car_rounded,
          title: '${car.make} ${car.model} (${car.year})',
          subtitle:
              '${car.plateNumber} • ${l10n.fleetDailyRate(formatRs(car.rates.daily24))}',
          trailing: AdminStatusChip.carReviewStatus(
              review, AppLocalizations.of(context)),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => CarReviewDetailSheet(
              vehicle: car,
              review: _reviews[car.vehicleId],
              onDecided: _load,
            ),
          ),
        );
      },
    );
  }
}

/// Inline Bookings tab inside [AdminShopDetailView].
class ShopDetailBookingsTab extends StatefulWidget {
  const ShopDetailBookingsTab({
    super.key,
    required this.shopId,
    required this.padding,
  });

  final String shopId;
  final EdgeInsetsGeometry padding;

  @override
  State<ShopDetailBookingsTab> createState() => _ShopDetailBookingsTabState();
}

class _ShopDetailBookingsTabState extends State<ShopDetailBookingsTab> {
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await sl<AdminPlatformDataSource>().getBookings();
      if (!mounted) return;
      setState(() {
        _bookings = all.where((b) => b.shopId == widget.shopId).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    if (_loading) return const AppLoadingState();
    if (_bookings.isEmpty) {
      return AppEmptyState(
        title: l10n.admin2_bookingsEmptyTitle,
        icon: Icons.receipt_long_rounded,
      );
    }
    return ListView.separated(
      padding: widget.padding,
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = _bookings[i];
        return AdminBookingListTile(
          booking: b,
          compact: true,
          onTap: () => context.go(
            RouteNames.adminBookingDetail
                .replaceFirst(':bookingId', b.bookingId),
          ),
        );
      },
    );
  }
}

/// Inline Packages & WhatsApp Credits management tab inside [AdminShopDetailView].
class ShopDetailPackagesTab extends StatelessWidget {
  const ShopDetailPackagesTab({
    super.key,
    required this.shop,
    required this.creditsBalance,
    required this.padding,
    required this.onUpdated,
  });

  final ShopModel shop;
  final int? creditsBalance;
  final EdgeInsetsGeometry padding;
  final VoidCallback onUpdated;

  AdminShopPlanRow get _planRow => AdminShopPlanRow(
        shopId: shop.shopId,
        shopName: shop.shopName,
        city: shop.city,
        tier: shop.plan,
        isVerified: shop.verificationStatus == 'approved' ||
            shop.verificationStatus == 'verified',
        whatsappBalance: creditsBalance ?? 0,
      );

  Future<void> _changePlan(BuildContext context) async {
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.manageSubscriptions);
    if (!check.proceed || !context.mounted) return;
    final result = await showAdminChangePlanDialog(context, shop: _planRow);
    if (result == null || !context.mounted) return;
    final ok = await sl<AdminPackagesDataSource>().setShopPlan(
      shopId: shop.shopId,
      tier: result.tier,
      reason: result.reason,
      adminRole: check.role,
    );
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (ok) {
      AppFeedback.showSuccess(
          context, l10n?.adminPackagesPlanUpdated ?? 'Shop plan updated.');
      onUpdated();
    } else {
      AppFeedback.showError(
          context, l10n?.adminPackagesActionFailed ?? 'Could not save change.');
    }
  }

  Future<void> _grantCredits(BuildContext context) async {
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.manageSubscriptions);
    if (!check.proceed || !context.mounted) return;
    final result = await showAdminGrantCreditsDialog(context, shop: _planRow);
    if (result == null || !context.mounted) return;
    final ok = await sl<AdminPackagesDataSource>().adjustShopCredits(
      shopId: shop.shopId,
      deltaCredits: result.delta,
      reason: result.reason,
      adminRole: check.role,
    );
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (ok) {
      AppFeedback.showSuccess(context,
          l10n?.adminPackagesCreditsUpdated ?? 'WhatsApp credits updated.');
      onUpdated();
    } else {
      AppFeedback.showError(
          context, l10n?.adminPackagesActionFailed ?? 'Could not save change.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: ListTile(
              leading: const Icon(Icons.card_membership_rounded),
              title: Text(l10n.admin2_shopDetailPlan),
              subtitle: Text(shop.plan.toUpperCase()),
              trailing: FilledButton(
                onPressed: () => _changePlan(context),
                child: Text(l10n.adminPackagesChangePlan),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: ListTile(
              leading: const Icon(Icons.chat_rounded),
              title: Text(l10n.adminAuditCredits),
              subtitle: Text(
                creditsBalance == null
                    ? l10n.adminAuditCreditsNone
                    : '$creditsBalance',
              ),
              trailing: OutlinedButton(
                onPressed: () => _grantCredits(context),
                child: Text(l10n.adminPackagesGrantCredits),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
