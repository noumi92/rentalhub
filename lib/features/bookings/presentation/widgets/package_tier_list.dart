import 'package:flutter/material.dart';

import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'package_tier_card.dart';

/// One selectable duration tier in the booking picker.
class PackageTierOption {
  const PackageTierOption({
    required this.label,
    required this.hours,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.kmIncluded,
  });

  final String label;
  final int hours;
  final String title;
  final String subtitle;
  final int price;
  final String kmIncluded;

  PackageTierOption copyWith({int? price, String? kmIncluded}) {
    return PackageTierOption(
      label: label,
      hours: hours,
      title: title,
      subtitle: subtitle,
      price: price ?? this.price,
      kmIncluded: kmIncluded ?? this.kmIncluded,
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
      // Out-of-city: the daily rate is the out-of-city rate, so every
      // tier scales by the same ratio; the km allowance becomes the
      // out-of-city allowance (350 km/day by default).
      if (isOutOfCity && vehicle.rates.daily24 > 0) {
        final outDaily =
            vehicle.rates.outOfCityDaily ?? vehicle.rates.daily24;
        final ratio = outDaily / vehicle.rates.daily24;
        final outKm = vehicle.outOfCityKmPerDay ?? 350;
        options = options.map((o) {
          final km = o.hours >= 24 ? '$outKm km/day' : o.kmIncluded;
          return o.copyWith(
              price: (o.price * ratio).round(), kmIncluded: km);
        }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          PackageTierCard(
            title: options[i].title,
            subtitle: options[i].subtitle,
            price: options[i].price + surchargeFor(options[i]),
            kmIncluded: options[i].kmIncluded,
            isSelected: selectedLabel == options[i].label,
            onTap: () => onSelect(options[i].label),
          ),
          if (i < options.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
