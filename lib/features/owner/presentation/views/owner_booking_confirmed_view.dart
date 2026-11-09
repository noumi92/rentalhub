import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Audit §5 item 3 (O18 p.6+p.7): the owner-side "Booking Confirmed"
/// screen. Reached after a payment-proof approval and after a manual
/// booking is created — instead of jumping straight to handover.
/// "Message Customer" opens the owner's own WhatsApp with the
/// confirmation already written (the dues-reminder `wa.me` precedent);
/// nothing is sent automatically — WhatsApp sending stays gated on D2.
class OwnerBookingConfirmedView extends StatefulWidget {
  const OwnerBookingConfirmedView({
    super.key,
    required this.booking,
    this.onBack,
  });

  final BookingEntity booking;
  final VoidCallback? onBack;

  @override
  State<OwnerBookingConfirmedView> createState() =>
      _OwnerBookingConfirmedViewState();
}

class _OwnerBookingConfirmedViewState
    extends State<OwnerBookingConfirmedView> {
  String _waNumber(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits;
    if (digits.startsWith('0')) return '92${digits.substring(1)}';
    return digits;
  }

  Future<void> _messageCustomer() async {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    final number = _waNumber(booking.customerPhone);
    if (number.isEmpty) {
      AppFeedback.showError(context, l10n.financeDuesNoPhoneError);
      return;
    }
    final when =
        DateFormat('d MMM yyyy, h:mm a').format(booking.pickupTime);
    final message = l10n.bookingConfirmedWhatsappMessage(
      booking.customerName ?? l10n.requestsCustomerFallback,
      booking.vehicleName ?? booking.vehicleId,
      when,
      formatRs(booking.totalAmount),
    );
    final uri =
        Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppFeedback.showError(context, l10n.bookingConfirmedWhatsappFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    final when =
        DateFormat('d MMM yyyy, h:mm a').format(booking.pickupTime);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.bookingConfirmedTitle,
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accentSuccess
                                .withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 48,
                              color: AppColors.successTextFor(
                                  Theme.of(context).brightness)),
                          const SizedBox(height: 8),
                          Text(
                            l10n.bookingConfirmedTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.paymentVerificationBooking(
                                booking.bookingId),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.bookingConfirmedHandoverScheduled(when),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row(context, l10n.requestsCustomerFallback,
                                booking.customerName ?? '—'),
                            _row(context, l10n.summaryVehicle,
                                booking.vehicleName ?? booking.vehicleId),
                            _row(
                                context,
                                l10n.bookingFareTotal,
                                l10n.amountRs(
                                    formatRs(booking.totalAmount))),
                            _row(
                                context,
                                l10n.bookingFareAdvancePaid,
                                l10n.amountRs(
                                    formatRs(booking.advancePaid))),
                            _row(
                                context,
                                l10n.bookingFareRemaining,
                                l10n.amountRs(
                                    formatRs(booking.remainingBalance))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: l10n.bookingConfirmedStartHandover,
                      icon: Icons.key_rounded,
                      onPressed: () => context.push(
                        RouteNames.ownerHandover
                            .replaceFirst(':id', booking.bookingId),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          RouteNames.ownerRequestsDetail
                              .replaceFirst(':id', booking.bookingId),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: Text(l10n.bookingConfirmedViewBooking),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _messageCustomer,
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(l10n.bookingConfirmedMessageCustomer),
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

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
}
