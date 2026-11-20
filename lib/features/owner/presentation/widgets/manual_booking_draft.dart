import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../bookings/utils/package_pricing.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/guarantor_picker.dart';
import '../widgets/manual_booking_package_selector.dart';

/// The walk-in wizard's draft: everything steps 1–3 collect, plus
/// the money math and the per-step validation. The view owns the
/// step index and the vehicle load; this class owns the rest, so
/// the view stays under the 250-line cap.
///
/// Money: rent = package total without the driver surcharge,
/// driver = the with-driver total minus rent, total = rent +
/// driver − discount. Advance required comes from
/// [PackagePricing.advanceFor] on the discounted total.
class ManualBookingDraft {
  ManualBookingDraft({
    DateTime? pickupTime,
    DateTime? returnTime,
    this.isOutOfCity = false,
  })  : _pickupTime = pickupTime ?? DateTime.now(),
        _returnTime = returnTime ??
            (pickupTime ?? DateTime.now()).add(const Duration(hours: 24));

  CustomerEntity? selectedCustomer;
  GuarantorSelection? guarantor;
  VehicleEntity? selectedVehicle;
  VehiclePackageEntity? selectedPackage;
  FixedRouteEntity? selectedRoute;
  bool isWithDriver = false;
  bool returnEdited = false;
  bool? carFree;

  DateTime _pickupTime;
  DateTime _returnTime;
  bool isOutOfCity;

  DateTime get pickupTime => _pickupTime;
  DateTime get returnTime => _returnTime;

  final discountController = TextEditingController(text: '0');
  final advanceController = TextEditingController();
  final depositController = TextEditingController();
  String paymentMethod = 'cash';
  bool depositReceived = true;
  String depositMethod = 'cash';
  bool addToDues = true;
  String? discountError;
  String? advanceError;

  void dispose() {
    discountController.dispose();
    advanceController.dispose();
    depositController.dispose();
  }

  int get rentAmount => ManualBookingPackageSelector.totalFor(
      vehicle: selectedVehicle, package: selectedPackage, isWithDriver: false,
      isOutOfCity: isOutOfCity, pickup: _pickupTime, returnTime: _returnTime, fixedRoute: selectedRoute);

  int get driverAmount {
    // The driver surcharge is charged ONLY when the owner chose a
    // driver. (A hardcoded isWithDriver: true here used to charge
    // every walk-in the full surcharge, inflating the total and the
    // advance required: with dues off the booking could not be
    // saved in full, and the phantom charge re-appeared as a
    // balance due after creation — "the advance was never
    // recorded".)
    if (!isWithDriver) return 0;
    return (ManualBookingPackageSelector.totalFor(vehicle: selectedVehicle, package: selectedPackage, isWithDriver: true,
            isOutOfCity: isOutOfCity, pickup: _pickupTime, returnTime: _returnTime, fixedRoute: selectedRoute) -
        rentAmount)
        .clamp(0, 1 << 30);
  }

  int get discount =>
      (int.tryParse(discountController.text.trim()) ?? 0).clamp(0, 1 << 30);
  int get total => (rentAmount + driverAmount - discount).clamp(0, 1 << 30);
  int get advanceRequired =>
      PackagePricing.advanceFor(vehicle: selectedVehicle, total: total);
  int get advanceReceived =>
      (int.tryParse(advanceController.text.trim()) ?? 0).clamp(0, total);
  int get remaining => (total - advanceReceived).clamp(0, 1 << 30);
  double? get depositAmount => depositReceived
      ? (double.tryParse(depositController.text.trim()) ?? 0)
      : null;

  void selectVehicle(VehicleEntity? v) {
    selectedVehicle = v;
    selectedRoute = null;
    final packages = v?.enabledPackages ?? const [];
    selectedPackage = packages.isNotEmpty ? packages.first : null;
    final deposit = v?.securityDepositPkr;
    if (deposit != null) depositController.text = deposit.toString();
    if (!returnEdited && selectedPackage != null) {
      _returnTime = ManualBookingPackageSelector.returnTimeFor(pickup: _pickupTime, package: selectedPackage!);
    }
  }

  void onPickupChanged(DateTime next) {
    _pickupTime = next;
    if (!returnEdited && selectedPackage != null) {
      _returnTime = ManualBookingPackageSelector.returnTimeFor(pickup: _pickupTime, package: selectedPackage!);
    }
  }

  void onReturnChanged(DateTime next) {
    _returnTime = next;
    returnEdited = true;
  }

  void onPackageChanged(VehiclePackageEntity? p) {
    selectedPackage = p;
    if (!returnEdited && p != null) {
      _returnTime = ManualBookingPackageSelector.returnTimeFor(pickup: _pickupTime, package: p);
    }
  }

  /// Step 2 gate: null when the car + schedule are valid.
  String? validateStep2(AppLocalizations l10n) {
    if (selectedVehicle == null || selectedPackage == null) {
      return l10n.manualBookingSelectVehicle;
    }
    if (isOutOfCity && selectedVehicle?.outCityMode == 'fixedRoute' && selectedRoute == null) {
      return l10n.outCityFixedRouteNone;
    }
    if (!_returnTime.isAfter(_pickupTime)) {
      return l10n.manualBookingReturnAfterPickup;
    }
    if (carFree == false) return l10n.manualBookingCarBusy;
    return null;
  }

  /// Step 3 gate: inline field errors land on [discountError] /
  /// [advanceError]; the returned string (if any) is the snackbar
  /// error — the "collect in full or add to dues" rule.
  String? validatePayment(AppLocalizations l10n) {
    final discountText = discountController.text.trim();
    final discountParsed = int.tryParse(discountText);
    final advanceText = advanceController.text.trim();
    final advanceParsed = int.tryParse(advanceText);
    discountError = null;
    advanceError = null;
    if ((discountText.isNotEmpty && discountParsed == null) || (discountParsed != null && discountParsed < 0)) {
      discountError = l10n.manualBookingAmountInvalid;
    } else if (discount > rentAmount + driverAmount) {
      discountError = l10n.manualBookingDiscountTooHigh;
    }
    if ((advanceText.isNotEmpty && advanceParsed == null) || (advanceParsed != null && advanceParsed < 0)) {
      advanceError = l10n.manualBookingAmountInvalid;
    }
    if (discountError != null || advanceError != null) return null;
    if (!addToDues && remaining > 0) return l10n.manualBookingCollectFull;
    return null;
  }

  /// Prefill the advance with the required advance when the owner
  /// has not typed one yet (first entry into step 3).
  void prefillAdvanceIfEmpty() {
    if (advanceController.text.trim().isEmpty) {
      advanceController.text = advanceRequired.toString();
    }
  }
}
