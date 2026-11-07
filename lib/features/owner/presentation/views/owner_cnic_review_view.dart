import 'dart:io';

import 'package:flutter/material.dart';
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
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _scanningBack = true);
    try {
      final result =
          await CnicOcrService().scanBack(File(picked.path));
      if (result.address != null && mounted) {
        setState(() => _addressController.text = result.address!);
      } else if (mounted) {
        AppFeedback.showInfo(
            context, 'No address read from the back of the card.');
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Back scan failed: $e');
    } finally {
      if (mounted) setState(() => _scanningBack = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      AppFeedback.showError(
          context, 'Name and phone are required to save the customer.');
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
      if (mounted) AppFeedback.showError(context, 'Could not save: $e');
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review Scanned CNIC',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Correct anything OCR misread',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_nameController, 'Full Name'),
                    _field(_fatherController, "Father's Name"),
                    _field(_cnicController, 'CNIC Number',
                        keyboard: TextInputType.number),
                    _field(_dobController, 'Date of Birth (dd.mm.yyyy)'),
                    _field(_expiryController, 'CNIC Expiry (dd.mm.yyyy)'),
                    _field(_phoneController, 'Phone Number',
                        keyboard: TextInputType.phone),
                    _field(_addressController, 'Address (from back of card)'),
                    OutlinedButton.icon(
                      onPressed: _scanningBack ? null : _scanBack,
                      icon: _scanningBack
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.flip_to_back_rounded),
                      label: const Text('Scan Back of CNIC (address)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Customer & Check Blacklist'),
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
