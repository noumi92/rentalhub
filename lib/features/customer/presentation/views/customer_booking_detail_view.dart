import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/booking_detail_actions.dart';
import '../widgets/booking_detail_summary.dart';
import '../widgets/booking_ticket_card.dart';
import '../../../../l10n/app_localizations.dart';

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

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'requested':
        return l10n.statusRequestSent;
      case 'approved':
        return l10n.statusApproved;
      case 'payment_submitted':
        return l10n.statusProofSubmitted;
      case 'paid':
        return l10n.statusPaid;
      case 'active':
        return l10n.statusOnTrip;
      case 'completed':
        return l10n.statusCompleted;
      case 'rejected':
        return l10n.statusRejected;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = booking;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: onBack != null
                  ? IconButton(
                      tooltip: l10n.back,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.vehicleName ?? l10n.bookingDetailTitle(b.bookingId),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.bookingShopLine(b.shopName ?? l10n.rentalShowroom, b.bookingId),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.primaryContainer),
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
                    _statusLabel(l10n, b.status),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: Colors.white),
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
                        prefix: l10n.proofRejectedPrefix,
                      ),
                    ],
                    if (b.status == 'cancelled' &&
                        (b.rejectionReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      BookingDetailRejectionCard(
                        reason: b.rejectionReason!,
                        prefix: l10n.cancellationReasonPrefix,
                      ),
                    ],
                    if (b.status == 'payment_submitted') ...[
                      const SizedBox(height: 14),
                      BookingDetailInfoCard(
                        text: l10n.proofWithShop,
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
