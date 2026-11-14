import 'package:flutter/material.dart';

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
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

/// `'payment_submitted'` → `'Payment submitted'`; single words are
/// just capitalised. Never show a raw enum value to the admin.
String humanizeStatus(String status) {
  if (status.isEmpty) return status;
  final words = status.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
