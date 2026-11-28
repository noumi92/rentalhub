import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import 'admin_kpi_card.dart';
import 'admin_list_card.dart';
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

/// Read-only Booking KPIs & historical status counts (numbers only —
/// no individual booking details) inside [AdminShopDetailView].
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

  int _count(Set<String> statuses) =>
      _bookings.where((b) => statuses.contains(b.status)).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    if (_loading) return const AppLoadingState();
    final total = _bookings.length;
    final onlineCount = _bookings.where((b) => b.origin != 'walk_in').length;
    final walkInCount = total - onlineCount;
    final pendingCount = _count({'requested', 'approved', 'payment_submitted'});
    final activeCount = _count({'paid', 'active'});
    final completedCount = _count({'completed'});
    final cancelledCount = _count({'cancelled', 'rejected'});
    final disputedCount = _count({'disputed'});
    final success = adminStatusColor(context, AdminStatusTone.success);
    final warning = adminStatusColor(context, AdminStatusTone.warning);
    final info = adminStatusColor(context, AdminStatusTone.info);
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;

    final cards = [
      AdminKpiCard(
        title: l10n.admin2_navBookings,
        value: '$total',
        changeLabel: '$onlineCount Online • $walkInCount Walk-in',
        icon: Icons.analytics_outlined,
        accentColor: info,
      ),
      AdminKpiCard(
        title: l10n.bookingsFilterPending,
        value: '$pendingCount',
        changeLabel: l10n.adminKpiPending,
        icon: Icons.schedule_rounded,
        accentColor: warning,
      ),
      AdminKpiCard(
        title: l10n.active,
        value: '$activeCount',
        changeLabel: '${l10n.statusPaid} & ${l10n.active}',
        icon: Icons.directions_car_rounded,
        accentColor: success,
      ),
      AdminKpiCard(
        title: l10n.statusCompleted,
        value: '$completedCount',
        changeLabel: l10n.statusCompleted,
        icon: Icons.check_circle_outline_rounded,
        accentColor: success,
      ),
      AdminKpiCard(
        title: l10n.statusCancelled,
        value: '$cancelledCount',
        changeLabel: '${l10n.statusCancelled} / ${l10n.statusRejected}',
        icon: Icons.cancel_outlined,
        accentColor: neutral,
      ),
      AdminKpiCard(
        title: l10n.statusDisputed,
        value: '$disputedCount',
        changeLabel: l10n.admin2_navDisputes,
        icon: Icons.gavel_rounded,
        accentColor: disputedCount > 0 ? warning : neutral,
      ),
    ];

    return SingleChildScrollView(
      padding: widget.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth < 340
              ? 1
              : constraints.maxWidth < 720
                  ? 2
                  : 3;
          const gap = 12.0;
          final w = (constraints.maxWidth - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: cards.map((c) => SizedBox(width: w, child: c)).toList(),
          );
        },
      ),
    );
  }
}

/// Inline Packages & WhatsApp Credits tab inside [AdminShopDetailView].
/// During initial launch, Change Plan and Grant Credits show Coming Soon.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.adminPackagesControlsComingSoon,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
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
              leading: const Icon(Icons.card_membership_rounded),
              title: Text(l10n.admin2_shopDetailPlan),
              subtitle: Text(shop.plan.toUpperCase()),
              trailing: AdminStatusChip(
                label: l10n.packagesComingSoonBadge,
                tone: AdminStatusTone.neutral,
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
              trailing: AdminStatusChip(
                label: l10n.packagesComingSoonBadge,
                tone: AdminStatusTone.neutral,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
