import 'package:flutter/material.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (P4-O07): the owner's custom rates on the rate matrix —
/// named rates for periods the seven standard packages do not cover.
/// The list starts empty and is never prefilled; each row has a
/// delete action, and "Add rate" opens a small dialog (name + price
/// + period). The parent owns the list and persists it with the
/// rest of the matrix via [UpdateVehiclePricingUseCase].
class PricingCustomRates extends StatelessWidget {
  const PricingCustomRates({
    super.key,
    required this.customRates,
    required this.onChanged,
  });

  final List<CustomRateEntity> customRates;
  final ValueChanged<List<CustomRateEntity>> onChanged;

  static String _periodLabel(AppLocalizations l10n, String period) =>
      {'hourly': l10n.ratesCustomPeriodHourly, 'daily': l10n.ratesCustomPeriodDaily, 'weekly': l10n.ratesCustomPeriodWeekly, 'monthly': l10n.ratesCustomPeriodMonthly}[period] ?? period;

  Future<void> _showAddDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String period = 'daily';
    final added = await showDialog<CustomRateEntity>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.ratesCustomAddTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.ratesCustomNameLabel,
                  hintText: l10n.ratesCustomNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.ratesCustomPriceLabel,
                  prefixText: 'Rs. ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: period,
                decoration: InputDecoration(
                  labelText: l10n.ratesCustomPeriodLabel,
                  border: const OutlineInputBorder(),
                ),
                items: ['hourly', 'daily', 'weekly', 'monthly']
                    .map((p) => DropdownMenuItem(value: p, child: Text(_periodLabel(l10n, p))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => period = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = int.tryParse(priceController.text.trim());
                if (name.isEmpty || price == null || price <= 0) {
                  AppFeedback.showError(ctx, l10n.ratesCustomInvalid);
                  return;
                }
                Navigator.of(ctx).pop(CustomRateEntity(name: name, pricePkr: price, period: period));
              },
              child: Text(l10n.ratesCustomAdd),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    priceController.dispose();
    if (added != null) onChanged([...customRates, added]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.ratesCustomTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.ratesCustomAdd),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (customRates.isEmpty)
          Text(l10n.ratesCustomEmpty, style: Theme.of(context).textTheme.labelSmall)
        else
          ...customRates.asMap().entries.map((entry) {
            final i = entry.key;
            final rate = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(rate.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${_periodLabel(l10n, rate.period)} • ${l10n.amountRs(formatRs(rate.pricePkr))}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: l10n.ratesCustomDelete,
                  onPressed: () {
                    final updated = List.of(customRates)..removeAt(i);
                    onChanged(updated);
                  },
                ),
              ),
            );
          }),
      ],
    );
  }
}
