import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/presentation/widgets/proof_image_viewer.dart';
import '../../../bookings/presentation/widgets/shop_payment_accounts.dart';
import '../widgets/operations/booking_fare_breakdown.dart';

/// Phase B (D3): the owner checks a submitted payment proof — the
/// screenshot and the transaction id — and either confirms the
/// payment (booking becomes paid and the handover can start) or
/// rejects it with a reason, sending the booking back to 'approved'
/// so the customer can upload a fresh proof.
class OwnerPaymentVerificationView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerPaymentVerificationView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerPaymentVerificationView> createState() =>
      _OwnerPaymentVerificationViewState();
}

class _OwnerPaymentVerificationViewState
    extends State<OwnerPaymentVerificationView> {
  bool _processing = false;

  BookingEntity get _booking => widget.booking;

  Future<void> _approve() async {
  final l10n = AppLocalizations.of(context)!;
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().verifyPayment(
        bookingId: _booking.bookingId,
        advanceAmount: _booking.advanceRequired,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context,
          l10n.paymentVerificationConfirmed(_booking.bookingId));
      // Audit §5 item 3 (O18): approval lands on the Booking
      // Confirmed screen, not straight on handover.
      // Registrar: RouteNames.ownerBookingConfirmed =
      // '/owner/booking-confirmed/:id' (see
      // audit_impl_manifest_worker_a.md).
      context.pushReplacement(
        '/owner/booking-confirmed/${_booking.bookingId}',
      );
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.paymentVerificationConfirmFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
  final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentVerificationRejectTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.paymentVerificationRejectNote),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.paymentVerificationReasonLabel,
                hintText: l10n.paymentVerificationReasonHint,
                // OW-m29: 16 dp, same as every other dialog field.
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: Text(l10n.paymentVerificationRejectButton),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().rejectPaymentProof(
        bookingId: _booking.bookingId,
        reason: reason,
      );
      if (!mounted) return;
      AppFeedback.showInfo(
          context, l10n.paymentVerificationRejected);
      context.pop();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.paymentVerificationRejectFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _row(String label, String value) {
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
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final b = _booking;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.paymentVerificationTitle,
              subtitle: l10n.paymentVerificationBooking(b.bookingId),
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row(l10n.summaryVehicle, b.vehicleName ?? b.vehicleId),
                            _row(l10n.requestsCustomerFallback, b.customerName ?? b.customerId),
                            _row(l10n.editPhone, b.customerPhone ?? '—'),
                            _row(l10n.packageLabel, b.packageType),
                            _row(l10n.paymentVerificationTotalRent, l10n.amountRs(formatRs(b.totalAmount))),
                            _row(l10n.paymentVerificationAdvanceDue, l10n.amountRs(formatRs(b.advanceRequired))),
                            _row(l10n.paymentVerificationAdvancePaid, l10n.amountRs(formatRs(b.advancePaid))),
                            _row(l10n.paymentVerificationTransactionId, b.transactionId ?? '—'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Audit §5 item 2 (O15): fare breakdown — daily
                    // rate × days, dates + times, trip tag, remaining.
                    BookingFareBreakdown(booking: b),
                    const SizedBox(height: 14),
                    // §10: the method/account the proof was paid to.
                    // No per-booking assigned account exists on the
                    // entity, so the shop's configured accounts are
                    // shown for the owner to cross-check the TID against.
                    ShopPaymentAccounts(
                      shopId: b.shopId,
                      title: l10n.paymentAccountsDirect,
                    ),
                    const SizedBox(height: 14),
                    Text(l10n.paymentVerificationScreenshotTitle, style: Theme.of(context) .textTheme .titleSmall ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (b.paymentProofUrl != null)
                      ProofImageViewer(imageUrl: b.paymentProofUrl!)
                    else
                      Text(l10n.paymentVerificationNoScreenshot),
                    if (b.rejectionReason != null) ...[
                      const SizedBox(height: 14),
                      Text(l10n.paymentVerificationPreviouslyRejected(b.rejectionReason!), style: Theme.of(context) .textTheme .bodyMedium ?.copyWith(color: AppColors.warningTextFor(Theme.of(context).brightness))),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: DebouncedButton(
                        text: _processing
                            ? l10n.paymentVerificationConfirming
                            : l10n.paymentVerificationConfirmButton(formatRs(b.advanceRequired)),
                        icon: Icons.check_circle_rounded,
                        isLoading: _processing,
                        onPressed: _approve,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _reject,
                        icon: Icon(Icons.close_rounded,
                            color: AppColors.dangerTextFor(
                                Theme.of(context).brightness)),
                        label: Text(l10n.paymentVerificationRejectButton,
                            style: TextStyle(
                                color: AppColors.dangerTextFor(
                                    Theme.of(context).brightness))),
                      ),
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
