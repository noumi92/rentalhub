import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../widgets/dashboard/dashboard_kpis.dart';
import '../widgets/dashboard/dashboard_ledger_section.dart';
import '../widgets/dashboard/dashboard_quick_actions.dart';

class OwnerDashboardView extends StatefulWidget {
  final String shopId;

  const OwnerDashboardView({
    super.key,
    this.shopId = 'shop-1',
  });

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  List<BookingEntity> _allBookings = [];
  bool _isLoading = true;
  // E2: a load failure used to render an empty dashboard silently;
  // it now renders an error state with retry.
  bool _hasError = false;
  String _shopName = '';
  int _fleetTotal = 0;
  int _fleetAvailable = 0;
  int _unreadNotifications = 0;
  double? _settleRate;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final ds = sl<BookingRemoteDataSource>();
      final list = await ds.getShopBookings(widget.shopId);
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(widget.shopId);
      final notifications = await sl<NotificationDataSource>()
          .getShopNotifications(widget.shopId);
      String shopName = '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(widget.shopId)
            .get();
        shopName =
            (doc.data()?['name'] ?? doc.data()?['shopName'] ?? '') as String;
      } catch (_) {}
      // The settle rate is real: completed trips whose deposit the
      // return flow actually settled, over all completed trips.
      final completed = list.where((b) => b.status == 'completed').toList();
      double? settleRate;
      if (completed.isNotEmpty) {
        final depositDs = sl<SecurityDepositDataSource>();
        var settled = 0;
        for (final b in completed) {
          final d = await depositDs.getByBookingId(b.bookingId);
          if (d != null && d.status != 'collected') settled++;
        }
        settleRate = settled / completed.length;
      }
      if (mounted) {
        setState(() {
          _allBookings = list;
          _shopName = shopName;
          _fleetTotal = vehicles.length;
          _fleetAvailable =
              vehicles.where((v) => v.status == 'available').length;
          _unreadNotifications = notifications.where((n) => !n.read).length;
          _settleRate = settleRate;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalRevenue => _allBookings
      .where((b) => b.status == 'completed' || b.status == 'active' || b.status == 'paid')
      .fold(0, (total, b) => total + b.totalAmount);

  int get _activeCount => _allBookings.where((b) => b.status == 'active').length;
  int get _completedCount => _allBookings.where((b) => b.status == 'completed').length;
  int get _waitingCount => _allBookings
      .where((b) => b.status == 'requested' || b.status == 'payment_submitted')
      .length;

  /// Revenue from paid / active / completed bookings picked up in one month.
  int _monthRevenue(int year, int month) => _allBookings
      .where((b) =>
          (b.status == 'completed' ||
              b.status == 'active' ||
              b.status == 'paid') &&
          b.pickupTime.year == year &&
          b.pickupTime.month == month)
      .fold(0, (total, b) => total + b.totalAmount);

  /// Real month-on-month revenue change, from the bookings' pickup
  /// dates. Null when there is no last-month revenue to compare.
  String get _growthLabel {
    final now = DateTime.now();
    final thisMonth = _monthRevenue(now.year, now.month);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = _monthRevenue(lastMonthDate.year, lastMonthDate.month);
    if (lastMonth == 0) return AppLocalizations.of(context)!.dashboardNoRevenueLastMonth;
    final pct = ((thisMonth - lastMonth) / lastMonth * 100).round();
    return AppLocalizations.of(context)!.dashboardGrowthLabel('${pct >= 0 ? '+' : ''}$pct');
  }

  List<BookingEntity> get _ledger => (List<BookingEntity>.of(_allBookings)
        ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime)))
      .take(8)
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kpis = DashboardKpis(
      totalRevenue: _totalRevenue,
      growthLabel: _growthLabel,
      activeCount: _activeCount,
      completedCount: _completedCount,
      settleLabel: _settleRate == null
          ? l10n.dashboardNoCompletedTrips
          : l10n.dashboardSettleRate((_settleRate! * 100).round()),
      waitingCount: _waitingCount,
      fleetAvailable: _fleetAvailable,
      fleetTotal: _fleetTotal,
    );
    // E1: the ledger section lives in its own widget file so this view
    // stays under the 250-line cap with the quick actions added.
    final ledger = DashboardLedgerSection(
      isEmpty: _allBookings.isEmpty,
      ledger: _ledger,
    );
    // D3: compact stacks KPIs above the ledger; medium+ puts them side by side.
    final body = isMediumOrLarger(context)
        ? Row(
            key: const Key('dashboard-two-columns'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: kpis),
              const SizedBox(width: 20),
              Expanded(child: ledger),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [kpis, const SizedBox(height: 20), ledger],
          );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dashboardTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(_shopName.isNotEmpty ? _shopName : l10n.dashboardMyShowroom, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                      tooltip: l10n.dashboardNotificationsTooltip,
                      onPressed: () => context.push(RouteNames.ownerNotifications),
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppColors.accentDanger, shape: BoxShape.circle),
                          child: Text('$_unreadNotifications',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  tooltip: l10n.dashboardSettingsTooltip,
                  onPressed: () => context.push(RouteNames.ownerSettings),
                ),
                IconButton(
                  tooltip: l10n.dashboardRefreshTooltip,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadDashboardData,
                ),
              ],
            ),
            // E1: quick actions sit between the header and the KPIs,
            // always visible (they do not scroll away with the ledger).
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DashboardQuickActions(),
            ),
            Expanded(
              // E2: shared loading / error states (the ledger's own
              // empty text lives in DashboardLedgerSection, untouched).
              child: _isLoading
                  ? AppLoadingState(message: l10n.dashboardLoading)
                  : _hasError
                      ? AppErrorState(message: l10n.dashboardLoadError, onRetry: _loadDashboardData)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: AppDimensions.spaceBetweenCards),
                          child: body,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
