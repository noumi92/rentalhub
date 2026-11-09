import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/utils/package_pricing.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../services/walk_in_booking_service.dart';
import '../widgets/guarantor_picker.dart';
import '../widgets/manual_booking_fare_summary.dart';
import '../widgets/manual_booking_package_selector.dart';
import '../widgets/operations/booking_fare_breakdown.dart';

/// Audit §5 item 1 (O17 p.7): the confirm step the manual flow was
/// missing — fare summary (daily rate × days, total), the
/// advance/remaining split, and an "Advance received" amount field
/// prefilled with the package advance (0 allowed). Confirming creates
/// the booking: `paid` only when the received advance covers the
/// required advance, otherwise `approved` with the balance still due.
/// Then the Booking Confirmed screen opens.
///
/// Registrar: the confirmed screen lives at
/// `/owner/booking-confirmed/:id` (see audit_impl_manifest_worker_a.md).
class OwnerManualBookingConfirmView extends StatefulWidget {
  const OwnerManualBookingConfirmView({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.customerCnic,
    this.guarantor,
    required this.vehicle,
    required this.package,
    required this.isWithDriver,
    required this.isOutOfCity,
    required this.pickupTime,
    required this.returnTime,
    this.fixedRoute,
    this.onBack,
  });

  final String customerName;
  final String customerPhone;
  final String customerCnic;
  final GuarantorSelection? guarantor;
  final VehicleEntity vehicle;
  final VehiclePackageEntity package;
  final bool isWithDriver;
  final bool isOutOfCity;
  final DateTime pickupTime;
  final DateTime returnTime;
  /// 09b §2: the fixed route chosen for this out-of-city trip — its flat price is the booked total, and the route id + summary are stored on the booking (gap b).
  final FixedRouteEntity? fixedRoute;
  final VoidCallback? onBack;

  /// Opens the confirm step for a validated manual booking draft.
  static void open(
    BuildContext context, {
    required String customerName,
    required String customerPhone,
    required String customerCnic,
    GuarantorSelection? guarantor,
    required VehicleEntity vehicle,
    required VehiclePackageEntity package,
    required bool isWithDriver,
    required bool isOutOfCity,
    required DateTime pickupTime,
    required DateTime returnTime,
    FixedRouteEntity? fixedRoute,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OwnerManualBookingConfirmView(
              customerName: customerName,
              customerPhone: customerPhone,
              customerCnic: customerCnic,
              guarantor: guarantor,
              vehicle: vehicle,
              package: package,
              isWithDriver: isWithDriver,
              isOutOfCity: isOutOfCity,
              pickupTime: pickupTime,
              returnTime: returnTime,
              fixedRoute: fixedRoute,
            )));
  }

  @override
  State<OwnerManualBookingConfirmView> createState() =>
      _OwnerManualBookingConfirmViewState();
}

class _OwnerManualBookingConfirmViewState
    extends State<OwnerManualBookingConfirmView> {
  late final TextEditingController _advanceController;
  bool _isCreating = false;

  /// Nights away from the home city: days − 1 (a 1-day trip has
  /// 0 nights). Only out-of-city WITH-DRIVER trips stay over.
  int get _nights => nightStayNightsFor(widget.pickupTime, widget.returnTime);

  int get _nightStay => nightStayTotalFor(vehicle: widget.vehicle, isWithDriver: widget.isWithDriver, isOutOfCity: widget.isOutOfCity, pickup: widget.pickupTime, returnTime: widget.returnTime);

  /// The booked total: the package total PLUS the night stay, so
  /// the stored total matches the fare breakdown (daily × days +
  /// night stay). The step-2 selector total does not include the
  /// stay yet — it is folded into totalFor separately.
  int get _total => ManualBookingPackageSelector.totalFor(vehicle: widget.vehicle, package: widget.package, isWithDriver: widget.isWithDriver, isOutOfCity: widget.isOutOfCity, pickup: widget.pickupTime, returnTime: widget.returnTime, fixedRoute: widget.fixedRoute);

  int get _advanceRequired => PackagePricing.advanceFor(vehicle: widget.vehicle, total: _total);

  int get _advanceReceived {
    final parsed = int.tryParse(_advanceController.text.trim());
    return parsed == null ? 0 : parsed.clamp(0, _total);
  }

  @override
  void initState() {
    super.initState();
    _advanceController = TextEditingController();
    // Prefilled with the package advance; 0 is allowed (the booking
    // is then approved, not paid, with the full balance still due).
    _advanceController.text = _advanceRequired.toString();
    _advanceController.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _advanceController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCreating = true);
    try {
      final booking = await WalkInBookingService.createWalkInBooking(
        name: widget.customerName,
        phone: widget.customerPhone,
        cnic: widget.customerCnic,
        guarantor: widget.guarantor,
        vehicle: widget.vehicle,
        package: widget.package,
        isWithDriver: widget.isWithDriver,
        rentAmount: _total,
        advanceRequired: _advanceRequired,
        pickupTime: widget.pickupTime,
        returnTime: widget.returnTime,
        tripType: widget.isOutOfCity ? 'out_of_city' : 'in_city',
        fixedRoute: widget.fixedRoute,
        advanceReceived: _advanceReceived,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.manualBookingRegistered(booking.bookingId));
        context.pushReplacement('/owner/booking-confirmed/${booking.bookingId}');
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.manualBookingCreateFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.manualBookingConfirmTitle, onBack: widget.onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ManualBookingFareSummary(
                      vehicle: widget.vehicle,
                      package: widget.package,
                      isWithDriver: widget.isWithDriver,
                      isOutOfCity: widget.isOutOfCity,
                      pickupTime: widget.pickupTime,
                      returnTime: widget.returnTime,
                      customerName: widget.customerName,
                      advanceReceived: _advanceReceived,
                      fixedRoute: widget.fixedRoute,
                    ),
                    // Out-of-city extras: the night-stay component
                    // of the total above (totalFor folds it in),
                    // plus the tolls note.
                    if (widget.isOutOfCity) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_nightStay > 0)
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(l10n.bookingFareNightStay(_nights))), Text(l10n.amountRs(formatRs(_nightStay)), style: const TextStyle(fontWeight: FontWeight.w800))]),
                              Text(widget.vehicle.tollsPaidBy == 'included' ? l10n.bookingFareTollsIncluded : l10n.bookingFareTollsCustomer, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _advanceController,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: l10n.bookingCheckAdvance,
                        prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: _isCreating ? l10n.manualBookingCreating : l10n.manualBookingConfirmBooking,
                      icon: Icons.check_circle_rounded,
                      isLoading: _isCreating,
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
