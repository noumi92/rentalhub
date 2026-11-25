import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_views.dart';
import 'profile_cnic_row.dart';
import 'profile_identity_card.dart';
import 'profile_menu_section.dart';
import 'profile_trust_section.dart';
import '../../../../l10n/app_localizations.dart';

/// Profile hub (2026-11-25): the Profile tab body — identity card,
/// trust section (the Reputation view folded in: trust card +
/// showroom ratings), CNIC row and the menu. Extracted from
/// [CustomerProfileView] so the view stays under the 250-line cap.
/// All data and callbacks come from the view; nothing is loaded here.
///
/// Sign-out moved out: it lives on the Settings screen only now, so
/// the profile no longer renders it twice.
class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.loading,
    required this.loadFailed,
    required this.name,
    required this.email,
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
    required this.onOpenDocuments,
    required this.onOpenSavedShops,
    required this.onOpenSettings,
    required this.onOpenSupport,
    required this.onRetry,
  });

  final bool loading;
  final bool loadFailed;
  final String name;
  final String email;
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
  final VoidCallback? onOpenDocuments;
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
          // E2: shared loading state.
          AppLoadingState(message: l10n.profileLoading)
        else if (loadFailed)
          // AC-18: signed-in + load failed — an error with retry, never a silent "Guest".
          AppErrorState(message: l10n.profileLoadFailed, onRetry: onRetry)
        else ...[
          ProfileIdentityCard(
            name: name,
            phone: phone,
            email: email,
            dateOfBirth: dateOfBirth,
            fatherName: fatherName,
            address: address,
          ),
          const SizedBox(height: 16),
          // E1: the customer's own CNIC, masked by default.
          if (cnic.isNotEmpty) ...[
            ProfileCnicRow(cnic: cnic),
            const SizedBox(height: 16),
          ],
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
              onOpenDocuments: onOpenDocuments,
              onOpenSavedShops: onOpenSavedShops,
              onOpenSettings: onOpenSettings,
              onOpenSupport: onOpenSupport),
        ],
      ],
    );
  }
}
