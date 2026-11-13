import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../widgets/dashboard/dashboard_app_bar.dart';
import '../widgets/dashboard/dashboard_greeting_header.dart';
import '../widgets/dashboard/dashboard_kpis.dart';
import '../widgets/dashboard/dashboard_ledger_section.dart';
import '../widgets/dashboard/dashboard_quick_actions.dart';
import '../widgets/dashboard/dashboard_schedule_section.dart';
import '../widgets/dashboard/revenue_kpi_card.dart';

class OwnerDashboardView extends StatefulWidget {
  final String shopId;

  const OwnerDashboardView({
    super.key,
    required this.shopId,
  });

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  List<BookingEntity> _allBookings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _shopName = '';
  String _ownerName = '';
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
      String ownerName = '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(widget.shopId)
            .get();
        final data = doc.data() ?? {};
        shopName = (data['name'] ?? data['shopName'] ?? '') as String;
        ownerName = (data['owner_name'] ?? data['ownerName'] ?? '') as String;
      } catch (_) {}
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
          _ownerName = ownerName;
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

  /// Audit impl (O29): today's earnings — today's completed / paid
  /// bookings revenue, by pickup date.
  int get _todayEarnings {
    final now = DateTime.now();
    return _allBookings
        .where((b) =>
            (b.status == 'completed' ||
                b.status == 'active' ||
                b.status == 'paid') &&
            b.pickupTime.year == now.year &&
            b.pickupTime.month == now.month &&
            b.pickupTime.day == now.day)
        .fold(0, (total, b) => total + b.totalAmount);
  }

  int get _activeCount => _allBookings.where((b) => b.status == 'active').length;
  int get _completedCount => _allBookings.where((b) => b.status == 'completed').length;
  int get _waitingCount => _allBookings
      .where((b) => b.status == 'requested' || b.status == 'payment_submitted')
      .length;

  int _monthRevenue(int year, int month) => _allBookings
      .where((b) =>
          (b.status == 'completed' ||
              b.status == 'active' ||
              b.status == 'paid') &&
          b.pickupTime.year == year &&
          b.pickupTime.month == month)
      .fold(0, (total, b) => total + b.totalAmount);

  int? get _growthPct {
    final now = DateTime.now();
    final thisMonth = _monthRevenue(now.year, now.month);
    final lastMonthDate = DateTime(now.year, now.month - 1);
    final lastMonth = _monthRevenue(lastMonthDate.year, lastMonthDate.month);
    if (lastMonth == 0) return null;
    return ((thisMonth - lastMonth) / lastMonth * 100).round();
  }

  List<BookingEntity> get _ledger => (List<BookingEntity>.of(_allBookings)
        ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime)))
      .take(8)
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final growthPct = _growthPct;
    final greeting = DashboardGreetingHeader(
      ownerName: _ownerName,
      shopName: _shopName,
    );
    final kpis = DashboardKpis(
      totalRevenue: _totalRevenue,
      todayEarnings: _todayEarnings,
      growthLabel: growthPct == null ? l10n.dashboardNoRevenueLastMonth : l10n.dashboardGrowthLabel('${growthPct >= 0 ? '+' : ''}$growthPct'),
      growthTrend: growthPct == null || growthPct == 0 ? KpiTrend.neutral : growthPct > 0 ? KpiTrend.up : KpiTrend.down,
      activeCount: _activeCount,
      completedCount: _completedCount,
      settleLabel: _settleRate == null
          ? l10n.dashboardNoCompletedTrips
          : l10n.dashboardSettleRate((_settleRate! * 100).round()),
      waitingCount: _waitingCount,
      fleetAvailable: _fleetAvailable,
      fleetTotal: _fleetTotal,
    );
    final schedule = DashboardScheduleSection(bookings: _allBookings);
    final ledger = DashboardLedgerSection(
      isEmpty: _allBookings.isEmpty,
      ledger: _ledger,
    );
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        greeting,
        const SizedBox(height: 16),
        kpis,
        const SizedBox(height: 20),
        schedule,
      ],
    );
    final body = isMediumOrLarger(context)
        ? Row(
            key: const Key('dashboard-two-columns'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: 20),
              Expanded(child: ledger),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              greeting,
              const SizedBox(height: 16),
              kpis,
              const SizedBox(height: 20),
              schedule,
              const SizedBox(height: 20),
              ledger,
            ],
          );
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            DashboardAppBar(
              shopName: _shopName,
              unreadNotifications: _unreadNotifications,
              onRefresh: _loadDashboardData,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DashboardQuickActions(),
            ),
            Expanded(
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
