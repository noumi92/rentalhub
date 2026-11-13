import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/usecases/save_customer_usecase.dart';
import '../../../trust/data/services/cnic_ocr_service.dart';
import '../../../trust/data/services/customer_qr_code_service.dart';
import '../../../trust/data/services/document_qr_service.dart';
import '../../../trust/utils/cnic_text_parser.dart';

/// Phase B (C2): the owner reviews what OCR read off the CNIC and
/// corrects it before anything is saved — OCR misreads names and
/// digits, so nothing is trusted blindly. Audit §20: a validated
/// [Form] (CNIC/phone/date validators + formatters), Father's Name
/// and Address saved on the entity (were discarded), the scanned
/// card photo previewed, and the view is a go_router route
/// (`/owner/customers/cnic-review`), not a Navigator push.
class OwnerCnicReviewView extends StatefulWidget {
  final CnicScanResult initial;
  final String? shopId;
  final ValueChanged<String>? onSaved;

  /// Path of the front-of-card photo the scan view picked, shown as
  /// a thumbnail so OCR can be checked against the card.
  final String? frontImagePath;

  /// Test seam for the QR reader; defaults to the real service.
  final DocumentQrService? qrService;

  const OwnerCnicReviewView({
    super.key,
    required this.initial,
    this.shopId,
    this.onSaved,
    this.frontImagePath,
    this.qrService,
  });

  @override
  State<OwnerCnicReviewView> createState() => _OwnerCnicReviewViewState();
}

