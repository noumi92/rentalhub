import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Item 9 (O27): the in-app handover receipt — receipt id, the
/// money rows and which of them were actually received. Sharing is
/// the existing manual `wa.me` pattern (prefilled message, nothing
/// sent automatically); there is no print / PDF receipt in this
/// build.
class HandoverReceiptSheet extends StatelessWidget {
  final BookingEntity booking;
  final String receiptId;
  final int securityDeposit;
  final int balanceDue;
  final String? balanceMethod;
  final String? depositMethod;
  final bool balanceReceived;
  final bool depositReceived;

  const HandoverReceiptSheet({
    super.key,
    required this.booking,
    required this.receiptId,
    required this.securityDeposit,
    required this.balanceDue,
    this.balanceMethod,
    this.depositMethod,
    this.balanceReceived = false,
    this.depositReceived = false,
  });

  String _waNumber(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits;
    if (digits.startsWith('0')) return '92${digits.substring(1)}';
    return digits;
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final number = _waNumber(booking.customerPhone);
    if (number.isEmpty) {
      AppFeedback.showError(context, l10n.rentalStartedNoPhone);
      return;
    }
    final message = l10n.handoverWizardReceiptMessage(
      receiptId,
      booking.vehicleName ?? l10n.summaryVehicle,
      formatRs(booking.totalAmount),
      formatRs(booking.advancePaid),
      formatRs(balanceDue),
      formatRs(securityDeposit),
    );
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppFeedback.showError(
          context, l10n.handoverWizardReceiptWhatsappFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.handoverWizardReceiptTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.handoverWizardReceiptId(receiptId),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('#${booking.bookingId}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                      booking.customerName ?? l10n.requestsCustomerFallback,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(booking.vehicleName ?? l10n.summaryVehicle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _row(context, l10n.handoverWizardAdvancePaid,
                l10n.amountRs(formatRs(booking.advancePaid)), true),
            _row(context, l10n.handoverBalanceDue,
                l10n.amountRs(formatRs(balanceDue)), balanceReceived),
            _row(context, l10n.returnReceiptDepositHeld,
                l10n.amountRs(formatRs(securityDeposit)), depositReceived),
            const SizedBox(height: 8),
            Text(
              l10n.amountRs(formatRs(booking.totalAmount)),
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonGoBack),
        ),
        FilledButton.icon(
          onPressed: () => _shareOnWhatsApp(context),
          icon: const Icon(Icons.share_rounded),
          label: Text(l10n.handoverWizardReceiptShare),
        ),
      ],
    );
  }

  Widget _row(
      BuildContext context, String label, String value, bool received) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (received)
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
