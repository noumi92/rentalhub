import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (P4-O08): the "Estimated Rates" card for one vehicle —
/// In-City/day, Out-City/day, Weekly and Monthly, all read from the
/// vehicle's real packages and rates (the out-of-city day rate falls
/// back to the same daily × 1.3 derivation the rate matrix shows).
/// "Go to My Cars" returns to the fleet list.
class OwnerPriceEstimateView extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerPriceEstimateView({
    super.key,
    required this.vehicle,
    this.onBack,
  });

  /// OW-m17: null when the package is missing — the UI renders "—"
  /// instead of a confident "Rs. 0" for a price that is unknown.
  int? _priceOf(String label) {
    for (final p in vehicle.effectivePackages) {
      if (p.label == label) return p.pricePkr;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    final outCity = v.rates.outOfCityDaily ?? (v.rates.daily24 * 1.3).round();
    final rows = <(String, int?)>[
      (l10n.estimateInCityDay, v.rates.daily24),
      (l10n.estimateOutCityDay, outCity),
      (l10n.estimateWeekly, _priceOf('Weekly')),
      (l10n.estimateMonthly, _priceOf('Monthly')),
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.estimateTitle,
              subtitle: v.displayName,
              onBack: onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.estimateCardTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ...rows.map((row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(row.$1, style: Theme.of(context).textTheme.bodyMedium)),
                                      const SizedBox(width: 8),
                                      Text(row.$2 == null ? '—' : l10n.amountRs(formatRs(row.$2!)), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                )),
                            if (v.withDriverSurchargePkr != null && v.withDriverSurchargePkr! > 0) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(l10n.estimateWithDriverSurcharge, style: Theme.of(context).textTheme.bodyMedium)),
                                  const SizedBox(width: 8),
                                  Text(l10n.estimatePerDay(l10n.amountRs(formatRs(v.withDriverSurchargePkr!))), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                            if (v.securityDepositPkr != null) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(l10n.estimateDeposit, style: Theme.of(context).textTheme.bodyMedium)),
                                  const SizedBox(width: 8),
                                  Text(l10n.amountRs(formatRs(v.securityDepositPkr!)), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.estimateHint, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
              child: DebouncedButton(
                text: l10n.estimateGoToMyCars,
                icon: Icons.directions_car_rounded,
                onPressed: () async => context.go(RouteNames.ownerFleet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
