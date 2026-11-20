import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../../services/contract_pdf_actions.dart';

/// Item 9 (O30): the completion card the agreement step becomes
/// after finalize — trip started time, return due, Share Agreement
/// PDF, and onward to the agreement wizard. Extracted so the step
/// stays under the 250-line cap.
class HandoverWizardCompletedCard extends StatelessWidget {
  final BookingEntity booking;
  final HandoverWizardState state;

  const HandoverWizardCompletedCard({
    super.key,
    required this.booking,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startedAt = state.completed!.tripStartAt ?? DateTime.now();
    final started = TimeOfDay.fromDateTime(startedAt).format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.handoverWizardHandedOver,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              if (state.completed!.receiptId != null)
                Text(
                  l10n.handoverWizardReceiptId(state.completed!.receiptId!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => ContractPdfActions.sharePdf(
            context: context,
            bookingId: booking.bookingId,
            bytes: state.completedPdfBytes,
          ),
          icon: const Icon(Icons.share_rounded),
          label: Text(l10n.handoverWizardSharePdf),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push(RouteNames.ownerAgreementWizard
              .replaceFirst(':id', booking.bookingId)),
          icon: const Icon(Icons.description_rounded),
          label: Text(l10n.rentalStartedViewAgreement),
        ),
      ],
    );
  }
}
