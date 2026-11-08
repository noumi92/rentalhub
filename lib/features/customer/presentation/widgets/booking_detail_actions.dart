import 'package:flutter/material.dart';

import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../l10n/app_localizations.dart';

/// The status-driven actions for one booking. Extracted from
/// [CustomerBookingDetailView] so the view stays under the
/// 250-line cap (rulebook §2.2).
class BookingDetailActions extends StatelessWidget {
  const BookingDetailActions({
    super.key,
    required this.booking,
    this.onPayAdvance,
    this.onViewPass,
    this.onCancel,
    this.onRateTrip,
    this.onFileDispute,
    this.onBrowseShops,
  });

  final BookingEntity booking;
  final VoidCallback? onPayAdvance;
  final VoidCallback? onViewPass;
  final VoidCallback? onCancel;
  final VoidCallback? onRateTrip;
  final VoidCallback? onFileDispute;
  final VoidCallback? onBrowseShops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _actions(AppLocalizations.of(context)!),
    );
  }

  List<Widget> _actions(AppLocalizations l10n) {
    switch (booking.status) {
      case 'requested':
        return [
          if (onCancel != null)
            DebouncedButton(
              text: l10n.cancelBooking,
              icon: Icons.cancel_outlined,
              onPressed: () async => onCancel!.call(),
            ),
        ];
      case 'approved':
        return [
          if (onPayAdvance != null)
            DebouncedButton(
              text: l10n.payAdvanceAmount(booking.advanceRequired),
              icon: Icons.payment_rounded,
              onPressed: () async => onPayAdvance!.call(),
            ),
          if (onCancel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label:  Text(l10n.cancelBooking),
            ),
          ],
        ];
      case 'paid':
      case 'active':
        return [
          if (onViewPass != null)
            DebouncedButton(
              text: l10n.viewPickupPass,
              icon: Icons.qr_code_rounded,
              onPressed: () async => onViewPass!.call(),
            ),
        ];
      case 'completed':
        return [
          if (onRateTrip != null)
            DebouncedButton(
              text: l10n.rateThisTrip,
              icon: Icons.star_rounded,
              onPressed: () async => onRateTrip!.call(),
            ),
          if (onFileDispute != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onFileDispute,
              icon: const Icon(Icons.report_problem_outlined),
              label:  Text(l10n.fileDispute),
            ),
          ],
        ];
      case 'rejected':
        return [
          if (onBrowseShops != null)
            DebouncedButton(
              text: l10n.browseOtherShops,
              icon: Icons.search_rounded,
              onPressed: () async => onBrowseShops!.call(),
            ),
        ];
      case 'cancelled':
        return [
          if (onFileDispute != null)
            OutlinedButton.icon(
              onPressed: onFileDispute,
              icon: const Icon(Icons.report_problem_outlined),
              label:  Text(l10n.fileDispute),
            ),
        ];
      default:
        return [];
    }
  }
}
