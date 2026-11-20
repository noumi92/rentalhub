import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../operations/handover_balance_section.dart';
import 'handover_receipt_sheet.dart';

/// Item 9 (O27): Collect Payment & Deposit — the advance row, the
/// balance due with its method chips + Received toggle, and the
/// per-vehicle deposit with its own method chips + Received toggle.
/// The receipt is generated for the booking as soon as the step
/// loads (id `RH-RCT-<bookingId>`) and can be viewed / shared on
/// WhatsApp from here.
class HandoverWizardStepPayment extends StatelessWidget {
  final BookingEntity booking;

  /// The vehicle's `securityDepositPkr` — never a hardcoded figure.
  final int securityDeposit;

  const HandoverWizardStepPayment({
    super.key,
    required this.booking,
    required this.securityDeposit,
  });

  int get _balanceDue =>
      (booking.totalAmount - booking.advancePaid).clamp(0, 1 << 30);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizard = context.watch<HandoverWizardCubit>();
    final state = wizard.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandoverBalanceSection(
          balanceDue: _balanceDue,
          securityDeposit: securityDeposit,
          selectedMethod: state.balanceMethod,
          onMethodChanged: wizard.setBalanceMethod,
          advancePaid: booking.advancePaid,
          depositMethod: state.depositMethod,
          onDepositMethodChanged: wizard.setDepositMethod,
          depositReceived: state.depositReceived,
          onDepositReceivedChanged: wizard.setDepositReceived,
          balanceReceived: state.balanceReceived,
          onBalanceReceivedChanged: wizard.setBalanceReceived,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => HandoverReceiptSheet(
              booking: booking,
              receiptId: state.receiptId,
              securityDeposit: securityDeposit,
              balanceDue: _balanceDue,
              balanceMethod: state.balanceMethod,
              depositMethod: state.depositMethod,
              balanceReceived: state.balanceReceived,
              depositReceived: state.depositReceived,
            ),
          ),
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(l10n.handoverWizardReceiptView),
        ),
      ],
    );
  }
}
