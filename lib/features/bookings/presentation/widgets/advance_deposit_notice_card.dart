import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class AdvanceDepositNoticeCard extends StatelessWidget {
  final bool isWithDriver;

  const AdvanceDepositNoticeCard({
    super.key,
    required this.isWithDriver,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.orangeTextFor(
                      Theme.of(context).brightness),
                  size: 18),
              SizedBox(width: 8),
              Text(
                l10n.advanceNoticeTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.orangeTextFor(Theme.of(context).brightness)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isWithDriver
                ? l10n.advanceNoticeWithDriver
                : l10n.advanceNoticeSelfDrive,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