class _OwnerCnicReviewViewState extends State<OwnerCnicReviewView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _fatherController;
  late final TextEditingController _cnicController;
  late final TextEditingController _dobController;
  late final TextEditingController _expiryController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String? _backImagePath;
  bool _scanningBack = false;
  bool _saving = false;

  /// The CNIC back-QR number, held only until save writes it to the
  /// restricted doc. Never rendered in this view (super admin only).
  String _qrCode = '';
  late final DocumentQrService _qrService;

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _qrService = widget.qrService ?? DocumentQrService();
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
    _nameController.dispose(); _fatherController.dispose(); _cnicController.dispose(); _dobController.dispose();
    _expiryController.dispose(); _phoneController.dispose(); _addressController.dispose();
    super.dispose();
  }

  /// dd.mm.yyyy only. OW-m21: the error used to be the field label
  /// itself ("Date of Birth") — now a localized explanation.
  static String? _validateDate(String? value, String message) {
    final t = value?.trim() ?? ''; if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(t); if (m == null) return message;
    final day = int.parse(m[1]!); final month = int.parse(m[2]!); final year = int.parse(m[3]!);
    final parsed = DateTime.tryParse('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
    if (parsed == null || parsed.day != day || parsed.month != month || parsed.year != year) return message;
    return null;
  }

  Future<void> _scanBack() async {
  final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 85);
    if (picked == null) return;
    setState(() => _scanningBack = true);
    try {
      // The QR NUMBER is stored for the restricted doc (super admin only — never shown here); OCR reads the address. The reads are independent, so one failing never loses the other.
      final code = await _qrService.readQr(File(picked.path));
      CnicScanResult? result;
      try { result = await CnicOcrService().scanBack(File(picked.path)); } catch (_) { result = null; }
      if (!mounted) return;
      setState(() => _backImagePath = picked.path);
      if (code != null && code.isNotEmpty) { _qrCode = code; AppFeedback.showSuccess(context, l10n.kyc2_qrRead); }
      if (result?.address != null) {
        setState(() => _addressController.text = result!.address!);
      } else if (code == null || code.isEmpty) {
        AppFeedback.showInfo(context, l10n.customersCnicNoAddress);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersCnicBackScanFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _scanningBack = false);
    }
  }

  Future<void> _save() async {
  final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    setState(() => _saving = true);
    try {
      final digits = cnic.replaceAll(RegExp(r'\D'), '');
      final customerId = digits.isNotEmpty ? 'cust-$digits' : 'cust-${DateTime.now().millisecondsSinceEpoch}';
      await sl<SaveCustomerUseCase>()(CustomerEntity(
        customerId: customerId,
        shopId: _shopId,
        name: name,
        phone: phone,
        cnic: cnic.isEmpty ? null : cnic,
        source: 'ocr',
        createdAt: DateTime.now(),
        dateOfBirth: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
        cnicExpiry: _expiryController.text.trim().isEmpty ? null : _expiryController.text.trim(),
        // Audit §20: these two were collected and then discarded.
        fatherName: _fatherController.text.trim().isEmpty ? null : _fatherController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      ));
      // The CNIC back-QR number goes to the restricted doc (super admin only) — never onto the customer record. Best-effort: a failed QR write never fails the save itself.
      if (_qrCode.trim().isNotEmpty) {
        await CustomerQrCodeService().saveQrCode(customerId: customerId, qrCode: _qrCode);
      }
      if (!mounted) return;
      widget.onSaved?.call(cnic);
      context.pop();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersCnicSaveFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController controller, String label,
      {TextInputType keyboard = TextInputType.text, String? hint, String? Function(String?)? validator, List<TextInputFormatter>? formatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(controller: controller, keyboardType: keyboard, inputFormatters: formatters, validator: validator, decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest)),
    );
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(top: 4, bottom: 10), child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)));

  Widget _photoThumb(String path) => Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), height: 120, fit: BoxFit.cover)));

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset — no double status bar.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.customersCnicReviewTitle,
              subtitle: l10n.customersCnicReviewSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Audit §20: preview the scanned card so OCR can
                      // be checked against it, not corrected blind.
                      if (widget.frontImagePath != null || _backImagePath != null) ...[
                        Row(children: [
                          if (widget.frontImagePath != null) _photoThumb(widget.frontImagePath!),
                          if (widget.frontImagePath != null && _backImagePath != null) const SizedBox(width: 12),
                          if (_backImagePath != null) _photoThumb(_backImagePath!),
                        ]),
                        const SizedBox(height: 16),
                      ],
                      // No dedicated Identity/Contact/Address .arb keys
                      // exist, so the closest existing title keys are
                      // reused as the section headings.
                      _section(l10n.cnicVerifyTitle),
                      _field(_nameController, l10n.onboardingFullName, hint: l10n.onboardingOwnerNameHint, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.addCustomerFullNameRequired : null),
                      _field(_fatherController, l10n.customersCnicFatherName, hint: l10n.onboardingOwnerNameHint),
                      _field(_cnicController, l10n.customersCnicNumber, keyboard: TextInputType.number, hint: '35201-1234567-1', validator: PakistaniValidators.validateCnic, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')), LengthLimitingTextInputFormatter(15)]),
                      _field(_dobController, l10n.customersCnicDob, keyboard: TextInputType.number, hint: '15.03.1990', validator: (v) => _validateDate(v, l10n.cnicReviewDateInvalid), formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)]),
                      _field(_expiryController, l10n.customersCnicExpiry, keyboard: TextInputType.number, hint: '01.01.2030', validator: (v) => _validateDate(v, l10n.cnicReviewDateInvalid), formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)]),
                      _section(l10n.contractFieldContact),
                      _field(_phoneController, l10n.customersCnicPhone, keyboard: TextInputType.phone, hint: '0300-1234567', validator: PakistaniValidators.validatePakistaniPhone, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(15)]),
                      _section(l10n.customersCnicAddress),
                      _field(_addressController, l10n.customersCnicAddress, hint: l10n.onboardingAddressHint),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _scanningBack ? null : _scanBack,
                          icon: _scanningBack ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.flip_to_back_rounded),
                          label: Text(l10n.customersCnicScanBack))),
                      const SizedBox(height: 12),
                      // Audit §20/C7: 54dp DebouncedButton (was ~40dp).
                      DebouncedButton(text: l10n.customersCnicSave, icon: Icons.check_rounded, isLoading: _saving, onPressed: _save),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
