import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

class RequestTriageCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onVerifyProof;
  final bool isProcessing;

  const RequestTriageCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    this.onVerifyProof,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  // The stored status code stays as-is; only the
                  // displayed label is localized (no upper-casing:
                  // Urdu has no case, and the label reads as a word).
                  _statusLabel(l10n, booking.status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
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
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      booking.customerPhone ?? '0300-1234567',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
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
                      ?.copyWith(fontWeight: FontWeight.w800),
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
                    'Rs. ${booking.totalAmount}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary),
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
                label: Text(l10n.requestsVerifyProof,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else if (booking.status == 'requested')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.requestsDecline,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentSuccess,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(l10n.requestsApprovePay,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
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
