import 'package:flutter/material.dart';
import '../../../bookings/data/datasources/booking_settings_data_source.dart';
import '../../../bookings/utils/package_pricing.dart';
import '../../../bookings/utils/picker_availability.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/booking_draft.dart';
import '../widgets/driver_mode_toggle.dart';
import '../widgets/duration_calendar_picker.dart';
import '../widgets/package_picker_header.dart';
import '../widgets/package_summary_bar.dart';
import '../widgets/package_tier_list.dart';
import '../widgets/picker_out_city_section.dart';
import '../../../../l10n/app_localizations.dart';

/// Phase B (B2): when a [vehicle] is supplied, the picker offers only
/// that vehicle's enabled packages at their real prices, with the
/// driver surcharge and advance taken from the vehicle — no formula
/// prices. Without a vehicle it keeps the old behaviour (derived
/// prices from the daily/hourly rates) for the legacy callers.
class RentPackagePickerView extends StatefulWidget {
  final String carId;
  final String carName;
  final String plateNumber;
  final String shopId;
  final String shopName;
  final int dailySelfDriveRate;
  final int dailyWithDriverRate;
  final int? hourlyRate;
  final VehicleEntity? vehicle;
  // Worker A (2026-11-21): test/route override for the shop's
  // booking-settings driver rate (Rs/day). When null the picker
  // loads it from `booking_settings/{shopId}` itself.
  final int? driverRatePerDayPkr;
  // Worker E: carried into the booking draft when the caller knows the shop's verification state (null = unknown; the review screen looks it up and fails open).
  final bool? shopIsVerified;
  final Function(Map<String, dynamic> bookingDraft)? onProceedToReview;
  final VoidCallback? onBack;

  const RentPackagePickerView({
    super.key,
    required this.carId,
    required this.carName,
    required this.plateNumber,
    required this.shopId,
    required this.shopName,
    required this.dailySelfDriveRate,
    required this.dailyWithDriverRate,
    this.hourlyRate,
    this.vehicle,
    this.driverRatePerDayPkr,
    this.shopIsVerified,
    this.onProceedToReview,
    this.onBack,
  });

  @override
  State<RentPackagePickerView> createState() => _RentPackagePickerViewState();
}

class _RentPackagePickerViewState extends State<RentPackagePickerView> {
  bool _isWithDriver = false;
  String _selectedPackage = '24h';
  DateTime _pickupDate = DateTime.now().add(const Duration(hours: 2));
  // CU-m18: the time matches the date (now + 2h) — TimeOfDay.now()
  // made the default pickup "today at the current time", already
  // past by the time the user looks at it.
  TimeOfDay _pickupTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
  int _durationDays = 1;

  /// Phase B (B3): trip type, the car's booked days and the shop's
  /// fixed routes. Loaded only when a vehicle is supplied and DI is
  /// initialised (legacy callers and unit tests run without it).
  bool _isOutOfCity = false;
  FixedRouteEntity? _selectedRoute;
  // Live updates (Item 2): the availability feed — blocked days + fixed routes, kept live while the picker is open.
  PickerAvailabilityFeed? _availability;
  // Worker A (2026-11-21): the shop's booking-settings driver rate
  // (Rs/day), loaded in initState when no override was passed.
  // Null (unset) charges Rs. 0 — the vehicle's stored surcharge is
  // never read by pricing.
  int? _driverRatePerDayPkr;
  int? get _driverRate => widget.driverRatePerDayPkr ?? _driverRatePerDayPkr;

