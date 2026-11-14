import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/success_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Audit item 17 (O21): Rental Started — the owner screen after
/// handover. Green "Rental Started" banner, booking #, "Return due
/// …", buttons View Agreement and Message Customer (a wa.me deep
/// link with a prefilled message, the same manual-WhatsApp pattern
/// as the dues reminder — no automated send, D2-gated).
class OwnerRentalStartedView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerRentalStartedView({
    super.key,
    required this.booking,
    this.onBack,
  });

  String _waNumber(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits;
    if (digits.startsWith('0')) return '92${digits.substring(1)}';
    return digits;
  }

  Future<void> _messageCustomer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final number = _waNumber(booking.customerPhone);
    if (number.isEmpty) {
      AppFeedback.showError(context, l10n.rentalStartedNoPhone);
      return;
    }
    final message = l10n.rentalStartedMessage(
      booking.customerName ?? l10n.requestsCustomerFallback,
      booking.vehicleName ?? l10n.summaryVehicle,
    );
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppFeedback.showError(context, l10n.rentalStartedWhatsappFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.rentalStartedTitle,
              subtitle: '#${booking.bookingId}',
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // OW-M6: the shared brightness-aware banner (was a
                    // fixed-light green slab with theme subtitles,
                    // invisible in dark mode).
                    SuccessBanner(
                      title: l10n.rentalStartedBanner,
                      lines: [
                        l10n.rentalStartedBooking(booking.bookingId),
                        l10n.rentalStartedReturnDue(
                          MaterialLocalizations.of(context)
                              .formatShortDate(booking.returnTime),
                          MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(booking.returnTime)),
                        ),
                      ],
                      lastLineMedium: true,
                    ),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: l10n.rentalStartedViewAgreement,
                      icon: Icons.description_rounded,
                      onPressed: () => context.push(
                        RouteNames.ownerContract
                            .replaceFirst(':id', booking.bookingId),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DebouncedButton(
                      text: l10n.rentalStartedMessageCustomer,
                      icon: Icons.message_rounded,
                      onPressed: () => _messageCustomer(context),
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
