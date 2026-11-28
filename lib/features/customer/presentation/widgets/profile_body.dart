import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_views.dart';
import '../../../auth/presentation/utils/sign_out_confirm_dialog.dart';
import '../../../auth/presentation/utils/sign_out_helper.dart';
import 'profile_identity_card.dart';
import 'profile_menu_section.dart';
import 'profile_sign_out_tile.dart';
import 'profile_trust_section.dart';
import '../../../../l10n/app_localizations.dart';

/// Profile tab body — unified Personal Details card (including masked
/// CNIC and completion prompt), unified Trust & Reputation card, and
/// account/support menu. Extracted from [CustomerProfileView] so the
/// view stays under the 250-line cap.
class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.loading,
    required this.loadFailed,
    required this.phone,
    required this.dateOfBirth,
    required this.fatherName,
    required this.address,
    required this.trustScore,
    required this.kycVerified,
    required this.isBlacklisted,
    required this.onOpenReputation,
    required this.onAppeal,
    required this.ownerReviews,
    required this.cnic,
    required this.onEdit,
    required this.onOpenSavedShops,
    required this.onOpenSettings,
    required this.onOpenSupport,
    required this.onRetry,
  });

  final bool loading;
  final bool loadFailed;
  final String phone;
  final String? dateOfBirth;
  final String? fatherName;
  final String? address;
  final double? trustScore;
  final bool kycVerified;
  final bool isBlacklisted;
  final VoidCallback? onOpenReputation;
  final VoidCallback? onAppeal;
  final List<Map<String, dynamic>> ownerReviews;
  final String cnic;
  final VoidCallback onEdit;
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSupport;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (loading)
          AppLoadingState(message: l10n.profileLoading)
        else if (loadFailed)
          AppErrorState(message: l10n.profileLoadFailed, onRetry: onRetry)
        else ...[
          ProfileIdentityCard(
            phone: phone,
            cnic: cnic,
            dateOfBirth: dateOfBirth,
            fatherName: fatherName,
            address: address,
            onEdit: onEdit,
          ),
          const SizedBox(height: 16),
          ProfileTrustSection(
            trustScore: trustScore,
            kycVerified: kycVerified,
            isBlacklisted: isBlacklisted,
            onOpenReputation: onOpenReputation,
            onAppeal: onAppeal,
            ownerReviews: ownerReviews,
          ),
          const SizedBox(height: 16),
          ProfileMenuSection(
            onOpenSavedShops: onOpenSavedShops,
            onOpenSettings: onOpenSettings,
            onOpenSupport: onOpenSupport,
          ),
          const SizedBox(height: 16),
          ProfileSignOutTile(
            onTap: () async {
              final confirmed = await showSignOutConfirmDialog(context);
              if (!confirmed || !context.mounted) return;
              await signOutToAuth(context);
            },
          ),
        ],
      ],
    );
  }
}