  @override
  void initState() {
    super.initState();
    if (widget.driverRatePerDayPkr == null) BookingSettingsDataSource().getSettings(widget.shopId).then((s) { if (mounted) setState(() => _driverRatePerDayPkr = s.driverRatePerDayPkr); });
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _selectedPackage = PackageTierList.defaultSelection(vehicle);
      _availability = PickerAvailabilityFeed(
        vehicleId: vehicle.vehicleId,
        shopId: widget.shopId,
        onChanged: () { if (mounted) setState(() {}); },
      )..load();
    }
  }

  @override
  void dispose() {
    _availability?.dispose();
    super.dispose();
  }

  List<PackageTierOption> get _tiers => PackageTierList.optionsFor(
        vehicle: widget.vehicle,
        isWithDriver: _isWithDriver,
        dailySelfDriveRate: widget.dailySelfDriveRate,
        dailyWithDriverRate: widget.dailyWithDriverRate,
        hourlyRate: widget.hourlyRate,
        isOutOfCity: _isOutOfCity,
        // 09b §2: when a fixed route is chosen the tiers show its flat
        // price (the total already charges it in _calculatedRate).
        fixedRoute: _selectedRoute,
      );

  PackageTierOption get _selectedTier => _tiers.firstWhere((t) => t.label == _selectedPackage, orElse: () => _tiers.first);

  int get _calculatedRate {
    // A fixed route is one fixed trip price; a chauffeur is added on
    // top, per day of the trip.
    if (_selectedRoute != null) {
      final driver = _isWithDriver ? (_driverRate ?? 0) * _durationDays : 0;
      return _selectedRoute!.fixedPricePkr + driver;
    }
    return PackagePricing.rateFor(vehicle: widget.vehicle, tier: _selectedTier, durationDays: _durationDays, isWithDriver: _isWithDriver, driverRatePerDayPkr: _driverRate);
  }

  int get _kmLimit => PackagePricing.kmLimitFor(tier: _selectedTier, durationDays: _durationDays);

  int get _advanceRequired => PackagePricing.advanceFor(vehicle: widget.vehicle, total: _calculatedRate);

  DateTime get _pickupDateTime => DateTime(_pickupDate.year, _pickupDate.month, _pickupDate.day, _pickupTime.hour, _pickupTime.minute);

  DateTime get _returnDateTime => _pickupDateTime.add(Duration(days: _durationDays));

  void _continue() {
    widget.onProceedToReview?.call(buildBookingDraft(
      carId: widget.carId,
      carName: widget.carName,
      plateNumber: widget.plateNumber,
      shopId: widget.shopId,
      shopName: widget.shopName,
      isWithDriver: _isWithDriver,
      tier: _selectedTier,
      kmLimit: _kmLimit,
      securityDepositPkr: widget.vehicle?.securityDepositPkr,
      tripType: _isOutOfCity ? 'out_of_city' : 'in_city',
      fixedRouteId: _selectedRoute?.routeId,
      fixedRouteSummary: _selectedRoute?.displayName,
      destinationCity: _selectedRoute?.destinationCity,
      outCityMode: widget.vehicle?.outCityMode,
      outCityPerKmPkr: widget.vehicle?.outCityPerKmPkr,
      pickupDate: _pickupDate,
      pickupTime: _pickupTime,
      durationDays: _durationDays,
      totalAmount: _calculatedRate,
      advanceRequired: _advanceRequired,
      shopIsVerified: widget.shopIsVerified,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiers = _tiers;
    final vehicle = widget.vehicle;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PackagePickerHeader(
              carName: widget.carName,
              shopName: widget.shopName,
              plateNumber: widget.plateNumber,
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DriverModeToggle(
                      isWithDriver: _isWithDriver,
                      onChanged: (val) => setState(() => _isWithDriver = val),
                    ),
                    if (vehicle != null)
                      PickerOutCitySection(
                        vehicle: vehicle,
                        isOutOfCity: _isOutOfCity,
                        onChanged: (v) => setState(() {
                          _isOutOfCity = v;
                          _selectedRoute = null;
                        }),
                        routes: _availability?.routes ?? const [],
                        selectedRoute: _selectedRoute,
                        onRouteSelected: (r) =>
                            setState(() => _selectedRoute = r),
                        pickup: _pickupDateTime,
                        returnTime: _returnDateTime,
                        kmPerDay: _selectedTier.perKmKmPerDay ??
                            vehicle.outOfCityKmPerDay ??
                            kDefaultOutCityKmPerDay,
                      ),
                    const SizedBox(height: 16),
                    Text(l10n.packageTiersTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    PackageTierList(
                      options: tiers,
                      selectedLabel: _selectedPackage,
                      onSelect: (label) => setState(() {
                        _selectedPackage = label;
                        _selectedRoute = null;
                      }),
                      surchargeFor: (o) => PackagePricing.driverSurchargeFor(vehicle: widget.vehicle, tier: o, isWithDriver: _isWithDriver, driverRatePerDayPkr: _driverRate),
                    ),
                    const SizedBox(height: 16),
                    DurationCalendarPicker(
                      pickupDate: _pickupDate,
                      pickupTime: _pickupTime,
                      durationDays: _durationDays,
                      blockedDates: _availability?.blockedDays ?? const {},
                      onDateChanged: (d) => setState(() => _pickupDate = d),
                      onTimeChanged: (t) => setState(() => _pickupTime = t),
                      onDurationChanged: (days) =>
                          setState(() => _durationDays = days),
                    ),
                  ],
                ),
              ),
            ),
            PackageSummaryBar(
              total: _calculatedRate,
              advance: _advanceRequired,
              deposit: vehicle?.securityDepositPkr,
              onContinue: _continue,
            ),
          ],
        ),
      ),
    );
  }
}
