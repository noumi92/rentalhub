import 'package:flutter/material.dart';

import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'package_tier_card.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';

/// One selectable duration tier in the booking picker.
class PackageTierOption {
  const PackageTierOption({
    required this.label,
    required this.hours,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.kmIncluded,
    this.perKmRatePkr,
    this.perKmKmPerDay,
  });

  final String label;
  final int hours;
  final String title;
  final String subtitle;
  final int price;
  final String kmIncluded;

  /// 09b §2: set when the tier price is a per-km ESTIMATE, not a flat
  /// package price — the Rs/km rate and the km/day it was estimated
  /// on (stored allowance, default [kDefaultOutCityKmPerDay]). The card shows the rate
  /// ([PackageTierList] renders it via `farePerKmUnit`) and the
  /// estimate note; the final total settles on actual km at return.
  final int? perKmRatePkr;
  final int? perKmKmPerDay;

  PackageTierOption copyWith({int? price, String? kmIncluded, int? perKmRatePkr, int? perKmKmPerDay}) {
    return PackageTierOption(
      label: label,
      hours: hours,
      title: title,
      subtitle: subtitle,
      price: price ?? this.price,
      kmIncluded: kmIncluded ?? this.kmIncluded,
      perKmRatePkr: perKmRatePkr ?? this.perKmRatePkr,
      perKmKmPerDay: perKmKmPerDay ?? this.perKmKmPerDay,
    );
  }
}

const Map<String, ({String title, String subtitle, String km})>
    _tierCopy = {
  '1h': (
    title: '1-Hour City Commute',
    subtitle: 'Quick city hops',
    km: '15 km',
  ),
  '3h': (
    title: '3-Hour Quick Trip',
    subtitle: 'Airport drop/pickup & short commutes',
    km: '40 km',
  ),
  '6h': (
    title: '6-Hour Express',
    subtitle: 'Ideal for city errands, weddings & meetings',
    km: '80 km',
  ),
  '12h': (
    title: '12-Hour Half Day',
    subtitle: 'Half-day outings & events',
    km: '150 km',
  ),
  '24h': (
    title: 'Daily 24-Hours',
    subtitle: 'Full day flexibility with grace return period',
    km: '250 km/day',
  ),
  'Weekly': (
    title: 'Weekly Package',
    subtitle: 'Seven days, one price',
    km: '250 km/day',
  ),
  'Monthly': (
    title: 'Monthly Package',
    subtitle: 'Thirty days, one price',
    km: '250 km/day',
  ),
};

/// The tier cards of the booking picker, extracted from
/// [RentPackagePickerView] so the view stays under the 250-line cap.
/// Phase B (B2): with a vehicle, the options are its enabled packages
/// at their real prices; without one, the legacy derived prices.
class PackageTierList extends StatelessWidget {
  const PackageTierList({
    super.key,
    required this.options,
    required this.selectedLabel,
    required this.onSelect,
    required this.surchargeFor,
  });

  final List<PackageTierOption> options;
  final String selectedLabel;
  final ValueChanged<String> onSelect;
  final int Function(PackageTierOption option) surchargeFor;

  /// The default selected package: '24h' when enabled, otherwise
  /// the first enabled package.
  static String defaultSelection(VehicleEntity? vehicle) {
    final enabled = vehicle?.enabledPackages ?? const [];
    if (enabled.isNotEmpty && !enabled.any((p) => p.label == '24h')) {
      return enabled.first.label;
    }
    return '24h';
  }

