import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/usecases/save_customer_usecase.dart';
import '../../../trust/data/services/cnic_ocr_service.dart';
import '../../../trust/utils/cnic_text_parser.dart';

/// Phase B (C2): the owner reviews what OCR read off the CNIC and
/// corrects it before anything is saved. Every field is editable —
/// OCR misreads names and digits, so nothing is trusted blindly.
class OwnerCnicReviewView extends StatefulWidget {
  final CnicScanResult initial;
  final String? shopId;
  final ValueChanged<String>? onSaved;

  const OwnerCnicReviewView({
    super.key,
    required this.initial,
    this.shopId,
    this.onSaved,
  });

  @override
  State<OwnerCnicReviewView> createState() => _OwnerCnicReviewViewState();
}

class _OwnerCnicReviewViewState extends State<OwnerCnicReviewView> {
  late final TextEditingController _nameController;
  late final TextEditingController _fatherController;
  late final TextEditingController _cnicController;
  late final TextEditingController _dobController;
  late final TextEditingController _expiryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _scanningBack = false;
  bool _saving = false;

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nameController = TextEditingController(text: r.name ?? '');
    _fatherController = TextEditingController(text: r.fatherName ?? '');
    _cnicController = TextEditingController(text: r.cnicNumber ?? '');
    _dobController = TextEditingController(text: r.dateOfBirth ?? '');
    _expiryController = TextEditingController(text: r.dateOfExpiry ?? '');
    _phoneController = TextEditingController();
    _addressController = TextEditingController(text: r.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherController.dispose();
    _cnicController.dispose();
    _dobController.dispose();
    _expiryController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _scanBack() async {
  final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _scanningBack = true);
    try {
      final result = await CnicOcrService().scanBack(File(picked.path));
      if (result.address != null && mounted) {
        setState(() => _addressController.text = result.address!);
      } else if (mounted) {
        AppFeedback.showInfo(
            context, l10n.customersCnicNoAddress);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersCnicBackScanFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _scanningBack = false);
    }
  }

  Future<void> _save() async {
  final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      AppFeedback.showError(
          context, l10n.customersCnicNamePhoneRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final digits = cnic.replaceAll(RegExp(r'\D'), '');
      await sl<SaveCustomerUseCase>()(CustomerEntity(
        customerId: digits.isNotEmpty
            ? 'cust-$digits'
            : 'cust-${DateTime.now().millisecondsSinceEpoch}',
        shopId: _shopId,
        name: name,
        phone: phone,
        cnic: cnic.isEmpty ? null : cnic,
        source: 'ocr',
        createdAt: DateTime.now(),
        dateOfBirth: _dobController.text.trim().isEmpty
            ? null
            : _dobController.text.trim(),
        cnicExpiry: _expiryController.text.trim().isEmpty
            ? null
            : _expiryController.text.trim(),
      ));
      if (!mounted) return;
      widget.onSaved?.call(cnic);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersCnicSaveFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController controller, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: IconButton(
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.customersCnicReviewTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.customersCnicReviewSubtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_nameController, l10n.onboardingFullName),
                    _field(_fatherController, l10n.customersCnicFatherName),
                    _field(_cnicController, l10n.customersCnicNumber,
                        keyboard: TextInputType.number),
                    _field(_dobController, l10n.customersCnicDob),
                    _field(_expiryController, l10n.customersCnicExpiry),
                    _field(_phoneController, l10n.customersCnicPhone,
                        keyboard: TextInputType.phone),
                    _field(_addressController, l10n.customersCnicAddress),
                    OutlinedButton.icon(
                      onPressed: _scanningBack ? null : _scanBack,
                      icon: _scanningBack
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.flip_to_back_rounded),
                      label: Text(l10n.customersCnicScanBack),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n.customersCnicSave),
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
