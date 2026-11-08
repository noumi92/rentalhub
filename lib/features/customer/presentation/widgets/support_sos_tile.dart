import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Phase C (C3): the Emergency SOS entry tile on the Support tab.
/// Extracted from [CustomerSupportView] so the view stays under the
/// 250-line cap. The dashboard was the SOS screen's only entry point;
/// with the dashboard deleted, Support is its home — the FAQ already
/// tells users to use the SOS screen for emergencies.
class SupportSosTile extends StatelessWidget {
  final VoidCallback? onTap;

  const SupportSosTile({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.accentDanger.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.accentDanger.withValues(alpha: 0.3)),
      ),
      leading:
          const Icon(Icons.sos_rounded, color: AppColors.accentDanger),
      title: Text('Emergency SOS',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.accentDanger)),
      subtitle: Text(
          'Police 15 · Rescue 1122 — one-tap emergency help.',
          style: Theme.of(context).textTheme.labelSmall),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.accentDanger),
      onTap: onTap,
    );
  }
}
