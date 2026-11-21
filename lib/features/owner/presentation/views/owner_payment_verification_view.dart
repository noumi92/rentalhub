import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/presentation/widgets/proof_image_viewer.dart';
import '../../../bookings/presentation/widgets/shop_payment_accounts.dart';
import '../../../trust/data/services/trust_score_service.dart';
import '../widgets/operations/booking_fare_breakdown.dart';
import '../widgets/operations/payment_reject_dialog.dart';
import '../widgets/operations/payment_verification_actions.dart';
import '../widgets/operations/payment_verification_summary.dart';

/// Phase B (D3): the owner checks a submitted payment proof — the
/// screenshot and the transaction id — and either confirms the
/// payment (booking becomes paid and the handover can start) or
/// rejects it with a reason, sending the booking back to 'approved'
/// so the customer can upload a fresh proof.
class OwnerPaymentVerificationView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  /// PW-18: a preloaded trust result (tests / embeds). When null
  /// the view loads it from [TrustScoreService] in initState.
  final TrustScoreResult? trustResult;

  const OwnerPaymentVerificationView({
    super.key,
    required this.booking,
    this.onBack,
    this.trustResult,
  });

  @override
  State<OwnerPaymentVerificationView> createState() =>
      _OwnerPaymentVerificationViewState();
}

class _OwnerPaymentVerificationViewState
    extends State<OwnerPaymentVerificationView> {
  bool _processing = false;

  /// Audit 2026-11-20 (§10): the amount the customer actually paid,
  /// as shown on the proof — prefilled with the required advance,
  /// editable. Recording only the required advance used to lose the
  /// excess (the booking kept a balance due already paid).
  final _amountController = TextEditingController();

  int get _verifiedAmount => (int.tryParse(_amountController.text.trim()) ?? _booking.advanceRequired).clamp(0, _booking.totalAmount);

  /// PW-18: the customer risk context (live trust score, KYC state,
  /// prior trips) for the money decision. Null until loaded.
  TrustScoreResult? _trust;

  @override
  void initState() {
    super.initState();
    _trust = widget.trustResult;
    _amountController.text = _booking.advanceRequired.toString();
    if (_trust == null) {
      const TrustScoreService().compute(_booking.customerId).then((r) {
        if (mounted && r != null) setState(() => _trust = r);
      });
    }
  }

  @override
  void dispose() { _amountController.dispose(); super.dispose(); }

  BookingEntity get _booking => widget.booking;

  Future<void> _approve() async {
  final l10n = AppLocalizations.of(context)!;
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) { AppFeedback.showError(context, l10n.manualBookingAmountInvalid); return; }
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().verifyPayment(
        bookingId: _booking.bookingId,
        advanceAmount: amount.clamp(0, _booking.totalAmount),
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.paymentVerificationConfirmed(_booking.bookingId));
      // Next-step batch (2026-11-21): Confirm lands back on All
      // Bookings (the list syncs its filter from `?filter=all`,
      // and its stream is live, so the new `paid` status shows
      // without a reload) instead of the Confirmed screen — the
      // onward journey is the Start Handover button on the paid
      // card in the list.
      goToAllOwnerBookings(context);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.paymentVerificationConfirmFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
  final l10n = AppLocalizations.of(context)!;
    final reason = await showPaymentRejectDialog(context);
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _processing = true);
    try {
      await sl<BookingRemoteDataSource>().rejectPaymentProof(
        bookingId: _booking.bookingId,
        reason: reason,
      );
      if (!mounted) return;
      AppFeedback.showInfo(context, l10n.paymentVerificationRejected);
      // Next-step batch (2026-11-21): same landing as Confirm —
      // All Bookings, where the booking now shows as `approved`
      // and the customer can upload a fresh proof.
      goToAllOwnerBookings(context);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.paymentVerificationRejectFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final b = _booking;
    // Item 8: never hand the stored value raw — a bare key is not a URL; resolveStoredMediaUrl signs it, blank shows "no screenshot".
    final proofUrl = b.paymentProofUrl == null ? '' : (sl.isRegistered<CPanelStorageClient>() ? sl<CPanelStorageClient>().resolveStoredMediaUrl(b.paymentProofUrl!) : b.paymentProofUrl!);
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
                    // O19: the proof is waiting on this owner — the
                    // banner says so up front, before the amounts.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainerFor(
                            Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 18,
                            color: AppColors.warningTextFor(
                                Theme.of(context).brightness),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.paymentVerificationWaitingBanner,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.warningTextFor(
                                        Theme.of(context).brightness),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PaymentVerificationSummary(booking: b, trust: _trust),
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
                    Text(l10n.paymentVerificationScreenshotTitle, style: Theme.of(context) .textTheme .titleSmall ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (proofUrl.isNotEmpty)
                      ProofImageViewer(imageUrl: proofUrl)
                    else
                      Text(l10n.paymentVerificationNoScreenshot),
                    if (b.rejectionReason != null) ...[
                      const SizedBox(height: 14),
                      Text(l10n.paymentVerificationPreviouslyRejected(b.rejectionReason!), style: Theme.of(context) .textTheme .bodyMedium ?.copyWith(color: AppColors.warningTextFor(Theme.of(context).brightness))),
                    ],
                    TextField(
                      controller: _amountController, keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.bookingCheckAdvance, prefixText: 'Rs. '),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    PaymentVerificationActions(
                      processing: _processing,
                      confirmLabel: _processing
                          ? l10n.paymentVerificationConfirming
                          // Audit 2026-11-15 PW-11: route through
                          // amountRs (§4.5 money rule); the .arb
                          // value no longer embeds 'Rs.'.
                          : l10n.paymentVerificationConfirmButton(
                              l10n.amountRs(formatRs(_verifiedAmount))),
                      rejectLabel: l10n.paymentVerificationRejectButton,
                      onConfirm: _approve,
                      onReject: _reject,
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
