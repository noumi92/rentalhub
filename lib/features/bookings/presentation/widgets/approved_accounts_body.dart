import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/booking_entity.dart';
import 'payment_account_card.dart';
import 'shop_payment_account.dart';
import '../../../../core/utils/money_format.dart';
import '../../../owner/presentation/widgets/operations/booking_fare_breakdown.dart';

/// The approved-state body of [OwnerPaymentAccountsView]: the
/// "Reservation Request Approved!" banner, the shop's payment accounts,
/// and the Upload-proof CTA. Extracted so the view stays under the
/// 250-line cap. Only rendered once the booking is actually `approved`
/// — never "further along": a `paid` / `active` booking already had
/// its proof verified, and terminal / `disputed` bookings must never
/// see an Upload Proof CTA. The CTA itself is gated on
/// `status == 'approved'` below, so even a direct render of this body
/// with a past-payment booking shows the accounts without the prompt.
/// A booking with a PARTIAL advance (`advancePaid > 0` but
/// `< advanceRequired`) is still `approved`, so it still shows the
/// prompt — the advance is outstanding.
class ApprovedAccountsBody extends StatelessWidget {
  const ApprovedAccountsBody({
    super.key,
    required this.booking,
    required this.onProceedToUploadProof,
    this.firestore,
  });

  final BookingEntity booking;
  final VoidCallback? onProceedToUploadProof;

  /// Injectable Firestore for tests; production uses the default
  /// instance (see [ShopPaymentAccount.fetch]).
  final FirebaseFirestore? firestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Next-step batch (2026-11-21): the Upload Proof CTA renders
    // ONLY for `approved`. A partial advance keeps the booking
    // `approved`, so the prompt still shows until verification
    // flips it to `paid` — the gate is the status, not the amount.
    final showUploadCta = booking.status == 'approved';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            AppColors.accentSuccess.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.successTextFor(
                              Theme.of(context).brightness),
                          size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.paymentApprovedTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              // §10: the amount line is dark green text
                              // (successTextFor), not small orange —
                              // orange is kept only for the large CTA.
                              // C5: grouped via the String-typed {amount}
                              // placeholder (rulebook §4.5).
                              l10n.paymentTransferToLock(
                                  formatRs(booking.advanceRequired)),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.successTextFor(
                                          Theme.of(context).brightness)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // O18: the payment deadline is display-only — the
                // customer sees how long they have to pay; nothing
                // auto-cancels when it passes.
                if (booking.paymentDeadline != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.paymentPayByDeadline(
                              MaterialLocalizations.of(context)
                                  .formatTimeOfDay(TimeOfDay.fromDateTime(
                                      booking.paymentDeadline!)),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Audit §5 item 2 (O15): the fare breakdown — dates,
                // day count, daily rate × days, advance / remaining.
                BookingFareBreakdown(booking: booking),
                const SizedBox(height: 16),
                Text(
                  l10n.paymentAccountsDirect,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  // O18: an assigned account is the ONLY one the
                  // customer pays into; older bookings with no
                  // assignment still see every account.
                  booking.selectedPaymentAccount == null
                      ? l10n.paymentPayHint
                      : l10n.paymentAssignedAccountOnly,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                _buildDynamicAccountsList(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // The pinned Upload Proof CTA — `approved` only (see above).
        if (showUploadCta)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, -3))
              ],
            ),
            child: DebouncedButton(
              text: l10n.paymentUploadProof,
              icon: Icons.upload_file_rounded,
              onPressed: () async {
                onProceedToUploadProof?.call();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDynamicAccountsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<ShopPaymentAccount>>(
      future: ShopPaymentAccount.fetch(booking.shopId,
          firestore: firestore),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // E2: shared loading state (the FutureBuilder used to
          // render the empty state while still loading).
          return AppLoadingState(
            message: l10n.paymentLoading,
          );
        }
        final accounts = ShopPaymentAccount.visible(
          snapshot.data ?? const [],
          booking.selectedPaymentAccount,
        );
        if (accounts.isNotEmpty) {
          return Column(
            children: accounts.map((acc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PaymentAccountCard(
                  methodTitle: acc.methodTitle(l10n),
                  accountTitle: acc.title.isEmpty
                      ? l10n.paymentVerified
                      : acc.title,
                  accountNumber: acc.number,
                  iban: null,
                  brandColor: acc.isWallet
                      ? AppColors.successTextFor(
                          Theme.of(context).brightness)
                      : Theme.of(context).colorScheme.onSurface,
                  icon: acc.isWallet
                      ? Icons.account_balance_wallet_rounded
                      : Icons.account_balance_rounded,
                ),
              );
            }).toList(),
          );
        }
        // Phase B (D1): when the shop has not configured any payment
        // accounts, say so — never show another shop's accounts as
        // if they were this shop's.
        // E2: shared empty state.
        return AppEmptyState(
          title: l10n.paymentNoAccounts,
          message: l10n.paymentAddAccountsNote,
          icon: Icons.account_balance_rounded,
        );
      },
    );
  }
}
