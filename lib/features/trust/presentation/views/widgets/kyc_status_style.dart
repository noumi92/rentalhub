import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// The single mapping from a KYC status string to its label, colour
/// and icon — shared by [KycStatusBanner], [HomeKycCard] and the
/// profile hub header, so the three places can never drift apart
/// again.
///
/// Statuses: 'verified' | 'rejected' | 'submitted' | 'resubmitted' |
/// 'pending' (anything else reads as submitted/pending, as before).
/// 'resubmitted' is a verified customer's updated submission waiting
/// for re-review: it is pending, not verified, and it is visible in
/// the admin review queue alongside 'submitted'.
abstract final class KycStatusStyle {
  static String label(AppLocalizations l10n, String status) {
    switch (status) {
      case 'verified':
        return l10n.verified;
      case 'rejected':
        return l10n.kycStatusRejected;
      default:
        return l10n.kycStatusSubmitted;
    }
  }

  static Color color(Brightness brightness, String status) {
    switch (status) {
      case 'verified':
        return AppColors.successOnContainerFor(brightness);
      case 'rejected':
        return AppColors.dangerTextFor(brightness);
      default:
        return AppColors.warningOnContainerFor(brightness);
    }
  }

  /// The plain text colour variant used for pill text on Home.
  static Color textColor(Brightness brightness, String status) {
    switch (status) {
      case 'verified':
        return AppColors.successTextFor(brightness);
      case 'rejected':
        return AppColors.dangerTextFor(brightness);
      default:
        return AppColors.warningTextFor(brightness);
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.error_outline_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }
}
