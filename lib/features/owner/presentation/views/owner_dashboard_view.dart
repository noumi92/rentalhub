import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../widgets/dashboard/dashboard_kpis.dart';
import '../widgets/dashboard/dashboard_ledger_item.dart';

class OwnerDashboardView extends StatefulWidget {
  final String shopId;
  final VoidCallback? onBack;

  const OwnerDashboardView({
    super.key,
    this.shopId = 'shop-1',
    this.onBack,
  });

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  List<BookingEntity> _allBookings = [];
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
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
      final completed =
          list.where((b) => b.status == 'completed').toList();
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
          _unreadNotifications =
              notifications.where((n) => !n.read).length;
          _settleRate = settleRate;
        });
      }
    } catch (_) {} finally {
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

  /// Real month-on-month revenue change, from the bookings' pickup
  /// dates. Null when there is no last-month revenue to compare.
  String get _growthLabel {
    final now = DateTime.now();
    final thisMonth = _allBookings
        .where((b) =>
            (b.status == 'completed' ||
                b.status == 'active' ||
                b.status == 'paid') &&
            b.pickupTime.year == now.year &&
            b.pickupTime.month == now.month)
        .fold(0, (total, b) => total + b.totalAmount);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = _allBookings
        .where((b) =>
            (b.status == 'completed' ||
                b.status == 'active' ||
                b.status == 'paid') &&
            b.pickupTime.year == lastMonthDate.year &&
            b.pickupTime.month == lastMonthDate.month)
        .fold(0, (total, b) => total + b.totalAmount);
    if (lastMonth == 0) return 'No revenue last month';
    final pct = ((thisMonth - lastMonth) / lastMonth * 100).round();
    return '${pct >= 0 ? '+' : ''}$pct% vs last month';
  }

  List<BookingEntity> get _ledger {
    final sorted = List<BookingEntity>.of(_allBookings)
      ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
    return sorted.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Showroom Revenue & Operations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(_shopName.isNotEmpty ? _shopName : 'My Showroom', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                      tooltip: 'Notifications',
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
                  tooltip: 'Shop settings',
                  onPressed: () => context.push(RouteNames.ownerSettings),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadDashboardData,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DashboardKpis(
                            totalRevenue: _totalRevenue,
                            growthLabel: _growthLabel,
                            activeCount: _activeCount,
                            completedCount: _completedCount,
                            settleLabel: _settleRate == null
                                ? 'No completed trips yet'
                                : '${(_settleRate! * 100).round()}% deposits settled',
                            waitingCount: _waitingCount,
                            fleetAvailable: _fleetAvailable,
                            fleetTotal: _fleetTotal,
                          ),
                          const SizedBox(height: 20),
                          Text('Completed Trip Ledger & Settlements', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                          const SizedBox(height: 10),
                          if (_allBookings.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('No trips yet — bookings will appear here.',
                                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                              ),
                            )
                          else
                            ..._ledger.map((b) => DashboardLedgerItem(
                                  bookingId: b.bookingId,
                                  vehicleName: b.vehicleName ?? 'Vehicle',
                                  customerName: b.customerName ?? 'Customer',
                                  amount: b.totalAmount,
                                  status: b.status,
                                )),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

}

