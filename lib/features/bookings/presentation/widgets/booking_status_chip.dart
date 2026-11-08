import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// C3: the booking status chip (label + colour) used on the request-sent
/// screen. It reads the booking's real status — requested shows
/// "Pending Review", approved "Approved", rejected "Rejected" — instead
/// of a hardcoded label.
class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final String status;

  static String labelFor(AppLocalizations l10n, String status) {
    switch (status) {
      case 'approved':
        return l10n.statusApproved;
      case 'rejected':
        return l10n.statusRejected;
      case 'payment_submitted':
        return l10n.statusProofSubmitted;
      case 'paid':
        return l10n.statusPaid;
      case 'active':
        return l10n.statusOnTrip;
      case 'completed':
        return l10n.statusCompleted;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return l10n.statusPendingReview;
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
        labelFor(AppLocalizations.of(context)!, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
