import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../data/services/customer_wallet_service.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/active_trip_floating_card.dart';
import '../widgets/customer_service_button.dart';
import '../widgets/customer_stats_row.dart';
import '../widgets/dashboard_wallet_card.dart';
import '../widgets/dashboard_recent_bookings.dart';

class CustomerDashboardView extends StatefulWidget {
  final VoidCallback? onExploreShops;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSos;
  final VoidCallback? onOpenWallet;
  final Function(BookingEntity booking)? onOpenActiveBooking;

  const CustomerDashboardView({
    super.key,
    this.onExploreShops,
    this.onOpenBookings,
    this.onOpenDocuments,
    this.onOpenSos,
    this.onOpenWallet,
    this.onOpenActiveBooking,
  });

  @override
  State<CustomerDashboardView> createState() => _CustomerDashboardViewState();
}

class _CustomerDashboardViewState extends State<CustomerDashboardView> {
  List<BookingEntity> _bookings = [];
  bool _isLoading = true;
  double? _trustScore;
  CustomerWalletSummary? _wallet;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      String uid = 'cust-101';
      try {
        final u = FirebaseAuth.instance.currentUser;
        if (u != null) uid = u.uid;
      } catch (_) {}

      final ds = sl<BookingRemoteDataSource>();
      final list = await ds.getCustomerBookings(uid);
      // E1: the trust score comes from the customer's own `users`
      // record (created at sign-in, 5.0 by default) — not a hardcoded
      // number. No record yet means no score shown.
      double? trustScore;
      try {
        if (sl.isRegistered<FirestoreService>()) {
          trustScore = (await sl<FirestoreService>().getUser(uid))?.trustScore;
        }
      } catch (_) {}
      // E1/F1: the wallet summary comes from the same service the
      // wallet screen uses (advances + deposits, not the shop ledger).
      CustomerWalletSummary? wallet;
      try {
        wallet = await CustomerWalletService(
          bookings: ds,
          deposits: sl<SecurityDepositDataSource>(),
        ).load(uid);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _bookings = list;
          _trustScore = trustScore;
          _wallet = wallet;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  BookingEntity? get _activeBooking {
    for (final b in _bookings) {
      if (b.status == 'paid' ||
          b.status == 'approved' ||
          b.status == 'payment_submitted' ||
          b.status == 'active') {
        return b;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeBooking;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 120,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Customer Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 2),
                  Text('RentalHub Pakistan',
                      style: TextStyle(
                          color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sos_rounded, color: Colors.white),
                  tooltip: 'Emergency SOS',
                  onPressed: widget.onOpenSos,
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCustomerData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (active != null) ...[
                        ActiveTripFloatingCard(
                          booking: active,
                          onTap: () => widget.onOpenActiveBooking?.call(active),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomerStatsRow(
                        totalTrips: _bookings.length,
                        activeBookings: active != null ? 1 : 0,
                        trustScore: _trustScore,
                      ),
                      const SizedBox(height: 16),
                      DashboardWalletCard(
                        summary: _wallet,
                        onTap: widget.onOpenWallet,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Quick Services',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.midnightNavy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomerServiceButton(
                              icon: Icons.storefront_rounded,
                              label: 'Explore Shops',
                              color: AppColors.royalNavy,
                              onTap: widget.onExploreShops,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomerServiceButton(
                              icon: Icons.calendar_month_rounded,
                              label: 'My Bookings',
                              color: AppColors.sunsetOrange,
                              onTap: widget.onOpenBookings,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomerServiceButton(
                              icon: Icons.badge_outlined,
                              label: 'KYC Docs',
                              color: AppColors.emeraldGreen,
                              onTap: widget.onOpenDocuments,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DashboardRecentBookings(
                        isLoading: _isLoading,
                        bookings: _bookings,
                        onViewAll: widget.onOpenBookings,
                        onOpenBooking: widget.onOpenActiveBooking,
                        onExploreShops: widget.onExploreShops,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

