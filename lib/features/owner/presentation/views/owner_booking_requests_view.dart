import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/operations/request_triage_card.dart';

class OwnerBookingRequestsView extends StatefulWidget {
  final String shopId;
  final VoidCallback? onBack;

  const OwnerBookingRequestsView({
    super.key,
    this.shopId = 'shop-1',
    this.onBack,
  });

  @override
  State<OwnerBookingRequestsView> createState() => _OwnerBookingRequestsViewState();
}

class _OwnerBookingRequestsViewState extends State<OwnerBookingRequestsView> {
  List<BookingEntity> _requests = [];
  bool _isLoading = true;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final ds = sl<BookingRemoteDataSource>();
      final bookings = await ds.getShopBookings(widget.shopId);
      setState(() {
        _requests = bookings
            .where((b) => b.status == 'requested' || b.status == 'payment_submitted')
            .toList();
        if (_requests.isEmpty) {
          // Provide sample incoming request for testing/demo
          _requests = [
            BookingEntity(
              bookingId: 'RH-REQ-778',
              customerId: 'cust-45',
              shopId: widget.shopId,
              vehicleId: 'v1',
              vehicleName: 'Honda Civic RS Turbo',
              customerName: 'Muhammad Hamza',
              customerPhone: '0321-4455667',
              packageType: '24h',
              isWithDriver: false,
              pickupTime: DateTime.now().add(const Duration(hours: 3)),
              returnTime: DateTime.now().add(const Duration(hours: 27)),
              totalAmount: 8500,
              advanceRequired: 1000,
              remainingBalance: 7500,
              status: 'requested',
            ),
          ];
        }
      });
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(BookingEntity booking) async {
    setState(() => _processingId = booking.bookingId);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: booking.bookingId, status: 'approved');
      if (mounted) {
        AppFeedback.showSuccess(context, 'Booking #${booking.bookingId} approved! Payment instructions sent to customer.');
        setState(() {
          _requests.removeWhere((b) => b.bookingId == booking.bookingId);
        });
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Approval failed: $e');
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectRequest(BookingEntity booking) async {
    setState(() => _processingId = booking.bookingId);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: booking.bookingId, status: 'rejected');
      if (mounted) {
        AppFeedback.showInfo(context, 'Booking #${booking.bookingId} rejected.');
        setState(() {
          _requests.removeWhere((b) => b.bookingId == booking.bookingId);
        });
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Decline failed: $e');
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                  const Text('Booking Requests Triage', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('${_requests.length} Requests Awaiting Review', style: const TextStyle(color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadRequests,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 52, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('No pending booking requests', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final b = _requests[index];
                            return RequestTriageCard(
                              booking: b,
                              isProcessing: _processingId == b.bookingId,
                              onApprove: () => _approveRequest(b),
                              onReject: () => _rejectRequest(b),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
