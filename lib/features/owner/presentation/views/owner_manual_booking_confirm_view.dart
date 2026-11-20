import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
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
import '../widgets/manual_booking_out_city_extras.dart';
import '../widgets/manual_booking_package_selector.dart';
import '../widgets/operations/booking_fare_breakdown.dart';
import 'owner_manual_booking_receipt_view.dart';

/// O24: step 4 of the walk-in wizard — Summary. The full money
/// picture (Rent / Driver / Discount / Total, advance received +
/// method, deposit, remaining dues) for a REGISTERED customer, then
/// "Confirm Booking" creates the booking (real RH-… number) and
/// lands on the receipt screen. The agreement note is honest: the
/// agreement is generated at handover using the saved signatures,
/// not here. No print/PDF receipt — the receipt screen shares via
/// WhatsApp instead.
class OwnerManualBookingConfirmView extends StatefulWidget {
  const OwnerManualBookingConfirmView({
    super.key,
    required this.customerId,
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
    required this.rentAmount,
    required this.driverAmount,
    this.discountAmountPkr,
    required this.advanceReceived,
    required this.paymentMethod,
    this.depositAmountPkr,
    required this.depositMethod,
    required this.addRemainingToDues,
    this.onBack,
  });

  /// The registered customer's real id (never a synthetic
  /// 'walkin-…' id — step 1 only selects registered customers).
  final String customerId;
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
  final FixedRouteEntity? fixedRoute;

  /// Step 3 money, computed by the wizard.
  final int rentAmount;
  final int driverAmount;
  final double? discountAmountPkr;
  final int advanceReceived;
  final String paymentMethod;
  final double? depositAmountPkr;
  final String depositMethod;
  final bool addRemainingToDues;
  final VoidCallback? onBack;

  /// Opens step 4 for a validated manual booking draft, routed
  /// through go_router (the draft travels via `state.extra`, same
  /// pattern as the CNIC-review route).
  static void open(
    BuildContext context, {
    required String customerId,
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
    required int rentAmount,
    required int driverAmount,
    double? discountAmountPkr,
    required int advanceReceived,
    required String paymentMethod,
    double? depositAmountPkr,
    required String depositMethod,
    required bool addRemainingToDues,
  }) {
    context.push(RouteNames.ownerManualBookingConfirm, extra: <String, dynamic>{
      'customerId': customerId, 'customerName': customerName, 'customerPhone': customerPhone, 'customerCnic': customerCnic, 'guarantor': guarantor,
      'vehicle': vehicle, 'package': package, 'isWithDriver': isWithDriver, 'isOutOfCity': isOutOfCity,
      'pickupTime': pickupTime, 'returnTime': returnTime, 'fixedRoute': fixedRoute,
      'rentAmount': rentAmount, 'driverAmount': driverAmount, 'discountAmountPkr': discountAmountPkr,
      'advanceReceived': advanceReceived, 'paymentMethod': paymentMethod,
      'depositAmountPkr': depositAmountPkr, 'depositMethod': depositMethod, 'addRemainingToDues': addRemainingToDues,
    });
  }

  @override
  State<OwnerManualBookingConfirmView> createState() =>
      _OwnerManualBookingConfirmViewState();
}

