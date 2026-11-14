import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// The Out-City tab header (09b §2): the active mode instead of only
/// the daily rate — the per-day rate, the per-km rate with its
/// estimate note, or the fixed route with its flat price. A
/// fixed-route vehicle whose route cannot be resolved says so and
/// the rows below fall back to the per-day ratio scaling.
class FareTableOutCityHeader extends StatelessWidget {
  const FareTableOutCityHeader({super.key, required this.vehicle, required this.fixedRoute, required this.loadingRoute, required this.routeFailed, required this.onRetryRoute});

  final VehicleEntity vehicle;
  final FixedRouteEntity? fixedRoute;
  final bool loadingRoute;
  final bool routeFailed;
  final VoidCallback onRetryRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    final bold = Theme.of(context).textTheme.bodyMedium;
    if (v.outCityMode == 'perKm' && (v.outCityPerKmPkr ?? 0) > 0) {
      final rate = v.outCityPerKmPkr!;
      final kmPerDay = v.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.farePerKmUnit(l10n.amountRs(formatRs(rate))), style: bold),
            Text(l10n.farePerKmEstimate(kmPerDay), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
    }
    if (v.outCityMode == 'fixedRoute') {
      if (loadingRoute) {
        // OW-m16: the shared loading state, not a bare spinner.
        return const Padding(padding: EdgeInsets.only(bottom: 8), child: AppLoadingState());
      }
      if (routeFailed) {
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: AppErrorState(message: l10n.fixedRoutesLoadError, onRetry: onRetryRoute));
      }
      final route = fixedRoute;
      if (route == null) {
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l10n.outCityFixedRouteNone, style: bold));
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.fareFixedRoute(route.displayName), style: bold),
            Text(l10n.fixedRouteSummary(route.distanceKm, formatRs(route.fixedPricePkr)), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(l10n.fareOutCityDaily(l10n.amountRs(formatRs(v.rates.outOfCityDaily ?? (v.rates.daily24 * 1.3).round()))), style: bold),
    );
  }
}
