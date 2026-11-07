import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// H1: one row of the profile menu (Documents / Saved Showrooms /
/// Settings). Extracted from [CustomerProfileView] so the view stays
/// under the 250-line cap.
class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({super.key, required this.items});

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: items.map((item) {
            final isLast = items.indexOf(item) == items.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: Icon(item.icon, color: AppColors.primary),
                  title: Text(item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  subtitle: Text(item.subtitle,
                      style: Theme.of(context).textTheme.labelSmall),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.textSecondary),
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