class _OwnerManualBookingConfirmViewState
    extends State<OwnerManualBookingConfirmView> {
  bool _isCreating = false;

  int get _discount => (widget.discountAmountPkr ?? 0).round();
  int get _total => (widget.rentAmount + widget.driverAmount - _discount).clamp(0, 1 << 30);
  int get _remaining => (_total - widget.advanceReceived).clamp(0, 1 << 30);
  int get _advanceRequired => PackagePricing.advanceFor(vehicle: widget.vehicle, total: _total);
  int get _nights => nightStayNightsFor(widget.pickupTime, widget.returnTime);
  int get _nightStay => nightStayTotalFor(vehicle: widget.vehicle, isWithDriver: widget.isWithDriver, isOutOfCity: widget.isOutOfCity, pickup: widget.pickupTime, returnTime: widget.returnTime);

  String _methodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'jazzcash':
        return l10n.returnPaymentJazzCash;
      case 'easypaisa':
        return l10n.returnPaymentEasyPaisa;
      case 'bank_transfer':
        return l10n.returnPaymentBankTransfer;
      default:
        return l10n.returnPaymentCash;
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.addRemainingToDues && _remaining > 0) {
      AppFeedback.showError(context, l10n.manualBookingCollectFull);
      return;
    }
    setState(() => _isCreating = true);
    try {
      final booking = await WalkInBookingService.createWalkInBooking(
        name: widget.customerName, phone: widget.customerPhone, cnic: widget.customerCnic, guarantor: widget.guarantor,
        vehicle: widget.vehicle, package: widget.package, isWithDriver: widget.isWithDriver, rentAmount: _total,
        advanceRequired: _advanceRequired, pickupTime: widget.pickupTime, returnTime: widget.returnTime,
        tripType: widget.isOutOfCity ? 'out_of_city' : 'in_city', fixedRoute: widget.fixedRoute, advanceReceived: widget.advanceReceived,
        customerId: widget.customerId, depositAmountPkr: widget.depositAmountPkr, discountAmountPkr: widget.discountAmountPkr,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.manualBookingRegistered(booking.bookingId));
      if (mounted) {
        OwnerManualBookingReceiptView.open(context, booking: booking, paymentMethod: widget.paymentMethod,
            rentAmount: widget.rentAmount, driverAmount: widget.driverAmount, depositMethod: widget.depositMethod);
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
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.manualBookingSummaryTitle, onBack: widget.onBack),
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: ManualBookingStepIndicator(currentStep: 4)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(children: [
                            _row(context, l10n.requestsCustomerFallback, widget.customerName),
                            _row(context, l10n.summaryVehicle, '${widget.vehicle.make} ${widget.vehicle.model}'),
                            _row(context, l10n.packageLabel, widget.isOutOfCity ? '${widget.package.label} • ${l10n.outOfCityHyphen}' : '${widget.package.label} • ${l10n.inCityHyphen}'),
                            if (widget.isOutOfCity && widget.fixedRoute != null)
                              _row(context, l10n.outCityFixedRouteLabel, widget.fixedRoute!.displayName),
                            _row(context, l10n.bookingFarePickup, dateFormat.format(widget.pickupTime)),
                            _row(context, l10n.bookingFareReturn, dateFormat.format(widget.returnTime)),
                            const Divider(height: 20),
                            _moneyRow(context, l10n, l10n.manualBookingRentLine, widget.rentAmount),
                            _moneyRow(context, l10n, l10n.manualBookingDriverLine, widget.driverAmount),
                            _moneyRow(context, l10n, l10n.manualBookingDiscountLine, -_discount),
                            const Divider(height: 20),
                            _moneyRow(context, l10n, l10n.bookingFareTotal, _total, bold: true),
                            _row(context, l10n.bookingCheckAdvance, '${l10n.amountRs(formatRs(widget.advanceReceived))} (${_methodLabel(l10n, widget.paymentMethod)})'),
                            _row(context, l10n.manualBookingDepositReceived, widget.depositAmountPkr == null ? l10n.handoverBalanceNotYet : '${l10n.amountRs(formatRs(widget.depositAmountPkr!))} (${_methodLabel(l10n, widget.depositMethod)})'),
                            _row(context, l10n.manualBookingRemainingDues, l10n.amountRs(formatRs(_remaining)), bold: true),
                        ]),
                      ),
                    ),
                    if (widget.isOutOfCity) ...[
                      const SizedBox(height: 12),
                      ManualBookingOutCityExtras(nights: _nights, nightStay: _nightStay, tollsIncluded: widget.vehicle.tollsPaidBy == 'included'),
                    ],
                    const SizedBox(height: 12),
                    Text(l10n.manualBookingAgreementNote, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: _isCreating ? l10n.manualBookingCreating : l10n.manualBookingConfirmBooking,
                      icon: Icons.check_circle_rounded, isLoading: _isCreating, onPressed: _confirm,
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

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w500 : FontWeight.w400))),
        ]),
      );

  Widget _moneyRow(BuildContext context, AppLocalizations l10n, String label, int amount, {bool bold = false}) =>
      _row(context, label, '${amount < 0 ? '− ' : ''}${l10n.amountRs(formatRs(amount.abs()))}', bold: bold);
}
