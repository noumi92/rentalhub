import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/manual_booking_car_step.dart';
import '../widgets/manual_booking_customer_step.dart';
import '../widgets/manual_booking_draft.dart';
import '../widgets/manual_booking_package_selector.dart';
import '../widgets/manual_booking_payment_step.dart';
import 'owner_manual_booking_confirm_view.dart';

/// Walk-in booking wizard (O21–O24), 4 steps: 1 Customer → 2 Car
/// → 3 Payment → 4 Summary. This view owns steps 1–3 and the
/// vehicle load; the draft ([ManualBookingDraft]) owns the money
/// math and validation. Step 4 is [OwnerManualBookingConfirmView]
/// (its own route, so the draft travels via `state.extra` like the
/// CNIC-review route).
///
/// Step 1 picks a REGISTERED customer — no new customer is ever
/// typed here; "+ Add New Customer" opens the full Add Customer
/// (KYC) flow and the customer-added screen's Start Booking action
/// returns here with the new customer prefilled. Step 2 is the car
/// radio list + packages + schedule (pickup defaults to Now).
/// Step 3 is payment + deposit.
class OwnerManualBookingView extends StatefulWidget {
  final String? prefilledCnic;
  final String? prefilledName;
  final String? prefilledPhone;
  final String? prefilledVehicleId;
  final DateTime? prefilledPickupTime;
  final DateTime? prefilledReturnTime;
  final String? prefilledTripType;
  final VoidCallback? onBack;

  const OwnerManualBookingView({
    super.key,
    this.prefilledCnic,
    this.prefilledName,
    this.prefilledPhone,
    this.prefilledVehicleId,
    this.prefilledPickupTime,
    this.prefilledReturnTime,
    this.prefilledTripType,
    this.onBack,
  });

  @override
  State<OwnerManualBookingView> createState() => _OwnerManualBookingViewState();
}

class _OwnerManualBookingViewState extends State<OwnerManualBookingView> {
  int _step = 1;
  late final ManualBookingDraft _draft;
  List<VehicleEntity> _vehicles = [];
  bool _isLoadingVehicles = true;
  String? _vehiclesError;

