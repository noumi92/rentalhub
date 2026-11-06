import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/booking_detail_actions.dart';
import '../widgets/booking_detail_summary.dart';
import '../widgets/booking_ticket_card.dart';

/// Phase A (A1): the customer booking detail screen — the hub for one
/// booking. It shows the ticket (with the QR once the booking is paid or
/// active), the booking summary, and the actions that make sense for the
/// booking's current status. It is what "My Bookings" opens when a row is
/// tapped.
class CustomerBookingDetailView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onPayAdvance;
  final VoidCallback? onViewPass;
  final VoidCallback? onCancel;
  final VoidCallback? onRateTrip;
  final VoidCallback? onFileDispute;
  final VoidCallback? onBrowseShops;
  final VoidCallback? onBack;

  const CustomerBookingDetailView({
    super.key,
    required this.booking,
    this.onPayAdvance,
    this.onViewPass,
    this.onCancel,
    this.onRateTrip,
    this.onFileDispute,
    this.onBrowseShops,
    this.onBack,
  });

  String _statusLabel(String status) {
    switch (status) {
      case 'requested':
        return 'Request sent';
      case 'approved':
        return 'Approved';
      case 'payment_submitted':
        return 'Proof submitted';
      case 'paid':
        return 'Paid';
      case 'active':
        return 'On trip';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.vehicleName ?? 'Booking ${b.bookingId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.shopName ?? 'Rental Showroom'} • ${b.bookingId}',
                    style: const TextStyle(
                      color: AppColors.textLavender,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(b.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BookingTicketCard(
                      booking: b,
                      onTap: () {
                        // The ticket is only a pass once the booking is
                        // paid or active — before that there is no QR to
                        // show, so the tap does nothing.
                        if (b.status == 'paid' || b.status == 'active') {
                          onViewPass?.call();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    BookingDetailSummary(booking: b),
                    if (b.status == 'rejected' &&
                        (b.rejectionReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      BookingDetailRejectionCard(reason: b.rejectionReason!),
                    ],
                    if (b.status == 'approved' &&
                        (b.rejectionReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      BookingDetailRejectionCard(
                        reason: b.rejectionReason!,
                        prefix:
                            'Your payment proof was rejected — please upload a new one: ',
                      ),
                    ],
                    if (b.status == 'cancelled' &&
                        (b.rejectionReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      BookingDetailRejectionCard(
                        reason: b.rejectionReason!,
                        prefix: 'Cancellation reason: ',
                      ),
                    ],
                    if (b.status == 'payment_submitted') ...[
                      const SizedBox(height: 14),
                      BookingDetailInfoCard(
                        text: 'Your payment proof is with the shop. '
                            'You will see the pickup pass here once it is verified.',
                      ),
                    ],
                    const SizedBox(height: 20),
                    BookingDetailActions(
                      booking: b,
                      onPayAdvance: onPayAdvance,
                      onViewPass: onViewPass,
                      onCancel: onCancel,
                      onRateTrip: onRateTrip,
                      onFileDispute: onFileDispute,
                      onBrowseShops: onBrowseShops,
                    ),
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