  static List<PackageTierOption> optionsFor({
    required VehicleEntity? vehicle,
    required bool isWithDriver,
    required int dailySelfDriveRate,
    required int dailyWithDriverRate,
    required int? hourlyRate,
    bool isOutOfCity = false,
    FixedRouteEntity? fixedRoute,
  }) {
    if (vehicle != null) {
      var options = vehicle.enabledPackages.map((p) {
        final copy = _tierCopy[p.label]!;
        return PackageTierOption(
          label: p.label,
          hours: p.hours,
          title: copy.title,
          subtitle: copy.subtitle,
          price: p.pricePkr,
          kmIncluded: copy.km,
        );
      }).toList();
      // Out-of-city modes (09b §2). A chosen fixed route is one flat
      // trip price — the picker already charges it in
      // [RentPackagePickerView._calculatedRate] — so every tier shows
      // that price and the route distance, whatever the vehicle mode.
      // Per-km tiers show the ESTIMATE for their duration (rate ×
      // km/day × hours/24) with the rate on the card, never a flat
      // package price. Per-day keeps the ratio scaling below.
      if (isOutOfCity) {
        if (fixedRoute != null) {
          options = options
              .map((o) => o.copyWith(
                  price: fixedRoute.fixedPricePkr,
                  kmIncluded: '${fixedRoute.distanceKm} km'))
              .toList();
        } else if (vehicle.outCityMode == 'perKm' &&
            (vehicle.outCityPerKmPkr ?? 0) > 0) {
          final rate = vehicle.outCityPerKmPkr!;
          final kmPerDay = vehicle.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay;
          options = options.map((o) {
            final estKm = (kmPerDay * o.hours / 24).round();
            return o.copyWith(
                price: (rate * kmPerDay * o.hours / 24).round(),
                kmIncluded: '$estKm km',
                perKmRatePkr: rate,
                perKmKmPerDay: kmPerDay);
          }).toList();
        } else if (vehicle.rates.daily24 > 0) {
          // Out-of-city: the daily rate is the out-of-city rate, so every
          // tier scales by the same ratio; the km allowance becomes the
          // out-of-city allowance ([kDefaultOutCityKmPerDay] km/day by default).
          final outDaily =
              vehicle.rates.outOfCityDaily ?? vehicle.rates.daily24;
          final ratio = outDaily / vehicle.rates.daily24;
          final outKm = vehicle.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay;
          options = options.map((o) {
            final km = o.hours >= 24 ? '$outKm km/day' : o.kmIncluded;
            return o.copyWith(
                price: (o.price * ratio).round(), kmIncluded: km);
          }).toList();
        }
      }
      return options;
    }
    final baseDaily =
        isWithDriver ? dailyWithDriverRate : dailySelfDriveRate;
    final hourly = hourlyRate ?? (baseDaily * 0.15).round();
    return [
      PackageTierOption(
          label: '24h',
          hours: 24,
          title: 'Daily 24-Hours',
          subtitle: 'Full day flexibility with grace return period',
          price: baseDaily,
          kmIncluded: '250 km/day'),
      PackageTierOption(
          label: '6h',
          hours: 6,
          title: '6-Hour Express',
          subtitle: 'Ideal for city errands, weddings & meetings',
          price: (hourly * 4.5).round(),
          kmIncluded: '80 km'),
      PackageTierOption(
          label: '3h',
          hours: 3,
          title: '3-Hour Quick Trip',
          subtitle: 'Airport drop/pickup & short commutes',
          price: (hourly * 2.5).round(),
          kmIncluded: '40 km'),
      PackageTierOption(
          label: '1h',
          hours: 1,
          title: '1-Hour City Commute',
          subtitle: 'Quick city hops',
          price: hourly,
          kmIncluded: '15 km'),
    ];
  }

  /// Titles/subtitles are display-only: the tier `label` ('1h', '24h',
  /// 'Weekly') is the data key and stays English; the card shows the
  /// localized copy for that label.
  static String _titleFor(AppLocalizations l10n, PackageTierOption o) {
    switch (o.label) {
      case '1h':
        return l10n.pkg1h;
      case '3h':
        return l10n.pkg3h;
      case '6h':
        return l10n.pkg6h;
      case '12h':
        return l10n.pkg12h;
      case '24h':
        return l10n.pkgDaily;
      case 'Weekly':
        return l10n.pkgWeeklyPackage;
      case 'Monthly':
        return l10n.pkgMonthlyPackage;
      default:
        return o.title;
    }
  }

  static String _subtitleFor(AppLocalizations l10n, PackageTierOption o) {
    switch (o.label) {
      case '1h':
        return l10n.pkg1hDesc;
      case '3h':
        return l10n.pkg3hDesc;
      case '6h':
        return l10n.pkg6hDesc;
      case '12h':
        return l10n.pkg12hDesc;
      case '24h':
        return l10n.pkgDailyDesc;
      case 'Weekly':
        return l10n.pkgWeeklyDesc;
      case 'Monthly':
        return l10n.pkgMonthlyDesc;
      default:
        return o.subtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 09b §2: per-km tiers carry the rate — the card's km pill shows
    // "Rs. 30 / km" (farePerKmUnit) instead of a km allowance, and
    // the estimate note says the total is estimated on the allowance.
    final perKmRate = options.isNotEmpty ? options.first.perKmRatePkr : null;
    final perKmKmPerDay =
        options.isNotEmpty ? options.first.perKmKmPerDay : null;
    return Column(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          PackageTierCard(
            title: _titleFor(l10n, options[i]),
            subtitle: _subtitleFor(l10n, options[i]),
            price: options[i].price + surchargeFor(options[i]),
            kmIncluded: perKmRate != null
                ? l10n.farePerKmUnit(l10n.amountRs(formatRs(perKmRate)))
                : options[i].kmIncluded,
            isSelected: selectedLabel == options[i].label,
            onTap: () => onSelect(options[i].label),
          ),
          if (i < options.length - 1) const SizedBox(height: 10),
        ],
        if (perKmRate != null && perKmKmPerDay != null) ...[
          const SizedBox(height: 10),
          Text(l10n.farePerKmEstimate(perKmKmPerDay),
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ],
    );
  }
}
