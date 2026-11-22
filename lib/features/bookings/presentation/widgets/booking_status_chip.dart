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
      case 'requested':
        return l10n.statusPendingReview;
      case 'approved':
        return l10n.statusApproved;
      case 'rejected':
        return l10n.statusRejected;
      case 'disputed':
        return l10n.statusDisputed;
      case 'payment_submitted':
        return l10n.statusProofSubmitted;
      case 'payment_rejected':
        return l10n.statusProofRejected;
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
  /// Showroom redesign Phase 0 (2026-11-16): these ARE the badge text
  /// colours — success `accentSuccessStrong` #047857 (4.99:1 on the
  /// #DCFCE7 badge), danger `errorText` #B91C1C (5.3:1 on the #FEE2E2
  /// badge). Never the raw accents #10B981 (2.31:1) / #EF4444 (3.08:1).
  static Color colorFor(String status, Brightness brightness) {
    switch (status) {
      case 'approved':
      case 'paid':
      case 'completed':
        return AppColors.successBadgeTextFor(brightness);
      case 'active':
        return brightness == Brightness.dark
            ? AppColors.primaryContainer
            : AppColors.primary;
      case 'rejected':
      case 'payment_rejected':
      case 'cancelled':
      case 'disputed':
        return AppColors.errorBadgeTextFor(brightness);
      default:
        return AppColors.warningTextFor(brightness);
    }
  }

  /// Badge background, brightness-aware (showroom redesign Phase 0):
  /// the guide tints — success #DCFCE7, error #FEE2E2, warning the
  /// warning container — light; the dark containers in dark mode.
  /// Replaces the old `color.withValues(alpha: 0.15)` tint.
  static Color backgroundFor(String status, Brightness brightness) {
    switch (status) {
      case 'approved':
      case 'paid':
      case 'completed':
        return AppColors.successBadgeFor(brightness);
      case 'active':
        return brightness == Brightness.dark
            ? AppColors.primary.withValues(alpha: 0.35)
            : AppColors.primaryContainer;
      case 'rejected':
      case 'payment_rejected':
      case 'cancelled':
      case 'disputed':
        return AppColors.errorBadgeFor(brightness);
      default:
        return AppColors.warningContainerFor(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = colorFor(status, brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundFor(status, brightness),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labelFor(AppLocalizations.of(context)!, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}
