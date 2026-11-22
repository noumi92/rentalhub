import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../owner/presentation/widgets/fleet/pricing_trip_charges.dart';

class AdvanceDepositNoticeCard extends StatelessWidget {
  final bool isWithDriver;

  /// PW-11: the vehicle's own per-night driver stay rate. Null means
  /// the caller has no vehicle rate — the verified code default
  /// ([kDefaultDriverNightStayPkr], Rs. 2,000: the same fallback the
  /// agreement PDF and the return settlement use) applies, never the
  /// old hardcoded Rs. 1,500 figure.
  final int? driverNightStayPkr;

  const AdvanceDepositNoticeCard({
    super.key,
    required this.isWithDriver,
    this.driverNightStayPkr,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orangeContainerFor(Theme.of(context).brightness),
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
              // Consolidation: the title flexes so it wraps instead of
              // overflowing the row at 360px (BP-4 gap test).
              Expanded(
                child: Text(
                  l10n.advanceNoticeTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.orangeTextFor(Theme.of(context).brightness)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isWithDriver
                ? l10n.advanceNoticeWithDriver(l10n.amountRs(formatRs(
                    driverNightStayPkr ?? kDefaultDriverNightStayPkr)))
                : l10n.advanceNoticeSelfDrive,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

