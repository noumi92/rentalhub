import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// H1: the profile's sign-out tile. Extracted from [CustomerProfileView]
/// so the view stays under the 250-line cap.
class ProfileSignOutTile extends StatelessWidget {
  const ProfileSignOutTile({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: const Icon(Icons.logout_rounded,
            color: AppColors.crimsonRed),
        title: const Text('Sign Out',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.crimsonRed)),
        onTap: onTap,
      ),
    );
  }
}
