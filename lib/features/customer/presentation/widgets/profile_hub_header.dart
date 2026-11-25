import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'profile_header.dart';

// Profile hub (2026-11-25): the shared navy header — app bar with
// the edit action plus the profile header (avatar, name, trust and
// KYC chips). Extracted from CustomerProfileView so the view stays
// under the 250-line cap.
class ProfileHubHeader extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final double? trustScore;
  final String kycStatus;
  final VoidCallback onEdit;

  const ProfileHubHeader({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.trustScore,
    required this.kycStatus,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final barBg = Theme.of(context).appBarTheme.backgroundColor ??
        AppColors.primaryDark;
    return Container(
      color: barBg,
      child: Column(
        children: [
          MinimalAppBar(
            title: l10n.profileTitle,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 20),
                tooltip: l10n.profileEditProfile,
                onPressed: onEdit,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: ProfileHeader(
              name: name,
              email: email,
              phone: phone,
              photoUrl: photoUrl,
              trustScore: trustScore,
              kycStatus: kycStatus,
              onEdit: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}
