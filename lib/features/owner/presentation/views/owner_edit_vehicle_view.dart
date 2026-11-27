import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/media_picker_helper.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../fleet/domain/usecases/update_vehicle_usecase.dart';
import '../constants/owner_vehicle_constants.dart';
import '../services/vehicle_photo_upload_service.dart';
import '../widgets/add_vehicle/add_vehicle_step_content.dart';

/// The simple car-details edit: ONE flat form, no stepper, no wizard.
/// Edits the car's identity (specs, front photo, status) and saves it
/// in one write via [UpdateVehicleUseCase]. Rates, packages, pricing
/// policy, out-of-city rules, other photos and documents are NOT
/// edited here — they live on the rates editor / rules screen and
/// stay exactly as stored.
class OwnerEditVehicleView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;
  const OwnerEditVehicleView({super.key, required this.vehicle, this.onBack});

  @override
  State<OwnerEditVehicleView> createState() => _OwnerEditVehicleViewState();
}

class _OwnerEditVehicleViewState extends State<OwnerEditVehicleView> {
  late String _selectedMake, _selectedModel, _color, _category, _fuelType, _status;
  late int _selectedYear, _seats;
  late bool _isAutomatic;
  late Set<String> _selectedFeatures;
  late final TextEditingController _plateController;
  XFile? _newFrontFile;
  bool _photoRemoved = false, _isSaving = false, _discardConfirmed = false;
  late String _initialSnapshot;

