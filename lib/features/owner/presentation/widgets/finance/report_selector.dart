import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// The reports period selector (This month / Last month / All
/// time). Lives with the selector so [OwnerReportsView] stays
/// under the 250-line cap.
class ReportPeriodDropdown extends StatelessWidget {
  final String period;
  final ValueChanged<String> onChanged;

  const ReportPeriodDropdown({
    super.key,
    required this.period,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButton<String>(
      dropdownColor: Theme.of(context).colorScheme.surface,
      value: period,
      items: [
        DropdownMenuItem(
            value: 'this_month', child: Text(l10n.financeThisMonth)),
        DropdownMenuItem(
            value: 'last_month', child: Text(l10n.financeLastMonth)),
        DropdownMenuItem(
            value: 'all', child: Text(l10n.financeAllTime)),
      ],
      onChanged: (v) => onChanged(v ?? 'this_month'),
    );
  }
}

/// Audit impl (O37): the report cards — Monthly Earnings Report,
/// Car-wise Earnings, Customer History. Tapping one selects it;
/// the selected card is highlighted. Extracted from
/// [OwnerReportsView] so the view stays under the 250-line cap.
class ReportSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const ReportSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _card(
          context,
          key: 'monthly',
          icon: Icons.bar_chart_rounded,
          title: l10n.reportMonthlyEarnings,
          subtitle: l10n.reportMonthlyEarningsHint,
        ),
        _card(
          context,
          key: 'carwise',
          icon: Icons.directions_car_rounded,
          title: l10n.reportCarWise,
          subtitle: l10n.reportCarWiseHint,
        ),
        _card(
          context,
          key: 'customer',
          icon: Icons.people_rounded,
          title: l10n.reportCustomerHistory,
          subtitle: l10n.reportCustomerHistoryHint,
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selected == key;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title,
            style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () => onSelect(key),
      ),
    );
  }
}
