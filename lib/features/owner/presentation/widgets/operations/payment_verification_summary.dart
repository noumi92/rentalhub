import 'package:flutter/material.dart';

import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../trust/data/services/trust_score_service.dart';

/// O19 (extracted from [OwnerPaymentVerificationView] so the view
/// stays under the 250-line cap): the booking summary card — vehicle,
/// customer, amounts, transaction id, the proof submission time and
/// the PW-18 risk context (live trust score, KYC state, prior trips).
/// The submission time renders only when the booking carries one
/// ([BookingEntity.proofSubmittedAt], stamped by
/// `updatePaymentProof`); older bookings without it show no line,
/// never an invented time.
class PaymentVerificationSummary extends StatelessWidget {
  const PaymentVerificationSummary({
    super.key,
    required this.booking,
    required this.trust,
  });

  final BookingEntity booking;
  final TrustScoreResult? trust;

  String _kycLabel(AppLocalizations l10n, String status) => {
        'verified': l10n.verified,
        'rejected': l10n.kycStatusRejected,
        'submitted': l10n.kycStatusSubmitted,
        'resubmitted': l10n.kycStatusSubmitted,
        'pending': l10n.kycStatusSubmitted,
      }[status] ??
      l10n.home2_kycNotStarted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = booking;
    final trust = this.trust;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _row(context, l10n.summaryVehicle, b.vehicleName ?? b.vehicleId),
            _row(context, l10n.requestsCustomerFallback,
                b.customerName ?? b.customerId),
            _row(context, l10n.editPhone, b.customerPhone ?? '—'),
            _row(context, l10n.packageLabel, b.packageType),
            _row(context, l10n.paymentVerificationTotalRent,
                l10n.amountRs(formatRs(b.totalAmount))),
            _row(context, l10n.paymentVerificationAdvanceDue,
                l10n.amountRs(formatRs(b.advanceRequired))),
            _row(context, l10n.paymentVerificationAdvancePaid,
                l10n.amountRs(formatRs(b.advancePaid))),
            _row(context, l10n.paymentVerificationTransactionId,
                b.transactionId ?? '—'),
            if (b.proofSubmittedAt != null)
              _row(
                context,
                l10n.paymentVerificationProofSubmittedAt,
                formatDateTime(context, b.proofSubmittedAt!),
              ),
            // PW-18: the risk context for the money decision — live
            // trust score, KYC state, prior trips. Nothing renders
            // until the computation arrives. No account is
            // highlighted: no per-booking destination account exists
            // on the entity, so there is no number to match against
            // the shop's accounts (that needs a destination field on
            // the booking, a data-layer change).
            if (trust != null) ...[
              const Divider(height: 16),
              Text(l10n.reputationTrustScoreValue(
                  trust.breakdown.total.toStringAsFixed(1))),
              Text(l10n.kycStatus(_kycLabel(l10n, trust.kycStatus))),
              Text(l10n.priorTripsCount(trust.completedTrips)),
            ],
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
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          // §10: the value flexes + ellipsizes (the contract sheet's
          // _fieldRow pattern) instead of overflowing at 360px / 1.35x
          // / Urdu on a long vehicle or customer name.
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
