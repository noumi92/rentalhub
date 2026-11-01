import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/active_trip_floating_card.dart';
import '../widgets/customer_stats_row.dart';

class CustomerDashboardView extends StatefulWidget {
  final VoidCallback? onExploreShops;
  final VoidCallback? onOpenBookings;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSos;
  final Function(BookingEntity booking)? onOpenActiveBooking;

  const CustomerDashboardView({
    super.key,
    this.onExploreShops,
    this.onOpenBookings,
    this.onOpenDocuments,
    this.onOpenSos,
    this.onOpenActiveBooking,
  });

  @override
  State<CustomerDashboardView> createState() => _CustomerDashboardViewState();
}

class _CustomerDashboardViewState extends State<CustomerDashboardView> {
  List<BookingEntity> _bookings = [];
  bool _isLoading = true;

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
      if (mounted) {
        setState(() {
          _bookings = list;
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
                  Text('RentalHub Pakistan • Verified Traveler',
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
                        trustScore: 4.8,
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
                            child: _buildServiceButton(
                              icon: Icons.storefront_rounded,
                              label: 'Explore Shops',
                              color: AppColors.royalNavy,
                              onTap: widget.onExploreShops,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildServiceButton(
                              icon: Icons.calendar_month_rounded,
                              label: 'My Bookings',
                              color: AppColors.sunsetOrange,
                              onTap: widget.onOpenBookings,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildServiceButton(
                              icon: Icons.badge_outlined,
                              label: 'KYC Docs',
                              color: AppColors.emeraldGreen,
                              onTap: widget.onOpenDocuments,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.midnightNavy,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onOpenBookings,
                            child: const Text('View All',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sunsetOrange)),
                          ),
                        ],
                      ),
                      if (_isLoading)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_bookings.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.car_rental_outlined,
                                    size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                const Text('No bookings found yet.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: widget.onExploreShops,
                                  child: const Text('Discover Nearby Cars'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._bookings.take(3).map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                      color: AppColors.border),
                                ),
                                leading: const Icon(
                                    Icons.directions_car_rounded,
                                    color: AppColors.royalNavy),
                                title: Text(b.vehicleName ?? 'Rental Car',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                subtitle: Text(
                                    '${b.status.toUpperCase()} • Rs. ${b.totalAmount}'),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14),
                                onTap: () =>
                                    widget.onOpenActiveBooking?.call(b),
                              ),
                            )),
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

  Widget _buildServiceButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.midnightNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
