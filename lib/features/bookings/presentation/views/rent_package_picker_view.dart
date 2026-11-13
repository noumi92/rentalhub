import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/utils/package_pricing.dart';
import '../../../bookings/utils/picker_availability.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import '../widgets/booking_draft.dart';
import '../widgets/driver_mode_toggle.dart';
import '../widgets/duration_calendar_picker.dart';
import '../widgets/package_picker_header.dart';
import '../widgets/package_summary_bar.dart';
import '../widgets/package_tier_list.dart';
import '../widgets/trip_type_section.dart';
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
  Set<DateTime> _blockedDates = {};
  List<FixedRouteEntity> _fixedRoutes = [];
  FixedRouteEntity? _selectedRoute;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _selectedPackage = PackageTierList.defaultSelection(vehicle);
      if (sl.isRegistered<BookingRemoteDataSource>() ||
          sl.isRegistered<GetShopFixedRoutesUseCase>()) {
        loadPickerAvailability(vehicleId: vehicle.vehicleId, shopId: widget.shopId).then((data) {
          if (!mounted) return;
          setState(() {
            _blockedDates = data.blockedDays;
            _fixedRoutes = data.routes;
          });
        });
      }
    }
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
      final driver = _isWithDriver
          ? (widget.vehicle?.withDriverSurchargePkr ?? 0) * _durationDays
          : 0;
      return _selectedRoute!.fixedPricePkr + driver;
    }
    return PackagePricing.rateFor(
      vehicle: widget.vehicle,
      tier: _selectedTier,
      durationDays: _durationDays,
      isWithDriver: _isWithDriver,
    );
  }

  int get _kmLimit => PackagePricing.kmLimitFor(tier: _selectedTier, durationDays: _durationDays);

  int get _advanceRequired => PackagePricing.advanceFor(vehicle: widget.vehicle, total: _calculatedRate);

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
                    if (vehicle != null) ...[
                      const SizedBox(height: 12),
                      TripTypeSection(
                        isOutOfCity: _isOutOfCity,
                        onChanged: (v) => setState(() {
                          _isOutOfCity = v;
                          _selectedRoute = null;
                        }),
                        fixedRoutes: _fixedRoutes,
                        selectedRoute: _selectedRoute,
                        onRouteSelected: (r) =>
                            setState(() => _selectedRoute = r),
                        // CU-m17: the section states the out-of-city
                        // price basis from the vehicle's own fields.
                        outCityMode: vehicle.outCityMode,
                        outCityPerKmPkr: vehicle.outCityPerKmPkr,
                        outCityDailyPkr: vehicle.rates.outOfCityDaily ??
                            vehicle.rates.daily24,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(l10n.packageTiersTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    PackageTierList(
                      options: tiers,
                      selectedLabel: _selectedPackage,
                      onSelect: (label) => setState(() {
                        _selectedPackage = label;
                        _selectedRoute = null;
                      }),
                      surchargeFor: (o) =>
                          PackagePricing.driverSurchargeFor(
                        vehicle: widget.vehicle,
                        tier: o,
                        isWithDriver: _isWithDriver,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DurationCalendarPicker(
                      pickupDate: _pickupDate,
                      pickupTime: _pickupTime,
                      durationDays: _durationDays,
                      blockedDates: _blockedDates,
                      onDateChanged: (d) => setState(() => _pickupDate = d),
                      onTimeChanged: (t) => setState(() => _pickupTime = t),
                      onDurationChanged: (days) =>
                          setState(() => _durationDays = days),
                    ),
                    const SizedBox(height: 20),
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
