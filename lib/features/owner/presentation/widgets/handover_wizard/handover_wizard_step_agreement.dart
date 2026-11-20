import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import 'handover_wizard_completed_card.dart';
import 'handover_wizard_signature_block.dart';

/// Item 9 (O30): Agreement & Handover — the auto-generated
/// agreement summary, the signatures, and the handover itself.
///
/// Signatures are SAVED, not re-signed: the customer's KYC
/// signature (spec O21: "Saved signature auto-applied") and the
/// owner's on-file signature are shown as "on file" with the
/// image when they exist; the pad appears only when there is no
/// saved signature, or when the owner taps "Sign fresh instead".
/// Finalize still requires a customer + an owner signature (saved
/// or fresh). The guarantor is NOT signed here — it moves to the
/// O47 wizard step, so O30 shows it as pending.
///
/// After finalize the step becomes the completion card: trip
/// started time, return due, Share Agreement PDF, and onward to
/// the agreement wizard.
class HandoverWizardStepAgreement extends StatefulWidget {
  final BookingEntity booking;
  final String shopName;
  final int securityDeposit;

  const HandoverWizardStepAgreement({
    super.key,
    required this.booking,
    required this.shopName,
    required this.securityDeposit,
  });

  @override
  State<HandoverWizardStepAgreement> createState() =>
      _HandoverWizardStepAgreementState();
}

class _HandoverWizardStepAgreementState
    extends State<HandoverWizardStepAgreement> {
  // Saved in initState: reading the cubit in dispose() is unsafe
  // (the element is deactivated by then).
  late final HandoverWizardCubit _wizard;

  @override
  void initState() {
    super.initState();
    _wizard = context.read<HandoverWizardCubit>();
    _wizard.customerSigController.addListener(_onPadDrawn);
    _wizard.ownerSigController.addListener(_onPadDrawn);
  }

  void _onPadDrawn() {
    if (_wizard.customerSigController.isNotEmpty ||
        _wizard.ownerSigController.isNotEmpty) {
      _wizard.markCustomerSigDrawn();
    }
  }

  @override
  void dispose() {
    _wizard.customerSigController.removeListener(_onPadDrawn);
    _wizard.ownerSigController.removeListener(_onPadDrawn);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizard = context.watch<HandoverWizardCubit>();
    final state = wizard.state;
    if (state.completed != null) {
      return HandoverWizardCompletedCard(
          booking: widget.booking, state: state);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _summaryCard(context, l10n),
        const SizedBox(height: 16),
        HandoverWizardSignatureBlock(
          title: l10n.handoverCustomerSignature,
          savedUrl: state.customerSavedSignatureUrl,
          savedPng: state.customerSavedSignaturePng,
          useSaved: state.useCustomerSaved,
          onToggleUseSaved: wizard.setUseCustomerSaved,
          controller: wizard.customerSigController,
        ),
        const SizedBox(height: 16),
        HandoverWizardSignatureBlock(
          title: l10n.handoverHostSignature,
          savedUrl: state.ownerSavedSignatureUrl,
          savedPng: state.ownerSavedSignaturePng,
          useSaved: state.useOwnerSaved,
          onToggleUseSaved: wizard.setUseOwnerSaved,
          controller: wizard.ownerSigController,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Row(
            children: [
              Icon(Icons.pending_actions_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.handoverWizardGuarantorPending,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, AppLocalizations l10n) {
    final booking = widget.booking;
    final now = DateTime.now();
    final started = TimeOfDay.fromDateTime(now).format(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.vehicleName ?? l10n.summaryVehicle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '#${booking.bookingId} • ${widget.shopName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(l10n.handoverWizardTripStarted(started),
              style: Theme.of(context).textTheme.bodyMedium),
          Text(
            l10n.rentalStartedReturnDue(
              MaterialLocalizations.of(context)
                  .formatShortDate(booking.returnTime),
              MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay.fromDateTime(booking.returnTime)),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
