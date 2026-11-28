import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';

/// 3-column bento KPI row (Bookings, Total Spent, Outstanding) with tabular
/// numbers and FittedBox so amounts never wrap or truncate.
class CustomerDetailKpiRow extends StatelessWidget {
  final int bookingCount;
  final int totalSpent;
  final int totalDues;

  const CustomerDetailKpiRow({
    super.key,
    required this.bookingCount,
    required this.totalSpent,
    required this.totalDues,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _kpiTile(context, l10n.customersTabBookings, '$bookingCount'),
        const SizedBox(width: 10),
        _kpiTile(
          context,
          l10n.customerDetailTotalSpent,
          l10n.amountRs(formatRs(totalSpent)),
        ),
        const SizedBox(width: 10),
        _kpiTile(
          context,
          l10n.customerDetailOutstandingShort,
          l10n.amountRs(formatRs(totalDues)),
          highlight: totalDues > 0,
        ),
      ],
    );
  }

  Widget _kpiTile(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.orangeContainerFor(brightness)
              : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppColors.orangeTextFor(brightness).withValues(alpha: 0.3)
                : (isDark ? cs.outlineVariant : AppColors.borderSubtle),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: highlight
                        ? AppColors.orangeTextFor(brightness)
                        : cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: highlight
                          ? AppColors.orangeTextFor(brightness)
                          : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unclipped 3-tab animated segmented switcher (Bookings | Personal Info | KYC & Docs).
class CustomerDetailSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CustomerDetailSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                key: ValueKey('customer_detail_tab_$i'),
                borderRadius: BorderRadius.circular(11),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selectedIndex == i
                        ? AppColors.primaryDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tabs[i],
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selectedIndex == i
                                  ? Colors.white
                                  : cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
