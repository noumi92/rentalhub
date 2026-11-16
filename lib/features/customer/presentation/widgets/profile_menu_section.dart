import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'customer_support_badge.dart';
import 'profile_menu_card.dart';

/// The profile menu section (extracted from [CustomerProfileView] to
/// keep the view under the 250-line cap): documents, saved shops,
/// settings, and Support (moved off the tab bar into Profile; the
/// live unread badge moved with it).
///
/// Customer pass (2026-11-16): regrouped like the owner Settings
/// screen — MY ACCOUNT (documents, saved showrooms) and SUPPORT &
/// SETTINGS (settings, support) as two labelled group cards, every
/// row with a 36x36 pastel badge.
class ProfileMenuSection extends StatelessWidget {
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSupport;

  const ProfileMenuSection({
    super.key,
    this.onOpenDocuments,
    this.onOpenSavedShops,
    this.onOpenSettings,
    this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel(context, l10n.profileSectionAccount),
        ProfileMenuCard(items: [
          ProfileMenuItem(
            icon: Icons.badge_outlined,
            title: l10n.profileMyDocuments,
            subtitle: l10n.profileKycSubtitle,
            onTap: onOpenDocuments,
            badgeKind: MenuBadgeKind.navy,
          ),
          ProfileMenuItem(
            icon: Icons.favorite_border_rounded,
            title: l10n.profileSavedShops,
            subtitle: l10n.profileSavedShopsSubtitle,
            onTap: onOpenSavedShops,
            badgeKind: MenuBadgeKind.orange,
          ),
        ]),
        const SizedBox(height: 16),
        _groupLabel(context, l10n.profileSectionSupport),
        ProfileMenuCard(items: [
          ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: l10n.profileSettingsLanguage,
            subtitle: l10n.profileSettingsSubtitle,
            onTap: onOpenSettings,
            badgeKind: MenuBadgeKind.grey,
          ),
          ProfileMenuItem(
            icon: Icons.support_agent_rounded,
            leading: CustomerSupportBadge(
                icon: const Icon(Icons.support_agent_rounded)),
            title: l10n.navSupport,
            subtitle: l10n.supportTitle,
            onTap: onOpenSupport,
            badgeKind: MenuBadgeKind.green,
          ),
        ]),
      ],
    );
  }

  Widget _groupLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
