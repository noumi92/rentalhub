import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

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
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              Text(
                email.isNotEmpty
                    ? email
                    : (phone.isNotEmpty ? phone : 'Not signed in'),
                style: const TextStyle(
                    color: AppColors.textLavender, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded,
              color: Colors.white, size: 20),
          tooltip: 'Edit profile',
          onPressed: onEdit,
        ),
      ],
    );
  }
}
