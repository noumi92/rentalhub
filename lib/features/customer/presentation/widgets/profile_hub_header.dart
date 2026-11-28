import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'profile_header.dart';

/// Shared solid-navy header for the Customer Profile hub.
/// Integrates [ProfileHeader] and the optional [TabBar] into one
/// seamless top hero block, owns the status-bar inset once, and
/// shows a back button automatically when pushed (e.g. `/customer/kyc`).
class ProfileHubHeader extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final double? trustScore;
  final String kycStatus;
  final VoidCallback onEdit;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenReputation;
  final TabController? tabController;
  final List<Widget>? tabs;

  const ProfileHubHeader({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.trustScore,
    required this.kycStatus,
    required this.onEdit,
    this.onOpenDocuments,
    this.onOpenReputation,
    this.tabController,
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
    final barBg = Theme.of(context).appBarTheme.backgroundColor ??
        AppColors.primaryDark;
    final hasTabs = tabController != null && tabs != null && tabs!.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: barBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                canPop ? 4 : 16,
                topPadding + 14,
                16,
                hasTabs ? 8 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canPop)
                    IconButton(
                      tooltip: AppLocalizations.of(context)?.back ?? 'Back',
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  Expanded(
                    child: ProfileHeader(
                      name: name,
                      email: email,
                      phone: phone,
                      photoUrl: photoUrl,
                      trustScore: trustScore,
                      kycStatus: kycStatus,
                      onEdit: onEdit,
                      onOpenDocuments: onOpenDocuments,
                      onOpenReputation: onOpenReputation,
                    ),
                  ),
                ],
              ),
            ),
            if (hasTabs)
              TabBar(
                controller: tabController,
                tabs: tabs!,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.68),
                indicatorColor: AppColors.secondary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.white.withValues(alpha: 0.12),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
