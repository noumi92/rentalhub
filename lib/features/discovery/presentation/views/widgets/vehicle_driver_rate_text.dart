import 'package:flutter/material.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_settings_data_source.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Worker 3 (2026-11-21): the with-driver daily rate label shared by
/// the fleet cards — `daily24 + shop booking-settings driver rate`.
/// Loads the rate from `booking_settings/{shopId}` in initState (the
/// same load pattern as RentPackagePickerView). Null while loading or
/// unset falls back to the self-drive rate (no surcharge), never
/// crashes, never blocks the card. The vehicle's stored
/// `withDriverSurchargePkr` is never read for display.
class VehicleDriverRateText extends StatefulWidget {
  const VehicleDriverRateText({
    super.key,
    required this.vehicle,
    this.style,
    this.textAlign,
    this.maxLines,
    this.settingsDataSource,
  });

  final VehicleEntity vehicle;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  /// Test seam — the shop booking-settings data source. Defaults to
  /// a fresh [BookingSettingsDataSource].
  final BookingSettingsDataSource? settingsDataSource;

  @override
  State<VehicleDriverRateText> createState() => _VehicleDriverRateTextState();
}

class _VehicleDriverRateTextState extends State<VehicleDriverRateText> {
  int? _driverRatePerDayPkr;

  @override
  void initState() {
    super.initState();
    (widget.settingsDataSource ?? BookingSettingsDataSource()).getSettings(widget.vehicle.shopId).then((s) { if (mounted) setState(() => _driverRatePerDayPkr = s.driverRatePerDayPkr); });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    return Text(
      l10n.vehicleDriverRate(formatRs(v.rates.daily24 + (_driverRatePerDayPkr ?? 0))),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: widget.textAlign,
    );
  }
}
