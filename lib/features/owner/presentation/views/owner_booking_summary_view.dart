import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../widgets/operations/booking_fare_breakdown.dart';

/// Next-step batch (2026-11-21): the read-only booking summary.
///
/// The owner detail route sends terminal bookings (`completed` /
/// `rejected` / `cancelled`) and `disputed` here — never the payment
/// accounts view, whose Upload Proof CTA used to render
/// unconditionally for them. No payment actions at all: customer,
/// vehicle, amounts and status only. For `disputed` the shared
/// resolver supplies the one next step (View / Resolve Dispute);
/// for `completed` it supplies Rate customer — the only
/// post-return entry point to rate the customer, since the return
/// flow lands on All Bookings. `rejected` / `cancelled` get no
/// button.
class OwnerBookingSummaryView extends StatelessWidget {
  const OwnerBookingSummaryView({
    super.key,
    required this.booking,
    this.onBack,
  });

  final BookingEntity booking;
  final VoidCallback? onBack;

  String _statusLabel(AppLocalizations l10n) {
    switch (booking.status) {
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
      case 'disputed':
        return l10n.statusDisputed;
      default:
        return booking.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = booking;
    final when =
        DateFormat('d MMM yyyy, h:mm a').format(b.pickupTime);
    // The resolver's steps for the statuses that land here are
    // `viewDispute` (disputed) and `rateCustomer` (completed);
    // `rejected` / `cancelled` resolve to `none`. Gate on the
    // KIND, not just hasAction: this view must never render a
    // Start Handover / return button if it is ever reached with a
    // `paid` / `active` booking — those belong on the Confirmed
    // view, and a stray handover button here would be a wrong
    // next step.
    final nextStep = resolveOwnerNextStep(b);
    final showDisputeStep =
        nextStep.kind == BookingNextStepKind.viewDispute;
    final disputeDestination = nextStep.destination(b);
    final showRateStep =
        nextStep.kind == BookingNextStepKind.rateCustomer;
    final rateDestination = nextStep.destination(b);
    return Scaffold(
      // C1: MinimalAppBar owns the top inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.requestsTitle,
              subtitle: l10n.paymentVerificationBooking(b.bookingId),
              onBack: onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row(context, l10n.requestsCustomerFallback,
                                b.customerName ?? '—'),
                            _row(context, l10n.summaryVehicle,
                                b.vehicleName ?? b.vehicleId),
                            if (b.vehiclePlate != null)
                              _row(context, l10n.summaryPlate,
                                  b.vehiclePlate!),
                            _row(context, l10n.summaryPickupTime, when),
                            _row(context, l10n.bookingFareTotal,
                                l10n.amountRs(formatRs(b.totalAmount))),
                            _row(context, l10n.bookingFareAdvancePaid,
                                l10n.amountRs(formatRs(b.advancePaid))),
                            _row(context, l10n.bookingFareRemaining,
                                l10n.amountRs(
                                    formatRs(b.remainingBalance))),
                            _row(context, l10n.editVehicleStatus,
                                _statusLabel(l10n)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    BookingFareBreakdown(booking: b),
                    if (b.rejectionReason != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        b.rejectionReason!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (showDisputeStep && disputeDestination != null) ...[
                      const SizedBox(height: 20),
                      DebouncedButton(
                        text: nextStep.label(l10n, b),
                        icon: Icons.gavel_rounded,
                        onPressed: () => context.push(disputeDestination),
                      ),
                    ],
                    if (showRateStep && rateDestination != null) ...[
                      const SizedBox(height: 20),
                      DebouncedButton(
                        text: nextStep.label(l10n, b),
                        icon: Icons.star_rate_rounded,
                        onPressed: () => context.push(rateDestination),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
