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

  /// Status text colour, brightness-aware: the light tokens are too dark
  /// to read on dark surfaces, so dark mode uses the lighter variants.
  static Color colorFor(String status, Brightness brightness) {
    switch (status) {
      case 'approved':
      case 'paid':
        return AppColors.successTextFor(brightness);
      case 'rejected':
      case 'cancelled':
        return AppColors.dangerTextFor(brightness);
      default:
        return AppColors.warningTextFor(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status, Theme.of(context).brightness);
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
