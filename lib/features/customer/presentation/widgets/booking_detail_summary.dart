import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Phase A (A1): the booking summary section of the customer booking
/// detail screen, extracted so the view stays under the 250-line cap.
class BookingDetailSummary extends StatelessWidget {
  const BookingDetailSummary({super.key, required this.booking});

  final BookingEntity booking;

  String _formatDateTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final amPm = d.hour < 12 ? 'AM' : 'PM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          _row('Vehicle', b.vehicleName ?? '—'),
          _row('Plate', b.vehiclePlate ?? '—'),
          _row('Package', b.packageType),
          _row('Drive mode', b.isWithDriver ? 'With driver' : 'Self drive'),
          _row('Trip', b.tripType == 'out_city' ? 'Out of city' : 'In city'),
          _row('Pickup', _formatDateTime(b.pickupTime)),
          _row('Return', _formatDateTime(b.returnTime)),
          const Divider(height: 18),
          _row('Total', 'Rs. ${b.totalAmount}', bold: true),
          _row('Advance required', 'Rs. ${b.advanceRequired}'),
          _row('Advance paid', 'Rs. ${b.advancePaid}'),
          _row('Remaining', 'Rs. ${b.remainingBalance}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The shop's rejection reason, shown on the detail screen when the
/// request was rejected — or when a payment proof was rejected (the
/// booking then sits back at 'approved' with the reason attached, and
/// the customer needs to know why before uploading again).
class BookingDetailRejectionCard extends StatelessWidget {
  const BookingDetailRejectionCard({
    super.key,
    required this.reason,
    this.prefix = 'The shop declined this request: ',
  });

  final String reason;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentDanger.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$prefix$reason',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }
}

/// A plain informational note (for example: proof submitted, waiting for
/// the shop to verify).
class BookingDetailInfoCard extends StatelessWidget {
  const BookingDetailInfoCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }
}
