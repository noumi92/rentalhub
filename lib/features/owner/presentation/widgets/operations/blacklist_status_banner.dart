import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../blacklist/domain/entities/blacklist_entity.dart';
import '../../../../../core/theme/card_decoration.dart';

class BlacklistStatusBanner extends StatelessWidget {
  final bool isChecked;
  final BlacklistEntity? blacklistedRecord;

  /// Audit §19: the CNIC is confirmed blacklisted but no record came
  /// back — the banner must say details are unavailable and refer to
  /// the tribunal, NEVER invent a phone number, reporter or reference
  /// (the old code fabricated a BLK-AUTO record).
  final bool detailsUnavailable;
  final VoidCallback? onProceed;
  final VoidCallback? onDecline;

  const BlacklistStatusBanner({
    super.key,
    required this.isChecked,
    this.blacklistedRecord,
    this.detailsUnavailable = false,
    this.onProceed,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    // Phase F: the banner copy is localized (English fallback for
    // delegate-less pumps). The record's own description, reason
    // category and reporter id stay stored data.
    final l10n = AppLocalizations.of(context);
    if (!isChecked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppCardDecoration.shadow(context)
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.blacklistScanPrompt ??
                    'Enter CNIC above to run an instant real-time scan against the RentalHub shared blacklist.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final isBlacklisted = blacklistedRecord != null || detailsUnavailable;

    if (isBlacklisted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorContainerFor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.accentDangerDark : AppColors.accentDanger, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dangerous_rounded, color: AppColors.errorOnContainerFor(Theme.of(context).brightness), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.blacklistCriticalAlert ??
                            'CRITICAL ALERT: BLACKLISTED CITIZEN',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.errorOnContainerFor(Theme.of(context).brightness)),
                      ),
                      if (blacklistedRecord != null)
                        Text(
                          l10n?.blacklistIncidentRef(blacklistedRecord!.blacklistId) ??
                              'Incident Ref: ${blacklistedRecord!.blacklistId}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppColors.errorOnContainerDark : AppColors.errorDark),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor : AppColors.accentDanger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detailsUnavailable)
                    // No record returned: no reason, description,
                    // reporter or reference is shown — none exists.
                    Text(
                      l10n?.blacklistDetailsUnavailable ??
                          'Blacklisted — details unavailable, refer to tribunal',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                    )
                  else ...[
                    Text(l10n?.blacklistReason(blacklistedRecord!.reasonCategory) ?? 'Reason: ${blacklistedRecord!.reasonCategory}', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(blacklistedRecord!.description, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(l10n?.blacklistReportedBy(blacklistedRecord!.reportedByShopId) ?? 'Reported By: ${blacklistedRecord!.reportedByShopId}', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.errorOnContainerFor(Theme.of(context).brightness))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Audit §19/C7: 54dp DebouncedButton (was 44dp).
            DebouncedButton(
              text: l10n?.blacklistDecline ?? 'Decline / Refuse Service',
              icon: Icons.block,
              backgroundColor: AppColors.errorDark,
              onPressed: onDecline ?? () {},
            ),
          ],
        ),
      );
    }

    // Clean Record
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successContainerFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.accentSuccessDark : AppColors.accentSuccess, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.successOnContainerFor(Theme.of(context).brightness), size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.blacklistCleanTitle ??
                          'No blacklist record found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                    ),
                    Text(
                      l10n?.blacklistCleanSubtitle ??
                          'Zero active defaults or tribunal complaints on file.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Audit §19/C7: 54dp DebouncedButton (was 44dp). orangeFill
          // carries the small white label in both modes (5.18:1).
          DebouncedButton(
            text: l10n?.blacklistProceed ?? 'Add Customer',
            icon: Icons.arrow_forward_rounded,
            backgroundColor: AppColors.orangeFill,
            onPressed: onProceed ?? () {},
          ),
        ],
      ),
    );
  }
}
