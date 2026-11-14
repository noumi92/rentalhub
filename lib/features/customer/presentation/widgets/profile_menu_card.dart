import 'package:flutter/material.dart';

import '../../../../core/theme/card_decoration.dart';


/// H1: one row of the profile menu (Documents / Saved Showrooms /
/// Settings). Extracted from [CustomerProfileView] so the view stays
/// under the 250-line cap.
class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.leading,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Optional leading widget replacing the plain [Icon(icon)] — used
  /// by the Profile Support row to carry the live
  /// CustomerSupportBadge (unread replied-ticket count) that used to
  /// sit on the Support tab. No visual change to the card itself.
  final Widget? leading;
  final VoidCallback? onTap;
}

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({super.key, required this.items});

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    // Fill lives on the Material (surface) so the ListTiles paint
    // their ink splashes on it; the inner Container carries ONLY the
    // shadow — a coloured DecoratedBox between Material and ListTile
    // hides the ink and Flutter asserts on it (suite, 2026-11-10).
    // Same pattern as SettingsSectionCard.
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppCardDecoration.shadow(context),
        ),
        child: Column(
          children: items.map((item) {
            final isLast = items.indexOf(item) == items.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: item.leading ?? Icon(item.icon),
                  title: Text(item.title,
                      style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: Text(item.subtitle,
                      style: Theme.of(context).textTheme.labelSmall),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onTap: item.onTap,
                ),
                if (!isLast) const Divider(height: 1, indent: 56),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
