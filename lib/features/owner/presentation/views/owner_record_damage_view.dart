import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/vehicle_damage_schematic_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../services/handover_photo_upload_service.dart';

/// Audit item 6 (O27): Record Damage — photo upload, description,
/// Repair Cost, "Deduct from Deposit" toggle, Save. The damage
/// schematic (previously unused anywhere) pins the damage zones;
/// the report is saved to `return_damage_reports`, scoped by
/// booking id, and the return settlement folds in every report
/// marked "deduct from deposit".
class OwnerRecordDamageView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;

  const OwnerRecordDamageView({
    super.key,
    required this.booking,
    this.onBack,
  });

  @override
  State<OwnerRecordDamageView> createState() => _OwnerRecordDamageViewState();
}

class _OwnerRecordDamageViewState extends State<OwnerRecordDamageView> {
  final _descriptionController = TextEditingController();
  final _repairCostController = TextEditingController();
  XFile? _photo;
  String? _photoUrl;
  List<DamagePin> _pins = const [];
  bool _deductFromDeposit = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _repairCostController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    await MediaPickerHelper.showMediaSourceSheet(
      context: context,
      onImageSelected: (XFile? file) async {
        if (file == null) return;
        setState(() => _photo = file);
        final url = await HandoverPhotoUploadService.uploadHandoverPhoto(
          shopId: widget.booking.shopId,
          bookingId: widget.booking.bookingId,
          photo: file,
          targetField: 'photoUrl',
          targetCollection: 'return_damage_reports',
        );
        if (mounted && url != null) setState(() => _photoUrl = url);
      },
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      AppFeedback.showError(context, l10n.damageDescriptionRequired);
      return;
    }
    final repairCost =
        (int.tryParse(_repairCostController.text.trim()) ?? 0).clamp(0, 1 << 30);
    setState(() => _isSaving = true);
    try {
      final id = await ReturnRecordsService().saveDamageReport(
        bookingId: widget.booking.bookingId,
        shopId: widget.booking.shopId,
        photoUrl: _photoUrl,
        description: _pins.isEmpty
            ? description
            : '$description (${_pins.map((p) => '${p.zone}: ${p.type}').join(', ')})',
        repairCost: repairCost,
        deductFromDeposit: _deductFromDeposit,
      );
      if (!mounted) return;
      if (id == null) {
        AppFeedback.showError(context, l10n.damageSaveFailed);
        return;
      }
      AppFeedback.showSuccess(context, l10n.damageSaved);
      widget.onBack?.call();
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            MinimalAppBar(
              title: l10n.damageTitle,
              subtitle: '#${widget.booking.bookingId} • ${widget.booking.vehicleName ?? l10n.summaryVehicle}',
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleDamageSchematicWidget(
                      initialPins: const [],
                      onPinsChanged: (pins) => setState(() => _pins = pins),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _photo == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_rounded),
                                  const SizedBox(height: 6),
                                  Text(l10n.damageAddPhoto,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              )
                            : Image.file(File(_photo!.path), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.damageDescriptionLabel,
                        hintText: l10n.damageDescriptionHint,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _repairCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.damageRepairCostLabel,
                        hintText: l10n.damageRepairCostHint,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.damageDeductFromDeposit,
                          style: Theme.of(context).textTheme.bodyMedium),
                      value: _deductFromDeposit,
                      onChanged: (v) => setState(() => _deductFromDeposit = v),
                    ),
                    const SizedBox(height: 16),
                    DebouncedButton(
                      text: l10n.damageSave,
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _save,
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
