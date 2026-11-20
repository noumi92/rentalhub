import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/vehicle_damage_schematic_widget.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../operations/exterior_photo_picker.dart';

/// Item 9 (O29): Car Photos at Handover — six slots (Front / Back
/// / Left / Right / Interior / Dashboard, each with the time it
/// was taken) plus the tap-to-mark damage diagram, wired into
/// handover for the first time (it used to live only on the
/// return side). The pins persist on the handover record.
class HandoverWizardStepPhotos extends StatelessWidget {
  final BookingEntity booking;

  const HandoverWizardStepPhotos({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wizard = context.watch<HandoverWizardCubit>();
    final state = wizard.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExteriorPhotoPicker(
          bookingId: booking.bookingId,
          shopId: booking.shopId,
          photos: state.photos,
          onChanged: wizard.setPhotos,
          includeInterior: true,
          takenAt: state.photoTakenAt,
          onTakenAtChanged: wizard.setPhotoTakenAt,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.handoverWizardDamageDiagram,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        VehicleDamageSchematicWidget(
          // The schematic's built-in default pins are demo data —
          // the wizard always passes the draft's (initially empty)
          // pins instead.
          initialPins: state.damagePins,
          onPinsChanged: wizard.setDamagePins,
        ),
      ],
    );
  }
}
