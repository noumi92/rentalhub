import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/sync_status_cubit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/booking_ticket_card.dart';

class CustomerBookingsView extends StatefulWidget {
  final Function(BookingEntity booking)? onOpenBookingDetails;
  final Function(BookingEntity booking)? onPayAdvance;
  final Function(BookingEntity booking)? onRateTrip;

  const CustomerBookingsView({
    super.key,
    this.onOpenBookingDetails,
    this.onPayAdvance,
    this.onRateTrip,
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
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              // Tab root: no back button. The header's back policy
              // renders one only when the route can pop, which a
              // branch root never can.
              titleWidget: Text(
                'My Reservations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
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
                    // No background/selected/label colours: the theme's
                    // chipTheme drives both modes (dark-correct).
                    labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderSubtle,
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
                                      color: Theme.of(context).colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No ${_tabs[_selectedTab]} bookings found.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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

                                Widget card(SyncEntryStatus status) =>
                                    BookingTicketCard(
                                      booking: b,
                                      onTap: () => widget
                                          .onOpenBookingDetails
                                          ?.call(b),
                                      actionLabel: actionLabel,
                                      onAction: actionCallback,
                                      syncStatus: status,
                                    );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  // Phase B (B5): the per-item sync chip
                                  // follows the queue state.
                                  child: Builder(
                                    builder: (context) {
                                      // Prefer a provided cubit, else
                                      // the DI singleton, else no
                                      // chip (never throw for a
                                      // missing provider).
                                      final syncCubit =
                                          resolveSyncStatusCubit(context);
                                      if (syncCubit == null) {
                                        return card(
                                            SyncEntryStatus.synced);
                                      }
                                      return BlocBuilder<SyncStatusCubit,
                                          SyncStatusState>(
                                        bloc: syncCubit,
                                        builder: (context, sync) =>
                                            card(sync.byEntity[
                                                    b.bookingId] ??
                                                SyncEntryStatus.synced),
                                      );
                                    },
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

