import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// C3: the booking status chip (label + colour) used on the request-sent
/// screen. It reads the booking's real status — requested shows
/// "Pending Review", approved "Approved", rejected "Rejected" — instead
/// of a hardcoded label.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final String status;

  static String labelFor(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'payment_submitted':
        return 'Proof submitted';
      case 'paid':
        return 'Paid';
      case 'active':
        return 'On trip';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending Review';
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case 'approved':
      case 'paid':
        return AppColors.accentSuccess;
      case 'rejected':
      case 'cancelled':
        return AppColors.accentDanger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labelFor(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
