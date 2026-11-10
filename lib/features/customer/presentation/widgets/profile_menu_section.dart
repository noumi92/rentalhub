import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'customer_support_badge.dart';
import 'profile_menu_card.dart';

/// The profile menu section (extracted from [CustomerProfileView] to
/// keep the view under the 250-line cap): documents, saved shops,
/// settings, and Support (moved off the tab bar into Profile; the
/// live unread badge moved with it).
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
    return ProfileMenuCard(items: [
      ProfileMenuItem(
        icon: Icons.badge_outlined,
        title: l10n.profileMyDocuments,
        subtitle: l10n.profileKycSubtitle,
        onTap: onOpenDocuments,
      ),
      ProfileMenuItem(
        icon: Icons.favorite_border_rounded,
        title: l10n.profileSavedShops,
        subtitle: l10n.profileSavedShopsSubtitle,
        onTap: onOpenSavedShops,
      ),
      ProfileMenuItem(
        icon: Icons.settings_outlined,
        title: l10n.profileSettingsLanguage,
        subtitle: l10n.profileSettingsSubtitle,
        onTap: onOpenSettings,
      ),
      ProfileMenuItem(
        icon: Icons.support_agent_rounded,
        leading: CustomerSupportBadge(
            icon: const Icon(Icons.support_agent_rounded)),
        title: l10n.navSupport,
        subtitle: l10n.supportTitle,
        onTap: onOpenSupport,
      ),
    ]);
  }
}
