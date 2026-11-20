import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';

/// Item 9 (O26): Scan QR & Verify — the matched-booking card plus
/// the manual face check. The QR scan itself lives in
/// [OwnerQrScanView] (which routes here once a booking resolves);
/// this step shows what the scan matched and gates "Continue" on
/// the owner confirming the customer against the KYC profile photo.
///
/// No face-match SDK, no match percentage: the spec's "94%" is a
/// mockup number. Only a confirmed flag + checked-at timestamp are
/// recorded (see [HandoverWizardCubit.setFaceChecked]).
class HandoverWizardStepVerify extends StatelessWidget {
  final BookingEntity booking;

  /// The customer's KYC profile photo URL, loaded by the shell —
  /// null when the customer has no photo on file.
  final String? kycPhotoUrl;

  const HandoverWizardStepVerify({
    super.key,
    required this.booking,
    this.kycPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizard = context.watch<HandoverWizardCubit>();
    final state = wizard.state;
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
                  Icon(Icons.verified_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.handoverWizardBookingMatched,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              _row(context, booking.vehicleName ?? l10n.summaryVehicle,
                  '#${booking.bookingId}'),
              const SizedBox(height: 6),
              _row(context, booking.customerName ?? l10n.requestsCustomerFallback,
                  booking.customerCnic ?? ''),
              const SizedBox(height: 6),
              _row(context, booking.customerPhone ?? '',
                  l10n.amountRs(formatRs(booking.totalAmount))),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
              Text(l10n.handoverWizardFaceTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(l10n.handoverWizardFaceHint,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kycPhotoUrl != null && kycPhotoUrl!.isNotEmpty
                        ? Image.network(
                            kycPhotoUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _photoFallback(context),
                          )
                        : _photoFallback(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            booking.customerName ??
                                l10n.requestsCustomerFallback,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (booking.customerCnic != null)
                          Text(booking.customerCnic!,
                              style: Theme.of(context).textTheme.bodySmall),
                        if (kycPhotoUrl == null ||
                            kycPhotoUrl!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(l10n.handoverWizardFaceNoPhoto,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: state.faceCheckConfirmed
                    ? OutlinedButton.icon(
                        onPressed: () => wizard.setFaceChecked(false),
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Colors.green),
                        label: Text(l10n.handoverWizardFaceConfirmed),
                      )
                    : FilledButton.icon(
                        onPressed: () => wizard.setFaceChecked(true),
                        icon: const Icon(Icons.face_rounded),
                        label: Text(l10n.handoverWizardFaceConfirm),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoFallback(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.person_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _row(BuildContext context, String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
            child: Text(left,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Flexible(
            child: Text(right,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
