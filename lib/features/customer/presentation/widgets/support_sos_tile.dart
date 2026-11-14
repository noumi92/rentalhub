import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      tileColor: AppColors.accentDanger.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.accentDanger.withValues(alpha: 0.3)),
      ),
      leading:
          Icon(Icons.sos_rounded, color: AppColors.dangerTextFor(Theme.of(context).brightness)),
      title: Text(l10n.supportSosTitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.dangerTextFor(Theme.of(context).brightness))),
      subtitle: Text(
          l10n.supportSosSubtitle,
          style: Theme.of(context).textTheme.labelSmall),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.dangerTextFor(Theme.of(context).brightness)),
      onTap: onTap,
    );
  }
}
