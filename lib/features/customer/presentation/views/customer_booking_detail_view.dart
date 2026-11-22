import 'package:flutter/material.dart';

import '../../../../core/widgets/minimal_app_bar.dart';
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
  final VoidCallback? onViewActiveTrip;
  final VoidCallback? onTrackDispute;
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
    this.onViewActiveTrip,
    this.onTrackDispute,
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
      case 'payment_rejected':
        return l10n.statusProofRejected;
      case 'paid':
        return l10n.statusPaid;
      case 'active':
        return l10n.statusOnTrip;
      case 'completed':
        return l10n.statusCompleted;
      case 'disputed':
        return l10n.statusDisputed;
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
      // C1: MinimalAppBar owns the top inset — SafeArea(top: false)
      // avoids the double status-bar band (SH-M3 class).
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: b.vehicleName ?? l10n.bookingDetailTitle(b.bookingId),
              subtitle: l10n.bookingShopLine(b.shopName ?? l10n.rentalShowroom, b.bookingId),
              onBack: onBack,
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
                        fontWeight: FontWeight.w500, color: Colors.white),
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
                      onTap: (b.status == 'paid' || b.status == 'active')
                          ? () => onViewPass?.call()
                          : null,
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
                      onViewActiveTrip: onViewActiveTrip,
                      onTrackDispute: onTrackDispute,
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
