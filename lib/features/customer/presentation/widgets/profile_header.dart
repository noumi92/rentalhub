import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// H1: the profile header — avatar initial, name, email/phone and the
/// edit button. Extracted from [CustomerProfileView] so the view stays
/// under the 250-line cap.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
              Text(
                email.isNotEmpty
                    ? email
                    : (phone.isNotEmpty ? phone : l10n.profileNotSignedInShort),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded,
              color: Colors.white, size: 20),
          tooltip: l10n.profileEditProfile,
          onPressed: onEdit,
        ),
      ],
    );
  }
}
