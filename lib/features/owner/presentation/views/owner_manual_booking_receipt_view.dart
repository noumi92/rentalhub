import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../services/manual_booking_whatsapp.dart';

/// O24: the receipt after a walk-in booking is confirmed — the
/// REAL booking number (RH-…), a Walk-in badge, the full money
/// lines, the agreement note, and Share Receipt via WhatsApp
/// (wa.me, nothing sent automatically). No print/PDF receipt.
/// Reached by pushReplacement from step 4, so Back does not
/// re-create the booking.
class OwnerManualBookingReceiptView extends StatelessWidget {
  const OwnerManualBookingReceiptView({
    super.key,
    required this.booking,
    required this.paymentMethod,
    required this.rentAmount,
    required this.driverAmount,
    required this.depositMethod,
    this.onBack,
  });

  final BookingEntity booking;
  final String paymentMethod;
  final int rentAmount;
  final int driverAmount;
  final String depositMethod;
  final VoidCallback? onBack;

  /// Opens the receipt for a just-created booking, replacing step 4.
  static void open(
    BuildContext context, {
    required BookingEntity booking,
    required String paymentMethod,
    required int rentAmount,
    required int driverAmount,
    required String depositMethod,
  }) {
    context.pushReplacement(RouteNames.ownerManualBookingReceipt,
        extra: <String, dynamic>{
          'booking': booking,
          'paymentMethod': paymentMethod,
          'rentAmount': rentAmount,
          'driverAmount': driverAmount,
          'depositMethod': depositMethod,
        });
  }

  String _methodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'jazzcash':
        return l10n.returnPaymentJazzCash;
      case 'easypaisa':
        return l10n.returnPaymentEasyPaisa;
      case 'bank_transfer':
        return l10n.returnPaymentBankTransfer;
      default:
        return l10n.returnPaymentCash;
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    await sendManualBookingReceipt(
      context,
      bookingId: booking.bookingId,
      customerName: booking.customerName ?? '',
      customerPhone: booking.customerPhone ?? '',
      vehicleName: booking.vehicleName ?? booking.vehicleId,
      pickupTime: booking.pickupTime,
      total: booking.totalAmount,
      remainingDues: booking.remainingBalance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final discount = (booking.discountAmountPkr ?? 0).round();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.manualBookingSummaryTitle, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(l10n.manualBookingRegistered(booking.bookingId),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.warningContainerFor(brightness), borderRadius: BorderRadius.circular(6)),
                          child: Text(l10n.manualBookingWalkInBadge,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600, color: AppColors.warningTextFor(brightness))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row(context, l10n.requestsCustomerFallback, booking.customerName ?? ''),
                            _row(context, l10n.summaryVehicle, booking.vehicleName ?? booking.vehicleId),
                            _row(context, l10n.packageLabel, '${booking.packageType} • ${booking.isWithDriver ? l10n.withDriver : l10n.selfDrive}'),
                            _row(context, l10n.bookingFarePickup, dateFormat.format(booking.pickupTime)),
                            _row(context, l10n.bookingFareReturn, dateFormat.format(booking.returnTime)),
                            const Divider(height: 20),
                            _moneyRow(context, l10n, l10n.manualBookingRentLine, rentAmount),
                            _moneyRow(context, l10n, l10n.manualBookingDriverLine, driverAmount),
                            if (discount > 0) _moneyRow(context, l10n, l10n.manualBookingDiscountLine, -discount),
                            _moneyRow(context, l10n, l10n.bookingFareTotal, booking.totalAmount, bold: true),
                            _row(context, l10n.manualBookingRentPaid, '${l10n.amountRs(formatRs(booking.advancePaid))} (${_methodLabel(l10n, paymentMethod)})'),
                            _row(context, l10n.manualBookingDepositReceived, booking.depositAmountPkr == null ? l10n.handoverBalanceNotYet : '${l10n.amountRs(formatRs(booking.depositAmountPkr!))} (${_methodLabel(l10n, depositMethod)})'),
                            _row(context, l10n.manualBookingRemainingDues, l10n.amountRs(formatRs(booking.remainingBalance)), bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.manualBookingAgreementNote, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      key: const Key('manual-booking-share-receipt'),
                      text: l10n.manualBookingShareReceipt,
                      icon: Icons.share_rounded,
                      onPressed: () => _shareReceipt(context),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(RouteNames.ownerRequests),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        child: Text(l10n.manualBookingReceiptDone),
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

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w500 : FontWeight.w400))),
        ],
      ),
    );
  }

  Widget _moneyRow(BuildContext context, AppLocalizations l10n, String label, int amount, {bool bold = false}) {
    final sign = amount < 0 ? '− ' : '';
    return _row(context, label, '$sign${l10n.amountRs(formatRs(amount.abs()))}', bold: bold);
  }
}
