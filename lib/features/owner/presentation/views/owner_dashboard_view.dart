import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_request_time.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../widgets/dashboard/dashboard_app_bar.dart';
import '../widgets/dashboard/dashboard_body.dart';
import '../widgets/dashboard/dashboard_booking_stats.dart';
import '../widgets/dashboard/dashboard_greeting_header.dart';
import '../widgets/dashboard/dashboard_kpis.dart';
import '../widgets/dashboard/dashboard_ledger_section.dart';
import '../widgets/dashboard/dashboard_live_bookings.dart';
import '../widgets/dashboard/dashboard_live_notifications.dart';
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
  // Live updates (Item 2): the bookings subscription behind the KPIs, schedule and ledger. Fleet, notifications and shop names stay one-time loads (pull-to-refresh re-runs this load; the app-bar refresh button is gone).
  final _liveBookings = DashboardLiveBookings();
  // PW-19 (UI/UX audit 2026-11-15): the unread-badge subscription
  // — the one-time count above goes stale while the dashboard is
  // open; this keeps it live.
  final _liveNotifications = DashboardLiveNotifications();
  // FG-1: the waiting bookings' request times, for the oldest wait
  // (see booking_request_time.dart — the entity carries no timestamp).
  Map<String, DateTime?> _requestTimes = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _liveBookings.dispose();
    _liveNotifications.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(widget.shopId);
      final notifications = await sl<NotificationDataSource>()
          .getShopNotifications(widget.shopId);
      // PW-19: the badge then stays live on the notifications
      // stream (same live pattern as bookings) instead of freezing
      // at this one-time count.
      await _liveNotifications.subscribe(
        shopId: widget.shopId,
        onUnreadCount: (n) { if (mounted) setState(() => _unreadNotifications = n); },
      );
      String shopName = '';
      String ownerName = '';
      try {
        // Shop-id linking (2026-11-15): the shops document is
        // `shop_<uid>`; the bare UID read always missed, so the
        // dashboard showed no shop/owner name.
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(await canonicalShopId(
                FirebaseFirestore.instance, widget.shopId))
            .get();
        final data = doc.data() ?? {};
        shopName = (data['name'] ?? data['shopName'] ?? '') as String;
        ownerName = (data['owner_name'] ?? data['ownerName'] ?? '') as String;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _shopName = shopName;
          _ownerName = ownerName;
          _fleetTotal = vehicles.length;
          _fleetAvailable =
              vehicles.where((v) => v.status == 'available').length;
          _unreadNotifications = notifications.where((n) => !n.read).length;
        });
      }
      // Live updates (Item 2): bookings come from the stream, not the one-time get this method used to do — the first emission paints the KPIs, schedule and ledger.
      // A false return means the bookings data source could not be
      // resolved (missing DI) — a load failure, so the error state
      // renders and its retry re-runs this method.
      if (!_liveBookings.subscribe(
        shopId: widget.shopId,
        onBookings: (list) { if (!mounted) return; setState(() => _allBookings = list); _refreshRequestTimes(list); },
        onSettleRate: (rate) { if (!mounted) return; setState(() => _settleRate = rate); },
      )) {
        if (mounted) setState(() => _hasError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _activeCount => _allBookings.where((b) => b.status == 'active').length;
  int get _completedCount => _allBookings.where((b) => b.status == 'completed').length;
  int get _waitingCount => _allBookings
      .where((b) => b.status == 'requested' || b.status == 'payment_submitted')
      .length;
  int get _newCount => _allBookings.where((b) => b.status == 'requested').length;
  int get _proofCount => _allBookings.where((b) => b.status == 'payment_submitted').length;

  // FG-1: the waiting bookings' request times (cached per session
  // by BookingRequestTimes) so the oldest wait can be shown.
  Future<void> _refreshRequestTimes(List<BookingEntity> list) async {
    final times = await BookingRequestTimes.fetch(list.map((b) => b.bookingId));
    if (mounted) setState(() => _requestTimes = {..._requestTimes, ...times});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Revenue numbers live in dashboard_booking_stats.dart now
    // (extracted so this view stays under the 250-line cap).
    final growth = growthPct(_allBookings);
    final waiting = _allBookings.where((b) => b.status == 'requested' || b.status == 'payment_submitted').toList();
    final oldestWait = oldestWaitFor(waiting, _requestTimes);
    final greeting = DashboardGreetingHeader(
      ownerName: _ownerName,
      shopName: _shopName,
    );
    final kpis = DashboardKpis(
      totalRevenue: monthRevenue(_allBookings),
      todayEarnings: todayEarnings(_allBookings),
      growthLabel: growth == null ? l10n.dashboardNoRevenueLastMonth : l10n.dashboardGrowthLabel('${growth >= 0 ? '+' : ''}$growth'),
      growthTrend: growth == null || growth == 0 ? KpiTrend.neutral : growth > 0 ? KpiTrend.up : KpiTrend.down,
      activeCount: _activeCount,
      completedCount: _completedCount,
      settleLabel: _settleRate == null
          ? l10n.dashboardNoCompletedTrips
          : l10n.dashboardSettleRate((_settleRate! * 100).round()),
      waitingCount: _waitingCount,
      newCount: _newCount,
      proofCount: _proofCount,
      oldestWaitLabel: oldestWait == null ? null : waitDurationLabel(l10n, oldestWait),
      onWaitingTap: () => context.go(RouteNames.ownerRequests),
      fleetAvailable: _fleetAvailable,
      fleetTotal: _fleetTotal,
    );
    // Phase 1 showroom redesign: one scroll column in the guide's
    // order — greeting, revenue + review, the 4+3 actions, the live
    // Active Rentals card, then schedule and ledger. Nothing is
    // dropped, only rearranged; the ledger moves to the second
    // column on medium screens and below the schedule on phones.
    final content = <Widget>[
      greeting,
      const SizedBox(height: 16),
      kpis,
      const SizedBox(height: 20),
      DashboardQuickActions(waitingCount: _waitingCount),
      const SizedBox(height: 16),
      ActiveRentalsTodayCard(activeCount: _activeCount),
      const SizedBox(height: 20),
      DashboardScheduleSection(bookings: _allBookings),
    ];
    final ledger = DashboardLedgerSection(
      isEmpty: _allBookings.isEmpty,
      ledger: ledgerFor(_allBookings),
    );
    final body = isMediumOrLarger(context)
        ? Row(
            key: const Key('dashboard-two-columns'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: content,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: ledger),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...content,
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
            ),
            Expanded(
              // Pull-to-refresh (user layout, 2026-11-16) re-runs
              // [_loadDashboardData] here.
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: DashboardBody(
                  isLoading: _isLoading,
                  hasError: _hasError,
                  quickActions: DashboardQuickActions(waitingCount: _waitingCount),
                  body: body,
                  loadingMessage: l10n.dashboardLoading,
                  errorMessage: l10n.dashboardLoadError,
                  onRetry: _loadDashboardData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
