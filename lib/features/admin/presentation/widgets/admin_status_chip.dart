import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// Contrast-safe status tones for the admin lists.
///
/// The canonical `*TextFor` helpers are too light for small text on a
/// light surface (accentSuccess #10B981 is 2.54:1, accentDanger #EF4444
/// is 3.9:1), so chips use the darker light-mode tokens the 2026-11-13
/// audit's contrast cluster prescribes — accentSuccessStrong 5.48:1,
/// errorDark #DC2626 4.83:1, warningOnContainer #92400E 6.84:1 — and
/// the lighter dark-mode variants on dark surfaces.
enum AdminStatusTone { success, danger, warning, info, neutral }

Color adminStatusColor(BuildContext context, AdminStatusTone tone) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (tone) {
    AdminStatusTone.success =>
      dark ? AppColors.accentSuccessDark : AppColors.accentSuccessStrong,
    AdminStatusTone.danger =>
      dark ? AppColors.accentDangerDark : AppColors.errorDark,
    AdminStatusTone.warning =>
      dark ? AppColors.warningOnContainerDark : AppColors.warningOnContainer,
    AdminStatusTone.info => Theme.of(context).colorScheme.primary,
    AdminStatusTone.neutral =>
      Theme.of(context).colorScheme.onSurfaceVariant,
  };
}

/// A small pill for a list status, with a human label (never a raw
/// `snake_case` enum value). Display-only: it is not tappable.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = adminStatusColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

/// `'payment_submitted'` → `'Payment submitted'`; single words are
/// just capitalised. Never show a raw enum value to the admin.
/// With `l10n` the known status codes render localised; unknown codes
/// and a null `l10n` fall back to the capitalised English form.
String humanizeStatus(String status, [AppLocalizations? l10n]) {
  if (status.isEmpty) return status;
  if (l10n != null) {
    final localized = switch (status) {
      'all' => l10n.filterAll,
      'approved' => l10n.statusApproved,
      'pending' => l10n.pending,
      'rejected' => l10n.statusRejected,
      'active' => l10n.active,
      'suspended' => l10n.admin2_suspended,
      'hidden' => l10n.admin2_hidden,
      'open' => l10n.admin2_open,
      'closed' => l10n.admin2_closed,
      'resolved' => l10n.admin2_resolved,
      'in_review' => l10n.inReview,
      'in_progress' => l10n.admin2_inProgress,
      'escalated' => l10n.admin2_escalated,
      'requested' => l10n.admin2_requested,
      'disputed' => l10n.admin2_disputed,
      'in_city' => l10n.admin2_inCity,
      'out_city' => l10n.admin2_outCity,
      'payment_submitted' => l10n.admin2_paymentSubmitted,
      'paid' => l10n.admin2_paid,
      'completed' => l10n.admin2_completed,
      'cancelled' => l10n.admin2_cancelled,
      _ => null,
    };
    if (localized != null) return localized;
  }
  final words = status.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
