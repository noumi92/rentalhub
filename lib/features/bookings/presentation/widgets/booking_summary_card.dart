import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';

class BookingSummaryCard extends StatelessWidget {
  final String carName;
  final String plateNumber;
  final String shopName;
  final bool isWithDriver;
  final String packageType;
  final DateTime pickupTime;
  final DateTime returnTime;
  final int totalAmount;
  final int advanceRequired;
  // C2: the trip details the picker chose — shown when the caller has
  // them (the review screen does; older call sites omit them).
  final String tripType;
  final int? kmLimit;
  final int? securityDepositPkr;
  final String? destinationCity;

  const BookingSummaryCard({
    super.key,
    required this.carName,
    required this.plateNumber,
    required this.shopName,
    required this.isWithDriver,
    required this.packageType,
    required this.pickupTime,
    required this.returnTime,
    required this.totalAmount,
    required this.advanceRequired,
    this.tripType = 'in_city',
    this.kmLimit,
    this.securityDepositPkr,
    this.destinationCity,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.summaryShowroom(shopName),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true),
            ],
          ),
          const Divider(height: 24),
          _buildRow(context, l10n.summaryMode, isWithDriver ? l10n.withChauffeur : l10n.selfDriveHyphen),
          const SizedBox(height: 8),
          _buildRow(context, l10n.summaryPackageTier, l10n.summaryPackageRental(packageType)),
          const SizedBox(height: 8),
          _buildRow(context, 
            l10n.summaryTrip,
            tripType == 'out_of_city'
                ? (destinationCity != null
                    ? l10n.summaryOutOfCityTo(destinationCity!)
                    : l10n.outOfCity)
                : l10n.inCity,
          ),
          if (kmLimit != null) ...[
            const SizedBox(height: 8),
            _buildRow(context, l10n.summaryKmIncluded, '$kmLimit km'),
          ],
          if (securityDepositPkr != null) ...[
            const SizedBox(height: 8),
            _buildRow(context, 
              l10n.summarySecurityDeposit,
              l10n.summaryDepositAtHandover(formatRs(securityDepositPkr!)),
            ),
          ],
          const SizedBox(height: 8),
          _buildRow(context,
            l10n.summaryPickupTime,
            // CU-m4: locale-aware date + time, not ambiguous d/M/yyyy.
            '${DateFormat.yMMMd(locale).format(pickupTime)} • ${DateFormat.jm(locale).format(pickupTime)}',
          ),
          const SizedBox(height: 8),
          _buildRow(context,
            l10n.summaryReturnDue,
            '${DateFormat.yMMMd(locale).format(returnTime)} • ${DateFormat.jm(locale).format(returnTime)}',
          ),
          const Divider(height: 24),
          _buildRow(context, l10n.summaryTotalFare, l10n.amountRs(formatRs(totalAmount)), isBold: true),
          const SizedBox(height: 8),
          _buildRow(context, 
            l10n.summaryAdvancePayable,
            l10n.amountRs(formatRs(advanceRequired)),
            color: AppColors.orangeTextFor(Theme.of(context).brightness),
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildRow(context, 
            l10n.summaryBalanceAtHandover,
            l10n.amountRs(formatRs(totalAmount - advanceRequired)),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // CU-m5: the value wraps instead of overflowing at large
        // text scale.
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isBold ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

