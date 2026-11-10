import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/pakistani_validators.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../../trust/data/services/cnic_ocr_service.dart';
import '../../../../trust/data/services/document_qr_service.dart';
import '../../../../trust/utils/cnic_text_parser.dart';
import 'kyc_draft.dart';
import 'kyc_step.dart';

/// Step 1 of the Add Customer wizard (O11): CNIC + identity. A camera
/// scan prefills the fields; everything stays editable by hand. The
/// only verification is the RentalHub blacklist check — no NADRA
/// claim, and no face matching anywhere.
class Step1Cnic extends StatefulWidget {
  final KycDraft draft;
  final VoidCallback onChanged;

  /// Test seam for the QR reader; defaults to the real service.
  final DocumentQrService? qrService;

  const Step1Cnic({super.key, required this.draft, required this.onChanged, this.qrService});

  @override
  State<Step1Cnic> createState() => _Step1CnicState();
}

class _Step1CnicState extends KycStepState<Step1Cnic> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _fatherController;
  late final TextEditingController _cnicController;
  late final TextEditingController _dobController;
  late final TextEditingController _expiryController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  /// The CNIC last verified clean. Editing the CNIC resets it, so
  /// Next always re-checks the CNIC that is actually on screen.
  String? _checkedCnic;
  bool _isBlacklisted = false;
  bool _showClean = false;
  bool _isVerifying = false;
  bool _scanningFront = false;
  bool _scanningBack = false;
  late final DocumentQrService _qrService;

  @override
  void initState() {
    super.initState();
    _qrService = widget.qrService ?? DocumentQrService();
    final d = widget.draft;
    _nameController = TextEditingController(text: d.name);
    _fatherController = TextEditingController(text: d.fatherName);
    _cnicController = TextEditingController(text: d.cnic);
    _dobController = TextEditingController(text: d.dateOfBirth);
    _expiryController = TextEditingController(text: d.cnicExpiry);
    _addressController = TextEditingController(text: d.address);
    _phoneController = TextEditingController(text: d.phone);
    _nameController.addListener(() { d.name = _nameController.text; widget.onChanged(); });
    _fatherController.addListener(() { d.fatherName = _fatherController.text; widget.onChanged(); });
    _cnicController.addListener(() {
      d.cnic = _cnicController.text;
      if (_checkedCnic != null && _checkedCnic != _cnicController.text.trim()) { _checkedCnic = null; _isBlacklisted = false; _showClean = false; }
      widget.onChanged();
    });
    _dobController.addListener(() { d.dateOfBirth = _dobController.text; widget.onChanged(); });
    _expiryController.addListener(() { d.cnicExpiry = _expiryController.text; widget.onChanged(); });
    _addressController.addListener(() { d.address = _addressController.text; widget.onChanged(); });
    _phoneController.addListener(() { d.phone = _phoneController.text; widget.onChanged(); });
  }

  @override
  void dispose() {
    _nameController.dispose(); _fatherController.dispose(); _cnicController.dispose(); _dobController.dispose();
    _expiryController.dispose(); _addressController.dispose(); _phoneController.dispose();
    super.dispose();
  }

  /// dd.mm.yyyy only; the label itself carries the format, so it
  /// doubles as the (localized) error text — no new .arb key needed.
  static String? _validateDate(String? value, String label) {
    final t = value?.trim() ?? ''; if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(t); if (m == null) return label;
    final day = int.parse(m[1]!); final month = int.parse(m[2]!); final year = int.parse(m[3]!);
    final parsed = DateTime.tryParse('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
    if (parsed == null || parsed.day != day || parsed.month != month || parsed.year != year) return label;
    return null;
  }

  /// Runs the blacklist check for the CNIC on screen. Returns true
  /// only when the CNIC is confirmed clean; a blacklisted CNIC, an
  /// invalid CNIC, or a failed lookup all block Next.
  Future<bool> _runBlacklistCheck() async {
    final l10n = AppLocalizations.of(context)!;
    final cnic = _cnicController.text.trim();
    if (PakistaniValidators.validateCnic(cnic) != null) { AppFeedback.showError(context, l10n.customersScanInvalidCnic); return false; }
    setState(() => _isVerifying = true);
    try {
      final blacklisted = await sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic);
      if (!mounted) return false;
      if (blacklisted) {
        setState(() { _isBlacklisted = true; _showClean = false; _checkedCnic = null; });
        AppFeedback.showError(context, l10n.kycWizardBlacklisted);
        return false;
      }
      setState(() { _isBlacklisted = false; _showClean = true; _checkedCnic = cnic; });
      return true;
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersScanLookupFailed(e.toString()));
      return false;
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Future<bool> validate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final cnic = _cnicController.text.trim();
    if (_checkedCnic == cnic && !_isBlacklisted) return true;
    return _runBlacklistCheck();
  }

  void _applyScanResult(CnicScanResult result) {
    widget.draft.applyCnicScan(result);
    _nameController.text = widget.draft.name;
    _fatherController.text = widget.draft.fatherName;
    _cnicController.text = widget.draft.cnic;
    _dobController.text = widget.draft.dateOfBirth;
    _expiryController.text = widget.draft.cnicExpiry;
    _addressController.text = widget.draft.address;
  }

  Future<void> _scanCnic({required bool front}) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() { if (front) { _scanningFront = true; } else { _scanningBack = true; } });
    try {
      if (front) {
        final result = await CnicOcrService().scanFront(File(picked.path));
        if (!mounted) return;
        if (!result.hasAnything) { AppFeedback.showError(context, l10n.customersScanUnreadable); return; }
        setState(() { widget.draft.cnicFrontPhoto = picked; _applyScanResult(result); });
      } else {
        // Back: the QR NUMBER is stored on the draft for the restricted
        // doc (super admin only — never shown here) and OCR reads the
        // address. The reads are independent: a failed QR read never
        // loses the OCR address, and vice versa.
        final code = await _qrService.readQr(File(picked.path));
        CnicScanResult? ocr;
        try { ocr = await CnicOcrService().scanBack(File(picked.path)); } catch (_) { ocr = null; }
        if (!mounted) return;
        setState(() {
          widget.draft.cnicBackPhoto = picked;
          if (code != null && code.isNotEmpty) widget.draft.qrCode = code;
          if (ocr != null) _applyScanResult(ocr);
        });
        if (code != null && code.isNotEmpty) AppFeedback.showSuccess(context, l10n.kyc2_qrRead);
        if ((code == null || code.isEmpty) && (ocr == null || !ocr.hasAnything)) AppFeedback.showError(context, l10n.customersScanUnreadable);
      }
      widget.onChanged();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.customersScanFailed(e.toString()));
    } finally {
      if (mounted) setState(() { if (front) { _scanningFront = false; } else { _scanningBack = false; } });
    }
  }

  Widget _field(TextEditingController controller, String label, {TextInputType keyboard = TextInputType.text, String? hint, String? Function(String?)? validator, List<TextInputFormatter>? formatters, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(controller: controller, keyboardType: keyboard, maxLines: maxLines, inputFormatters: formatters, validator: validator, decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;
    final okColor = Theme.of(context).colorScheme.primary;
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanningFront ? null : () => _scanCnic(front: true),
                    icon: _scanningFront ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.credit_card_rounded),
                    label: Text(l10n.kycWizardScanFront))),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanningBack ? null : () => _scanCnic(front: false),
                    icon: _scanningBack ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.flip_to_back_rounded),
                    label: Text(l10n.kycWizardScanBack))),
              ],
            ),
            if (widget.draft.cnicFrontPhoto != null || widget.draft.cnicBackPhoto != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                if (widget.draft.cnicFrontPhoto != null) Chip(avatar: const Icon(Icons.check_rounded, size: 16), label: Text(l10n.kycWizardFrontScanned)),
                if (widget.draft.cnicBackPhoto != null) Chip(avatar: const Icon(Icons.check_rounded, size: 16), label: Text(l10n.kycWizardBackScanned)),
              ]),
            ],
            const SizedBox(height: 16),
            Text(l10n.kycWizardManualEntry, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _field(_nameController, l10n.addCustomerName, validator: (v) => (v == null || v.trim().isEmpty) ? l10n.addCustomerFullNameRequired : null),
            _field(_fatherController, l10n.kycWizardFatherName),
            _field(_cnicController, l10n.addCustomerCnic, keyboard: TextInputType.number, hint: '35201-1234567-1', validator: PakistaniValidators.validateCnic, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')), LengthLimitingTextInputFormatter(15)]),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isVerifying ? null : _runBlacklistCheck,
                icon: _isVerifying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shield_rounded),
                label: Text(l10n.cnicVerifyButton))),
            if (_isBlacklisted) ...[const SizedBox(height: 8), Text(l10n.kycWizardBlacklisted, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: errorColor, fontWeight: FontWeight.w700))],
            if (_showClean) ...[const SizedBox(height: 8), Text(l10n.blacklistCleanTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: okColor, fontWeight: FontWeight.w700))],
            const SizedBox(height: 12),
            _field(_dobController, l10n.kycWizardDateOfBirth, keyboard: TextInputType.number, hint: '15.03.1990', validator: (v) => _validateDate(v, l10n.kycWizardDateOfBirth), formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)]),
            _field(_expiryController, l10n.kycWizardCnicExpiry, keyboard: TextInputType.number, hint: '01.01.2030', validator: (v) => _validateDate(v, l10n.kycWizardCnicExpiry), formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)]),
            _field(_addressController, l10n.kycWizardAddress, maxLines: 3),
            _field(_phoneController, l10n.kycWizardWhatsappNumber, keyboard: TextInputType.phone, hint: '0300-1234567', validator: PakistaniValidators.validatePakistaniPhone, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')), LengthLimitingTextInputFormatter(15)]),
          ],
        ),
      ),
    );
  }
}