  @override
  void initState() {
    super.initState();
    _draft = ManualBookingDraft(
      pickupTime: widget.prefilledPickupTime,
      returnTime: widget.prefilledReturnTime,
      isOutOfCity: widget.prefilledTripType == 'out_of_city',
    )..returnEdited = widget.prefilledReturnTime != null;
    _loadVehicles();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
      _vehiclesError = null;
    });
    try {
      final cars = await sl<FleetRemoteDataSource>().getShopVehicles(currentShopId());
      if (mounted) {
        setState(() {
          _vehicles = cars;
          VehicleEntity? prefilled;
          for (final v in cars) {
            if (v.vehicleId == widget.prefilledVehicleId) prefilled = v;
          }
          _draft.selectVehicle(prefilled ?? (cars.isNotEmpty ? cars.first : null));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _vehiclesError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  void _addNewCustomer(String query) {
    final params = <String, String>{};
    if (query.replaceAll(RegExp(r'\D'), '').length >= 5) params['cnic'] = query.trim();
    context.push(Uri(path: RouteNames.ownerAddCustomer, queryParameters: params.isEmpty ? null : params).toString());
  }

  void _next() {
    final l10n = AppLocalizations.of(context)!;
    if (_step == 1) {
      if (_draft.selectedCustomer == null) {
        AppFeedback.showError(context, l10n.manualBookingSelectCustomer);
        return;
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      final error = _draft.validateStep2(l10n);
      if (error != null) {
        AppFeedback.showError(context, error);
        return;
      }
      _draft.prefillAdvanceIfEmpty();
      setState(() => _step = 3);
      return;
    }
    final error = _draft.validatePayment(l10n);
    if (_draft.discountError != null || _draft.advanceError != null) {
      setState(() {});
      return;
    }
    if (error != null) {
      AppFeedback.showError(context, error);
      return;
    }
    final customer = _draft.selectedCustomer!;
    OwnerManualBookingConfirmView.open(
      context,
      customerId: customer.customerId,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerCnic: customer.cnic ?? '',
      guarantor: _draft.guarantor,
      vehicle: _draft.selectedVehicle!,
      package: _draft.selectedPackage!,
      isWithDriver: _draft.isWithDriver,
      isOutOfCity: _draft.isOutOfCity,
      pickupTime: _draft.pickupTime,
      returnTime: _draft.returnTime,
      fixedRoute: _draft.selectedRoute,
      rentAmount: _draft.rentAmount,
      driverAmount: _draft.driverAmount,
      discountAmountPkr: _draft.discount > 0 ? _draft.discount.toDouble() : null,
      advanceReceived: _draft.advanceReceived,
      paymentMethod: _draft.paymentMethod,
      depositAmountPkr: _draft.depositAmount,
      depositMethod: _draft.depositMethod,
      addRemainingToDues: _draft.addToDues,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.manualBookingTitle, subtitle: l10n.manualBookingSubtitle, onBack: widget.onBack),
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: ManualBookingStepIndicator(currentStep: _step)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: _stepBody(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (_step > 1)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l10n.commonGoBack),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    ),
                  if (_step > 1) const SizedBox(width: 10),
                  Expanded(
                    child: DebouncedButton(text: l10n.manualBookingNext, icon: Icons.arrow_forward_rounded, onPressed: _next),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 1:
        return ManualBookingCustomerStep(
          selected: _draft.selectedCustomer, onSelected: (c) => setState(() => _draft.selectedCustomer = c),
          onAddNewCustomer: _addNewCustomer, onGuarantorChanged: (g) => setState(() => _draft.guarantor = g),
          prefilledCnic: widget.prefilledCnic, prefilledName: widget.prefilledName, prefilledPhone: widget.prefilledPhone,
        );
      case 2:
        return ManualBookingCarStep(
          isLoadingVehicles: _isLoadingVehicles, vehiclesError: _vehiclesError, onRetryLoad: _loadVehicles, vehicles: _vehicles,
          selectedVehicle: _draft.selectedVehicle, onVehicleChanged: (v) => setState(() => _draft.selectVehicle(v)),
          selectedPackage: _draft.selectedPackage, onPackageChanged: (p) => setState(() => _draft.onPackageChanged(p)),
          isWithDriver: _draft.isWithDriver, onDriverModeChanged: (v) => setState(() => _draft.isWithDriver = v),
          isOutOfCity: _draft.isOutOfCity, pickupTime: _draft.pickupTime, returnTime: _draft.returnTime,
          onPickupChanged: (next) => setState(() => _draft.onPickupChanged(next)),
          onReturnChanged: (next) => setState(() => _draft.onReturnChanged(next)),
          onTripTypeChanged: (v) => setState(() => _draft.isOutOfCity = v),
          selectedFixedRoute: _draft.selectedRoute, onFixedRouteChanged: (r) => setState(() => _draft.selectedRoute = r),
          onAvailabilityChanged: (free) => _draft.carFree = free,
        );
      default:
        return ManualBookingPaymentStep(
          rentAmount: _draft.rentAmount, driverAmount: _draft.driverAmount,
          discountController: _draft.discountController, discountError: _draft.discountError, onDiscountChanged: () => setState(() {}),
          advanceController: _draft.advanceController, advanceError: _draft.advanceError, onAdvanceChanged: () => setState(() {}),
          advanceRequired: _draft.advanceRequired, paymentMethod: _draft.paymentMethod,
          onPaymentMethodChanged: (m) => setState(() => _draft.paymentMethod = m),
          depositController: _draft.depositController, depositReceived: _draft.depositReceived,
          onDepositReceivedChanged: (v) => setState(() => _draft.depositReceived = v),
          depositMethod: _draft.depositMethod, onDepositMethodChanged: (m) => setState(() => _draft.depositMethod = m),
          remainingDues: _draft.remaining, addToDues: _draft.addToDues, onAddToDuesChanged: (v) => setState(() => _draft.addToDues = v),
        );
    }
  }
}
