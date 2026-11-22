import 'package:flutter/material.dart';
import '../../../../core/widgets/app_feedback.dart';
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

class RentPackagePickerView extends StatefulWidget {
  final String carId, carName, plateNumber, shopId, shopName;
  final String? shopPhone;
  final int dailySelfDriveRate, dailyWithDriverRate;
  final int? hourlyRate, driverRatePerDayPkr;
  final VehicleEntity? vehicle;
  final bool initialWithDriver;
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
    this.shopPhone,
    required this.dailySelfDriveRate,
    required this.dailyWithDriverRate,
    this.hourlyRate,
    this.vehicle,
    this.initialWithDriver = false,
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
  TimeOfDay _pickupTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
  int _durationDays = 1;
  bool _isOutOfCity = false;
  FixedRouteEntity? _selectedRoute;
  PickerAvailabilityFeed? _availability;
  int? _driverRatePerDayPkr;
  int? get _driverRate => widget.driverRatePerDayPkr ?? _driverRatePerDayPkr;

  @override
  void initState() {
    super.initState();
    _isWithDriver = widget.initialWithDriver;
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
        fixedRoute: _selectedRoute,
      );

  PackageTierOption get _selectedTier => _tiers.firstWhere((t) => t.label == _selectedPackage, orElse: () => _tiers.first);

  int get _calculatedRate {
    if (_selectedRoute != null) {
      return _selectedRoute!.fixedPricePkr + (_isWithDriver ? (_driverRate ?? 0) * _durationDays : 0);
    }
    return PackagePricing.rateFor(vehicle: widget.vehicle, tier: _selectedTier, durationDays: _durationDays, isWithDriver: _isWithDriver, driverRatePerDayPkr: _driverRate);
  }

  int get _kmLimit => PackagePricing.kmLimitFor(tier: _selectedTier, durationDays: _durationDays);
  int get _advanceRequired => PackagePricing.advanceFor(vehicle: widget.vehicle, total: _calculatedRate);
  DateTime get _pickupDateTime => DateTime(_pickupDate.year, _pickupDate.month, _pickupDate.day, _pickupTime.hour, _pickupTime.minute);

  DateTime get _returnDateTime {
    final tier = _selectedTier;
    if (tier.hours < 24) return _pickupDateTime.add(Duration(hours: tier.hours));
    final days = PackagePricing.effectiveDaysFor(tier: tier, durationDays: _durationDays);
    return _pickupDateTime.add(Duration(days: days));
  }

  bool _spanHasBlockedDay() {
    final blocked = _availability?.blockedDays;
    if (blocked == null || blocked.isEmpty) return false;
    final start = DateTime(_pickupDate.year, _pickupDate.month, _pickupDate.day);
    final days = _selectedTier.hours < 24
        ? 1
        : PackagePricing.effectiveDaysFor(tier: _selectedTier, durationDays: _durationDays);
    for (var i = 0; i < days; i++) {
      if (blocked.contains(start.add(Duration(days: i)))) return true;
    }
    return false;
  }

  void _continue() {
    final l10n = AppLocalizations.of(context)!;
    if (_pickupDateTime.isBefore(DateTime.now())) {
      AppFeedback.showError(context, l10n.pickerPastTime);
      return;
    }
    if (_spanHasBlockedDay()) {
      AppFeedback.showError(context, l10n.manualBookingCarBusy);
      return;
    }
    widget.onProceedToReview?.call(buildBookingDraft(
      carId: widget.carId,
      carName: widget.carName,
      plateNumber: widget.plateNumber,
      shopId: widget.shopId,
      shopName: widget.shopName,
      shopPhone: widget.shopPhone,
      isWithDriver: _isWithDriver,
      tier: _selectedTier,
      kmLimit: _kmLimit,
      securityDepositPkr: widget.vehicle?.securityDepositPkr,
      driverNightStayPkr: widget.vehicle?.driverNightStayPkr,
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
                      showDurationStepper: _selectedTier.hours >= 24,
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
