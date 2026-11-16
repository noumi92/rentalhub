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

/// Badge background for [AdminStatusChip] (showroom redesign Phase 0,
/// 2026-11-16): the guide tints — success #DCFCE7, error #FEE2E2,
/// warning the warning container — light; the dark containers in dark
/// mode. Info/neutral keep the old 12% tint of the tone colour.
/// [adminStatusColor] itself is unchanged: other callers (dashboard
/// accents, tribunal, ticket tiles) use it for text/icon colour.
Color adminStatusBadgeBackground(BuildContext context, AdminStatusTone tone) {
  final brightness = Theme.of(context).brightness;
  return switch (tone) {
    AdminStatusTone.success => AppColors.successBadgeFor(brightness),
    AdminStatusTone.danger => AppColors.errorBadgeFor(brightness),
    AdminStatusTone.warning => AppColors.warningContainerFor(brightness),
    _ => adminStatusColor(context, tone).withValues(alpha: 0.12),
  };
}

/// Badge text for [AdminStatusChip]: the badge text tokens — success
/// `accentSuccessStrong` #047857 (4.99:1 on #DCFCE7), danger
/// `errorText` #B91C1C (5.3:1 on #FEE2E2) — light; the light
/// on-container colours in dark mode. Info/neutral keep
/// [adminStatusColor].
Color adminStatusBadgeText(BuildContext context, AdminStatusTone tone) {
  final brightness = Theme.of(context).brightness;
  return switch (tone) {
    AdminStatusTone.success => AppColors.successBadgeTextFor(brightness),
    AdminStatusTone.danger => AppColors.errorBadgeTextFor(brightness),
    AdminStatusTone.warning => AppColors.warningTextFor(brightness),
    _ => adminStatusColor(context, tone),
  };
}
/// A small pill for a list status, with a human label (never a raw
/// `snake_case` enum value). Display-only: it is not tappable.
/// Badge labels are weight 500, never bold (rulebook §4.5: Bold only
/// at displayLarge 28).
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AdminStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = adminStatusBadgeText(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: adminStatusBadgeBackground(context, tone),
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
