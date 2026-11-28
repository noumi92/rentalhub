import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/connectivity_service.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../core/widgets/minimal_app_bar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../../services/handover_wizard_finalize.dart';
import '../../services/handover_wizard_loader.dart';
import '../../widgets/handover_wizard/handover_wizard_error_message.dart';
import '../../widgets/handover_wizard/handover_wizard_load_error_banner.dart';
import '../../widgets/handover_wizard/handover_wizard_nav_bar.dart';
import '../../widgets/handover_wizard/handover_wizard_step_agreement.dart';
import '../../widgets/handover_wizard/handover_wizard_step_checklist.dart';
import '../../widgets/handover_wizard/handover_wizard_step_payment.dart';
import '../../widgets/handover_wizard/handover_wizard_step_photos.dart';
import '../../widgets/handover_wizard/handover_wizard_step_verify.dart';
import '../../widgets/handover_wizard/handover_wizard_stepper.dart';

/// Item 9 (O26–O30): the 5-step handover wizard — Verify →
/// Payment → Checklist → Photos → Agreement. Assembly, not a
/// rebuild: each step reuses the existing section widgets (QR
/// scanner, balance section, fuel/odometer, checklist, photo
/// picker, damage schematic, signature pads, [HandoverCubit] +
/// offline-first sync, the PDF generator), and the draft lives in
/// [HandoverWizardCubit].
///
/// The old single view ([OwnerHandoverSignatureView]) stays in
/// the tree; the `/owner/handover/:id` route now lands here, with
/// `?step=0..4` picking the starting step.
class OwnerHandoverWizardView extends StatelessWidget {
  final BookingEntity booking;
  final int initialStep;
  final VoidCallback? onBack;

  const OwnerHandoverWizardView({
    super.key,
    required this.booking,
    this.initialStep = 0,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isWalkIn = booking.origin == 'walk_in';
    final effectiveStep = isWalkIn && initialStep == 0 ? 1 : initialStep;
    return BlocProvider(
      create: (_) => HandoverWizardCubit(
        bookingId: booking.bookingId,
        initialStep: effectiveStep,
        faceCheckConfirmed: isWalkIn,
      ),
      child: _HandoverWizardBody(booking: booking, onBack: onBack),
    );
  }
}

class _HandoverWizardBody extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const _HandoverWizardBody({required this.booking, this.onBack});

  @override
  State<_HandoverWizardBody> createState() => _HandoverWizardBodyState();
}

class _HandoverWizardBodyState extends State<_HandoverWizardBody> {
  bool _isLoading = true;
  String? _loadError;
  String _shopName = '';
  int _securityDeposit = 0;
  String? _vehiclePlate;
  String? _vehicleColour;
  String? _vehicleFuel;
  String? _kycPhotoUrl;

  @override
  void initState() {
    super.initState();
    _shopName = widget.booking.shopName ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    String? error;
    try {
      final loaded = await HandoverWizardLoader.load(
        booking: widget.booking,
        wizard: context.read<HandoverWizardCubit>(),
      );
      if (!mounted) return;
      setState(() {
        _shopName = loaded.shopName;
        _securityDeposit = loaded.securityDeposit;
        _vehiclePlate = loaded.vehiclePlate;
        _vehicleColour = loaded.vehicleColour;
        _vehicleFuel = loaded.vehicleFuel;
        _kycPhotoUrl = loaded.kycPhotoUrl;
      });
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;
    // The name is printed on the agreement, so a load that ends
    // with no name must surface as a load error with a retry here
    // — not only at finalize on the last step, after the owner has
    // filled the whole wizard.
    error ??= _shopName.isEmpty
        ? AppLocalizations.of(context)!.handoverShopNameRequired
        : null;
    setState(() {
      _loadError = error;
      _isLoading = false;
    });
  }

  int get _balanceDue =>
      (widget.booking.totalAmount - widget.booking.advancePaid)
          .clamp(0, 1 << 30);

  Future<void> _finalize() async {
    final l10n = AppLocalizations.of(context)!;
    final wizard = context.read<HandoverWizardCubit>();
    if (!wizard.signaturesReady) {
      AppFeedback.showError(context, l10n.handoverSignRequired);
      return;
    }
    if (_shopName.isEmpty) {
      AppFeedback.showError(context, l10n.handoverShopNameRequired);
      return;
    }
    wizard.setFinalizing(true);
    try {
      final result = await HandoverWizardFinalize.run(
        booking: widget.booking,
        shopName: _shopName,
        securityDeposit: wizard.state.effectiveDeposit(_securityDeposit),
        vehiclePlate: _vehiclePlate,
        vehicleColour: _vehicleColour,
        vehicleFuel: _vehicleFuel,
        wizard: wizard,
        customerNameFallback: l10n.requestsCustomerFallback,
        vehicleFallback: l10n.summaryVehicle,
        isOnline: sl.isRegistered<ConnectivityService>()
            ? sl<ConnectivityService>().isOnline
            : true,
      );
      if (!mounted) return;
      wizard.markCompleted(result.entity, result.pdfBytes);
      AppFeedback.showSuccess(context, l10n.handoverCertified);
    } catch (e) {
      debugPrint('Handover finalize failed: $e');
      if (!mounted) return;
      wizard.setFinalizing(false);
      AppFeedback.showError(context, l10n.walkInHandoverFailedGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<HandoverWizardCubit, HandoverWizardState>(
      listenWhen: (prev, next) =>
          (prev.errorTick != next.errorTick || prev.error != next.error) &&
          next.error != null,
      listener: (context, state) =>
          AppFeedback.showError(context, handoverWizardErrorMessage(l10n, state.error!)),
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              MinimalAppBar(
                title: l10n.handoverWizardTitle,
                subtitle:
                    '#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? l10n.summaryVehicle}',
                onBack: widget.onBack,
              ),
              BlocBuilder<HandoverWizardCubit, HandoverWizardState>(
                builder: (context, state) =>
                    HandoverWizardStepperBar(currentStep: state.step + 1),
              ),
              // A failed shop/vehicle load shows a visible inline
              // error with a retry instead of silently certifying
              // against the 'RentalHub' / Rs. 0 fallbacks (audit C4).
              if (_loadError != null)
                HandoverWizardLoadErrorBanner(
                  error: _loadError!,
                  onRetry: _load,
                ),
              if (_isLoading)
                const Expanded(child: AppLoadingState())
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: BlocBuilder<HandoverWizardCubit,
                        HandoverWizardState>(
                      builder: (context, state) {
                        switch (state.step) {
                          case 0:
                            return HandoverWizardStepVerify(
                                booking: widget.booking,
                                kycPhotoUrl: _kycPhotoUrl);
                          case 1:
                            return HandoverWizardStepPayment(
                                booking: widget.booking,
                                securityDeposit: _securityDeposit);
                          case 2:
                            return const HandoverWizardStepChecklist();
                          case 3:
                            return HandoverWizardStepPhotos(
                                booking: widget.booking);
                          default:
                            return HandoverWizardStepAgreement(
                                booking: widget.booking,
                                shopName: _shopName,
                                securityDeposit:
                                    state.effectiveDeposit(_securityDeposit));
                        }
                      },
                    ),
                  ),
                ),
              HandoverWizardNavBar(
                balanceDue: _balanceDue,
                securityDeposit: _securityDeposit,
                onFinalize: _finalize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