  bool get _isRented => widget.vehicle.status == 'rented';
  bool get _hasPhoto => _newFrontFile != null || (!_photoRemoved && (widget.vehicle.imageUrl?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    // The specs step only offers the constants lists (same constraint
    // as the add wizard): an out-of-list value falls back to the
    // first option so the dropdowns never crash on a missing value.
    _selectedMake = OwnerVehicleConstants.makes.contains(v.make) ? v.make : OwnerVehicleConstants.makes.first;
    _selectedModel = v.model;
    _selectedYear = v.year.clamp(2011, DateTime.now().year);
    _color = v.color ?? '';
    _category = OwnerVehicleConstants.categories.contains(v.category) ? v.category : OwnerVehicleConstants.categories.first;
    _plateController = TextEditingController(text: v.plateNumber);
    _isAutomatic = v.transmission != 'Manual';
    _fuelType = const ['Petrol', 'Diesel', 'Hybrid', 'Electric'].contains(v.fuelType) ? v.fuelType : 'Petrol';
    _seats = v.seats;
    _selectedFeatures = Set.of(v.features);
    _status = v.status;
    _initialSnapshot = _snapshot();
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  String _snapshot() => [_selectedMake, _selectedModel, '$_selectedYear', _color, _category, _plateController.text, '$_isAutomatic', _fuelType, '$_seats', ..._selectedFeatures, _status, _newFrontFile?.path ?? '', '$_photoRemoved'].join('|');
  bool get _isDirty => _snapshot() != _initialSnapshot;

  void _pop() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  /// Back with unsaved edits asks first (same dialog as the rate matrix).
  Future<void> _handleBack() async {
    if (!_isDirty) return _pop();
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pricingUnsavedTitle),
        content: Text(l10n.pricingUnsavedBody),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.syncDiscard))],
      ),
    );
    if (discard == true) {
      setState(() => _discardConfirmed = true);
      _pop();
    }
  }

  void _choosePhoto() {
    MediaPickerHelper.showMediaSourceSheet(
      context: context,
      hasExistingFile: _hasPhoto,
      onImageSelected: (f) => setState(() {
        _photoRemoved = f == null;
        _newFrontFile = f;
      }),
    );
  }

  static bool _isValidPlate(String plate) => RegExp(r'^[A-Z]{2,4}-?\d{1,2}-?\d{1,4}$').hasMatch(plate.trim().toUpperCase());

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selectedModel.trim().isEmpty) return AppFeedback.showError(context, l10n.addVehicleModelRequired);
    final plate = _plateController.text.trim();
    if (plate.isEmpty || !_isValidPlate(plate)) return AppFeedback.showError(context, l10n.addVehiclePlateRequired);
    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_newFrontFile != null) {
        // Single-slot upload (only imageUrl); the service falls back
        // to the local path when the upload fails, like the add view.
        imageUrl = await VehiclePhotoUploadService.uploadFrontPhoto(shopId: widget.vehicle.shopId, photo: _newFrontFile, vehicleId: widget.vehicle.vehicleId) ?? _newFrontFile!.path;
      } else if (_photoRemoved) {
        // copyWith cannot clear a field (null means "keep"), so an
        // explicit removal is stored as '' — the fleet card falls
        // back to its placeholder asset for a non-URL image.
        imageUrl = '';
      }
      final updated = widget.vehicle.copyWith(
        make: _selectedMake, model: _selectedModel.trim(), year: _selectedYear, plateNumber: plate, category: _category,
        transmission: _isAutomatic ? 'Automatic' : 'Manual', fuelType: _fuelType, seats: _seats, color: _color,
        features: _selectedFeatures.toList(), status: _status, imageUrl: imageUrl,
      );
      await sl<UpdateVehicleUseCase>()(vehicleId: widget.vehicle.vehicleId, vehicle: updated);
      if (!mounted) return;
      _initialSnapshot = _snapshot();
      AppFeedback.showSuccess(context, l10n.editVehicleSaved);
      _pop();
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _assetImage() => Image.asset('assets/images/white_sedan_hero.png', width: double.infinity, height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.directions_car_rounded, size: 64)));

  Widget _fileImage(String path) => Image.file(File(path), width: double.infinity, height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _assetImage());

  /// Same network / local-file / asset fallback as the fleet card.
  Widget _photoPreview() {
    if (_newFrontFile != null) return _fileImage(_newFrontFile!.path);
    final imageUrl = widget.vehicle.imageUrl;
    if (_photoRemoved || imageUrl == null || imageUrl.isEmpty) return _assetImage();
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, width: double.infinity, height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _assetImage());
    }
    if (imageUrl.startsWith('/') || imageUrl.contains(r'\')) return _fileImage(imageUrl);
    return _assetImage();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isDirty || _discardConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              MinimalAppBar(title: l10n.editVehicleTitle, subtitle: widget.vehicle.displayName, onBack: _handleBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddVehicleSpecsStep(
                        selectedMake: _selectedMake, onMakeChanged: (m) => setState(() => _selectedMake = m),
                        selectedModel: _selectedModel, onModelChanged: (m) => setState(() => _selectedModel = m),
                        selectedYear: _selectedYear, onYearChanged: (y) => setState(() => _selectedYear = y),
                        color: _color, onColorChanged: (c) => setState(() => _color = c),
                        category: _category, onCategoryChanged: (c) => setState(() => _category = c),
                        plateController: _plateController, onPlateChanged: () => setState(() {}),
                        isAutomatic: _isAutomatic, onTransmissionChanged: (a) => setState(() => _isAutomatic = a),
                        fuelType: _fuelType, onFuelTypeChanged: (f) => setState(() => _fuelType = f),
                        seats: _seats, onSeatsChanged: (s) => setState(() => _seats = s),
                        selectedFeatures: _selectedFeatures,
                        onFeatureToggled: (f) => setState(() => _selectedFeatures.contains(f) ? _selectedFeatures.remove(f) : _selectedFeatures.add(f)),
                      ),
                      const SizedBox(height: 18),
                      Text(l10n.addVehiclePhotoFront, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: double.infinity, height: 190, child: _photoPreview())),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: _choosePhoto, icon: const Icon(Icons.photo_camera_rounded), label: Text(l10n.mediaSelectSource)),
                      const SizedBox(height: 18),
                      Text(l10n.editVehicleStatus, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const Key('edit-vehicle-status'),
                            value: _status,
                            isExpanded: true,
                            // A rented car cannot change status — flipping
                            // it to maintenance while out on rent would lie
                            // about a car a customer is driving.
                            onChanged: _isRented ? null : (v) {
                              if (v != null) setState(() => _status = v);
                            },
                            items: [
                              DropdownMenuItem(value: 'available', child: Text(l10n.available)),
                              DropdownMenuItem(value: 'maintenance', child: Text(l10n.fleetFilterMaintenance)),
                              if (_isRented) DropdownMenuItem(value: 'rented', enabled: false, child: Text(l10n.fleetOnRent)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
                child: DebouncedButton(text: l10n.editVehicleSave, isLoading: _isSaving, onPressed: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
