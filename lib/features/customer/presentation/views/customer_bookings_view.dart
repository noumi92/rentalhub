import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/booking_ticket_card.dart';
import '../widgets/customer_bottom_nav.dart';

class CustomerBookingsView extends StatefulWidget {
  final Function(BookingEntity booking)? onOpenBookingDetails;
  final Function(BookingEntity booking)? onPayAdvance;
  final Function(BookingEntity booking)? onRateTrip;
  final VoidCallback? onBack;

  const CustomerBookingsView({
    super.key,
    this.onOpenBookingDetails,
    this.onPayAdvance,
    this.onRateTrip,
    this.onBack,
  });

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView> {
  int _selectedTab = 0;
  final List<String> _tabs = ['All', 'Pending', 'Approved', 'Active', 'Done'];
  List<BookingEntity> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
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
          _allBookings = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<BookingEntity> get _filteredBookings {
    switch (_selectedTab) {
      case 1:
        return _allBookings
            .where((b) =>
                b.status == 'requested' || b.status == 'payment_submitted')
            .toList();
      case 2:
        return _allBookings.where((b) => b.status == 'approved').toList();
      case 3:
        return _allBookings
            .where((b) => b.status == 'paid' || b.status == 'active')
            .toList();
      case 4:
        return _allBookings
            .where((b) =>
                b.status == 'completed' ||
                b.status == 'cancelled' ||
                b.status == 'rejected')
            .toList();
      default:
        return _allBookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredBookings;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Text(
                'My Reservations',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = i == _selectedTab;
                  return ChoiceChip(
                    label: Text(_tabs[i]),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedTab = i),
                    selectedColor: AppColors.midnightNavy,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.midnightNavy,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.midnightNavy
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      child: list.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_rounded,
                                      size: 46,
                                      color: AppColors.slateGray
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No ${_tabs[_selectedTab]} bookings found.',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final b = list[index];
                                String? actionLabel;
                                VoidCallback? actionCallback;

                                if (b.status == 'approved') {
                                  actionLabel = 'Pay Advance';
                                  actionCallback =
                                      () => widget.onPayAdvance?.call(b);
                                } else if (b.status == 'paid' ||
                                    b.status == 'active') {
                                  actionLabel = 'View Pass';
                                  actionCallback = () =>
                                      widget.onOpenBookingDetails?.call(b);
                                } else if (b.status == 'completed') {
                                  actionLabel = 'Rate Trip';
                                  actionCallback =
                                      () => widget.onRateTrip?.call(b);
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: BookingTicketCard(
                                    booking: b,
                                    onTap: () =>
                                        widget.onOpenBookingDetails?.call(b),
                                    actionLabel: actionLabel,
                                    onAction: actionCallback,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

