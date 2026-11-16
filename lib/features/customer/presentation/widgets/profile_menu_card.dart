import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';

/// H1: one row of the profile menu (Documents / Saved Showrooms /
/// Settings). Extracted from [CustomerProfileView] so the view stays
/// under the 250-line cap.
///
/// Customer pass (2026-11-16): the rows follow the owner Settings
/// pattern — every leading icon sits in a 36x36 pastel circular
/// badge, the title is semibold, and the card is the canonical
/// showroom card (surface, 1px hairline, radius 16, elevation 1.5).
/// One badge colour per row, from the existing container tokens —
/// never a hardcoded hex. Dark legs come from the matching
/// `*For(brightness)` helpers / dark container tokens.
enum MenuBadgeKind { orange, green, red, amber, navy, grey }

class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.leading,
    this.onTap,
    this.badgeKind = MenuBadgeKind.navy,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Optional leading widget replacing the plain [Icon(icon)] — used
  /// by the Profile Support row to carry the live
  /// CustomerSupportBadge (unread replied-ticket count) that used to
  /// sit on the Support tab. It renders inside the pastel badge.
  final Widget? leading;
  final VoidCallback? onTap;
  final MenuBadgeKind badgeKind;
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: dark ? AppColors.borderDark : AppColors.borderSubtle,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppCardDecoration.shadow(context),
        ),
        child: Column(
          children: items.map((item) {
            final isLast = items.indexOf(item) == items.length - 1;
            final isRtl =
                Directionality.of(context) == TextDirection.rtl;
            return Column(
              children: [
                ListTile(
                  leading: _iconBadge(context, item),
                  title: Text(item.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.subtitle,
                      style: Theme.of(context).textTheme.labelSmall),
                  trailing: Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 20,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant),
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

  Widget _iconBadge(BuildContext context, ProfileMenuItem item) {
    final colors =
        _badgeColors(Theme.of(context).brightness, item.badgeKind);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bg),
      child: IconTheme(
        data: IconThemeData(size: 20, color: colors.fg),
        child: item.leading ?? Icon(item.icon),
      ),
    );
  }

  ({Color bg, Color fg}) _badgeColors(
      Brightness brightness, MenuBadgeKind kind) {
    return switch (kind) {
      MenuBadgeKind.orange => (
          bg: AppColors.orangeContainerFor(brightness),
          fg: AppColors.orangeOnContainerFor(brightness)
        ),
      MenuBadgeKind.green => (
          bg: AppColors.successContainerFor(brightness),
          fg: AppColors.successOnContainerFor(brightness)
        ),
      MenuBadgeKind.red => (
          bg: AppColors.errorContainerFor(brightness),
          fg: AppColors.errorOnContainerFor(brightness)
        ),
      MenuBadgeKind.amber => (
          bg: AppColors.warningContainerFor(brightness),
          fg: AppColors.warningOnContainerFor(brightness)
        ),
      MenuBadgeKind.navy => (
          bg: brightness == Brightness.dark
              ? AppColors.primaryContainerOnDark
              : AppColors.primaryContainer,
          fg: brightness == Brightness.dark
              ? AppColors.onSurfaceDark
              : AppColors.primary
        ),
      MenuBadgeKind.grey => (
          bg: brightness == Brightness.dark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceElevated,
          fg: brightness == Brightness.dark
              ? AppColors.onSurfaceVariantDark
              : AppColors.onSurfaceVariantLight
        ),
    };
  }
}
