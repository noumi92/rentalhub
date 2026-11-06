import 'package:flutter/material.dart';

import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

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
      children: _actions(),
    );
  }

  List<Widget> _actions() {
    switch (booking.status) {
      case 'requested':
        return [
          if (onCancel != null)
            DebouncedButton(
              text: 'Cancel booking',
              icon: Icons.cancel_outlined,
              onPressed: () async => onCancel!.call(),
            ),
        ];
      case 'approved':
        return [
          if (onPayAdvance != null)
            DebouncedButton(
              text: 'Pay advance (Rs. ${booking.advanceRequired})',
              icon: Icons.payment_rounded,
              onPressed: () async => onPayAdvance!.call(),
            ),
          if (onCancel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel booking'),
            ),
          ],
        ];
      case 'paid':
      case 'active':
        return [
          if (onViewPass != null)
            DebouncedButton(
              text: 'View pickup pass',
              icon: Icons.qr_code_rounded,
              onPressed: () async => onViewPass!.call(),
            ),
        ];
      case 'completed':
        return [
          if (onRateTrip != null)
            DebouncedButton(
              text: 'Rate this trip',
              icon: Icons.star_rounded,
              onPressed: () async => onRateTrip!.call(),
            ),
          if (onFileDispute != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onFileDispute,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('File a dispute'),
            ),
          ],
        ];
      case 'rejected':
        return [
          if (onBrowseShops != null)
            DebouncedButton(
              text: 'Browse other shops',
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
              label: const Text('File a dispute'),
            ),
        ];
      default:
        return [];
    }
  }
}
