import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// H1: the profile's sign-out tile. Extracted from [CustomerProfileView]
/// so the view stays under the 250-line cap.
class ProfileSignOutTile extends StatelessWidget {
  const ProfileSignOutTile({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        leading: Icon(Icons.logout_rounded,
            color: AppColors.dangerTextFor(Theme.of(context).brightness)),
        title: Text(l10n.profileSignOut,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.dangerTextFor(Theme.of(context).brightness))),
        onTap: onTap,
      ),
    );
  }
}
