import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';
import '../operations/fuel_odometer_input_widget.dart';
import '../operations/handover_checklist_section.dart';
import '../handover_damage_notes_editor.dart';

/// Item 9 (O28): Handover Checklist — odometer + the E–F fuel
/// slider, the documents / accessories / keys checklist with the
/// AC-working and all-lights-working condition checkboxes, and the
/// free-text damage notes. The odometer starts empty by design
/// (a prefilled number could be certified as real untouched).
class HandoverWizardStepChecklist extends StatefulWidget {
  const HandoverWizardStepChecklist({super.key});

  @override
  State<HandoverWizardStepChecklist> createState() =>
      _HandoverWizardStepChecklistState();
}

class _HandoverWizardStepChecklistState
    extends State<HandoverWizardStepChecklist> {
  late final TextEditingController _odometerController;

  @override
  void initState() {
    super.initState();
    final odometer =
        context.read<HandoverWizardCubit>().state.odometer;
    _odometerController = TextEditingController(
        text: odometer > 0 ? odometer.toString() : '');
  }

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wizard = context.watch<HandoverWizardCubit>();
    final state = wizard.state;
    if (_odometerController.text.isEmpty && state.odometer > 0) {
      _odometerController.text = state.odometer.toString();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FuelOdometerInputWidget(
          odometerController: _odometerController,
          selectedFuel: state.fuelLevel,
          onFuelSelected: wizard.setFuel,
        ),
        const SizedBox(height: 16),
        HandoverChecklistSection(
          documentsGiven: state.documentsGiven,
          accessories: state.accessories,
          keysHandedOver: state.keysHandedOver,
          onDocumentsChanged: wizard.setDocuments,
          onAccessoriesChanged: wizard.setAccessories,
          onKeysChanged: wizard.setKeysHandedOver,
          acWorking: state.acWorking,
          onAcWorkingChanged: wizard.setAcWorking,
          lightsWorking: state.lightsWorking,
          onLightsWorkingChanged: wizard.setLightsWorking,
        ),
        const SizedBox(height: 16),
        HandoverDamageNotesEditor(
          initialNotes: state.damageNotes,
          onChanged: wizard.setDamageNotes,
        ),
        // Keep the draft in sync while the owner types — the step
        // gate reads the cubit, not this controller.
        _OdometerSync(
          controller: _odometerController,
          onChanged: wizard.setOdometer,
        ),
      ],
    );
  }
}

/// Listens to the odometer field and pushes the parsed value into
/// the draft. A zero-height widget — no UI of its own.
class _OdometerSync extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  const _OdometerSync({required this.controller, required this.onChanged});

  @override
  State<_OdometerSync> createState() => _OdometerSyncState();
}

class _OdometerSyncState extends State<_OdometerSync> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  void _sync() {
    widget.onChanged(int.tryParse(widget.controller.text.trim()) ?? 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
