import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'customer_support_badge.dart';
import 'profile_menu_card.dart';

/// Profile menu section on the Customer Profile tab:
/// MY ACCOUNT (saved showrooms) and SUPPORT & SETTINGS (settings,
/// support with live unread badge). Documents/KYC lives directly in
/// the top KYC tab and the header KYC chip rather than duplicated here.
class ProfileMenuSection extends StatelessWidget {
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSupport;

  const ProfileMenuSection({
    super.key,
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
