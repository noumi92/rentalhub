import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_views.dart';
import 'profile_cnic_row.dart';
import 'profile_menu_section.dart';
import 'profile_sign_out_tile.dart';
import 'profile_trust_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Customer pass (2026-11-16): the profile body — trust card, CNIC
/// row, grouped menu and sign-out. Extracted from
/// [CustomerProfileView] so the view stays under the 250-line cap.
/// All data and callbacks come from the view; nothing is loaded here.
class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.loading,
    required this.loadFailed,
    required this.trustScore,
    required this.kycVerified,
    required this.isBlacklisted,
    required this.onOpenReputation,
    required this.onAppeal,
    required this.cnic,
    required this.onOpenDocuments,
    required this.onOpenSavedShops,
    required this.onOpenSettings,
    required this.onOpenSupport,
    required this.onSignOut,
    required this.onRetry,
  });

  final bool loading;
  final bool loadFailed;
  final double? trustScore;
  final bool kycVerified;
  final bool isBlacklisted;
  final VoidCallback? onOpenReputation;
  final VoidCallback? onAppeal;
  final String cnic;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenSavedShops;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSupport;
  final VoidCallback? onSignOut;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (loading)
          // E2: shared loading state.
          AppLoadingState(message: l10n.profileLoading)
        else if (loadFailed)
          // AC-18: signed-in + load failed — an error with retry, never a silent "Guest".
          AppErrorState(message: l10n.profileLoadFailed, onRetry: onRetry)
        else ...[
          ProfileTrustCard(
              trustScore: trustScore,
              kycVerified: kycVerified,
              isBlacklisted: isBlacklisted,
              onTap: onOpenReputation,
              onAppeal: onAppeal),
          const SizedBox(height: 16),
          // E1: the customer's own CNIC, masked by default.
          if (cnic.isNotEmpty) ...[
            ProfileCnicRow(cnic: cnic),
            const SizedBox(height: 16),
          ],
          ProfileMenuSection(
              onOpenDocuments: onOpenDocuments,
              onOpenSavedShops: onOpenSavedShops,
              onOpenSettings: onOpenSettings,
              onOpenSupport: onOpenSupport),
          const SizedBox(height: 16),
          ProfileSignOutTile(onTap: onSignOut),
        ],
      ],
    );
  }
}
