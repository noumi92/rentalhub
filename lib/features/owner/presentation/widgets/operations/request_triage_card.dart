import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/booking_request_time.dart';
import 'booking_fare_breakdown.dart';
import 'triage_trust_row.dart';

class RequestTriageCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onVerifyProof;
  final bool isProcessing;

  /// False hides the owner Approve/Decline row (e.g. a customer
  /// viewing a `requested` booking through the shared accounts
  /// view); the summary still renders. Defaults to true so the
  /// triage list is unaffected.
  final bool showActions;

  /// FG-4 (UI/UX audit 2026-11-15): the request time, for the
  /// "Waiting Xh Ym" line. When null the card reads the session
  /// cache populated by the owning view's fetch (see
  /// booking_request_time.dart) — a missing time renders no line,
  /// never an invented one.
  final DateTime? requestedAt;

  /// FG-4: the customer risk signal, when the caller already holds
  /// it (tests / embeds). When null the trust row loads it lazily
  /// via [TrustScoreService] and renders nothing until it arrives.
  final double? trustScore;
  final String? kycStatus;
  final int? completedTrips;

  const RequestTriageCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    this.onVerifyProof,
    this.isProcessing = false,
    this.showActions = true,
    this.requestedAt,
    this.trustScore,
    this.kycStatus,
    this.completedTrips,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    // FG-22 (UI/UX audit 2026-11-15): the status chip is coloured
    // by status — neutral for requested, orange for proof-waiting,
    // green for approved/paid/active/completed, red for rejected /
    // cancelled — mirroring _bookingStatusColor, instead of orange
    // for every status.
    final (Color chipBg, Color chipFg) = switch (booking.status) {
      'payment_submitted' => (
          AppColors.orangeContainerFor(brightness),
          AppColors.orangeTextFor(brightness),
        ),
      'approved' || 'paid' || 'active' || 'completed' => (
          AppColors.successContainerFor(brightness),
          AppColors.successTextFor(brightness),
        ),
      'rejected' || 'cancelled' => (
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
      _ => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
    // FG-4: the request time behind the wait line.
    final requestedAt = this.requestedAt ??
        BookingRequestTimes.cached(booking.bookingId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#${booking.bookingId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  // The stored status code stays as-is; only the
                  // displayed label is localized (no upper-casing:
                  // Urdu has no case, and the label reads as a word).
                  _statusLabel(l10n, booking.status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: chipFg,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withAlpha(25),
                child: Icon(Icons.person,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? l10n.requestsCustomerFallback,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      // §9: never a plausible-looking demo number — an
                      // unknown phone renders as an em dash.
                      booking.customerPhone ?? '—',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // FG-4: the customer risk signal — live trust score, KYC
          // badge, prior trips — loaded lazily by the row itself.
          TriageTrustRow(
            customerId: booking.customerId,
            trustScore: trustScore,
            kycStatus: kycStatus,
            completedTrips: completedTrips,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.vehicleName ?? l10n.requestsRequestedCar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ,
                ),
              ),
              const SizedBox(width: 8),
              // E3: the amount shrinks to fit instead of overflowing —
              // at 200% text scale 'Rs. 1250000' is wider than the card
              // and pushed the row 23px past the edge. A money amount
              // must stay fully visible, so it scales down rather than
              // ellipsizing.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    // C5: grouped rupees, via the localised wrapper.
                    l10n.amountRs(formatRs(booking.totalAmount)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        // OW-m34: the amount is orange text, not the
                        // secondary teal — same token as the status
                        // label above it.
                        color: AppColors.orangeTextFor(
                            Theme.of(context).brightness)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            // The package code (e.g. '24h') is stored data and stays
            // as-is; only the drive-mode words are localized.
            '${booking.packageType.toUpperCase()} • ${booking.isWithDriver ? l10n.requestsWithChauffeur : l10n.selfDrive}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          // Audit §5 item 2 (O14): the pickup/return dates and the
          // day count the request cards were missing.
          Text(
            // Audit 2026-11-15 DS-5: localized day + time, never a bare DateFormat.
            '${formatDayTime(context, booking.pickupTime)} → ${formatDayTime(context, booking.returnTime)} • ${l10n.bookingDaysCount(bookingDayCount(booking))}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          // FG-4: how long the request has waited — the card's job
          // is "decide oldest first". No known request time renders
          // no line, never an invented one.
          if (requestedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.requestsWaitingTime(waitDurationLabel(
                  l10n, DateTime.now().difference(requestedAt))),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: booking.status == 'payment_submitted'
                        ? AppColors.warningTextFor(brightness)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          // Phase B (D1): the actions depend on where the booking is
          // in the pipeline — only new requests can be approved or
          // declined; a submitted proof is verified on the detail
          // screen; an approved booking just waits for payment.
          if (booking.status == 'payment_submitted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : onVerifyProof,
                icon: const Icon(Icons.fact_check_rounded, size: 18),
                label: Text(l10n.requestsVerifyProof),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else if (booking.status == 'requested' && showActions)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      // §9: theme danger tokens, not raw red shades.
                      foregroundColor: AppColors.dangerTextFor(
                          Theme.of(context).brightness),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.requestsDecline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      // §9: white on accentSuccess #10B981 is ~2.5:1;
                      // accentSuccessStrong #047857 is 5.48:1.
                      backgroundColor: AppColors.accentSuccessStrong,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.requestsApprovePay),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The stored status code stays as-is; only the displayed label is
/// localized. Unknown codes fall back to the raw code.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
