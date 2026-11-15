import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trust/data/services/cnic_ocr_service.dart';
import 'doc_photo_tile.dart';
import 'kyc_draft.dart';
import 'kyc_step.dart';

/// Wizard step 3 — driving license, utility bill, extra documents,
/// customer signature and the rental terms (spec O14).
class Step3Docs extends StatefulWidget {
  final KycDraft draft;
  final VoidCallback onChanged;

  const Step3Docs({super.key, required this.draft, required this.onChanged});

  @override
  Step3DocsState createState() => Step3DocsState();
}

class Step3DocsState extends KycStepState<Step3Docs> {
  late final TextEditingController _licenseNumberController;
  late final TextEditingController _licenseExpiryController;
  late final SignatureController _signatureController;
  late bool _signed;
  bool _scanningLicenseFront = false;
  bool _scanningLicenseBack = false;

  @override
  void initState() {
    super.initState();
    _licenseNumberController = TextEditingController(text: widget.draft.licenseNumber);
    _licenseExpiryController = TextEditingController(text: widget.draft.licenseExpiry);
    _signatureController = SignatureController(penStrokeWidth: 3, penColor: Colors.black);
    _signed = widget.draft.hasSignature;
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  /// dd.mm.yyyy only; an invalid date returns the localized format
  /// error (FG-14) — never the field label, which reads as a label,
  /// not an explanation.
  static String? _validateDate(String? value, String error) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(t);
    if (m == null) return error;
    final day = int.parse(m[1]!); final month = int.parse(m[2]!); final year = int.parse(m[3]!);
    final parsed = DateTime.tryParse('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
    if (parsed == null || parsed.day != day || parsed.month != month || parsed.year != year) return error;
    return null;
  }

  /// FG-16: name the FIRST missing item instead of one generic
  /// "step incomplete" for all seven requirements, so the owner
  /// knows exactly what to add; an empty signature pad and the
  /// unaccepted terms each get their own message.
  @override
  Future<bool> validate() async {
    final d = widget.draft;
    final l10n = AppLocalizations.of(context)!;
    // First missing item wins, in screen order.
    final missing = !d.hasLicenseFront ? l10n.kycWizardMissingItem(l10n.kycWizardLicenseFront)
        : !d.hasLicenseBack ? l10n.kycWizardMissingItem(l10n.kycWizardLicenseBack)
        : d.licenseNumber.trim().isEmpty ? l10n.kycWizardMissingItem(l10n.kycWizardLicenseNumber)
        : d.licenseExpiry.trim().isEmpty ? l10n.kycWizardMissingItem(l10n.kycWizardLicenseExpiry)
        : _validateDate(d.licenseExpiry, l10n.kycWizardDateFormatError) != null ? l10n.kycWizardDateFormatError
        : !d.hasUtilityBill ? l10n.kycWizardMissingItem(l10n.kycWizardUtilityBill)
        : !d.hasSignature ? l10n.kycWizardSignatureMissing
        : !d.termsAgreed ? l10n.kycWizardTermsMissing
        : null;
    if (missing != null && mounted) AppFeedback.showError(context, missing);
    return missing == null;
  }

  /// Utility bill + extra docs: rear camera only (FG-17). The wizard
  /// plan allows the gallery for CNIC front/back only; the bill and
  /// extra documents are KYC evidence like the license, so they
  /// follow the same camera-only rule (no gallery row).
  Future<void> _pick(ValueSetter<XFile> set) async {
    await MediaPickerHelper.showMediaSourceSheet(context: context, cameraOnly: true, onImageSelected: (file) { if (file == null || !mounted) return; setState(() => set(file)); widget.onChanged(); });
  }

  void _syncLicenseControllers() {
    _licenseNumberController.text = widget.draft.licenseNumber;
    _licenseExpiryController.text = widget.draft.licenseExpiry;
  }

  /// License front/back: rear camera only (no gallery), then the
  /// on-device OCR reads the number and expiry into the fields. The
  /// front is the primary source; the back fills what the front did
  /// not yield. Both images are saved with the wizard.
  Future<void> _captureLicense({required bool front}) async {
    // Per-side guard: a front OCR still in flight must not block
    // the back capture (and vice versa).
    if (front ? _scanningLicenseFront : _scanningLicenseBack) return;
    XFile? picked;
    await MediaPickerHelper.showMediaSourceSheet(context: context, cameraOnly: true, onImageSelected: (file) => picked = file);
    final photo = picked;
    if (photo == null || !mounted) return;
    setState(() { if (front) { widget.draft.licenseFrontPhoto = photo; _scanningLicenseFront = true; } else { widget.draft.licenseBackPhoto = photo; _scanningLicenseBack = true; } });
    widget.onChanged();
    try {
      final result = await CnicOcrService().scanLicense(File(photo.path));
      if (!mounted) return;
      if (result.hasAnything) {
        setState(() { widget.draft.applyLicenseScan(result, overwrite: front); _syncLicenseControllers(); });
        widget.onChanged();
      } else if (front) {
        AppFeedback.showWarning(context, AppLocalizations.of(context)!.kyc2_licenseUnreadable);
      }
    } catch (_) {
      if (mounted && front) AppFeedback.showWarning(context, AppLocalizations.of(context)!.kyc2_licenseUnreadable);
    } finally {
      if (mounted) setState(() { if (front) { _scanningLicenseFront = false; } else { _scanningLicenseBack = false; } });
    }
  }

  Future<void> _confirmSignature() async {
    if (_signatureController.isEmpty) {
      AppFeedback.showError(context, AppLocalizations.of(context)!.kycWizardSignatureMissing);
      return;
    }
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty || !mounted) return;
    setState(() { widget.draft.signaturePng = bytes; _signed = true; });
    widget.onChanged();
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() { widget.draft.signaturePng = null; _signed = false; });
    widget.onChanged();
  }

  void _showTerms() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.contractTermsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(l10n.contractTerm1), const SizedBox(height: 8), Text(l10n.contractTerm2), const SizedBox(height: 8), Text(l10n.contractTerm3)],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonConfirm))],
      ),
    );
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(top: 4, bottom: 10), child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)));

  Widget _field(TextEditingController controller, String label, {String? hint, TextInputType keyboard = TextInputType.text, List<TextInputFormatter>? formatters, required ValueChanged<String> onChanged}) {
    // Filled like step 1's fields (were unfilled here).
    return TextFormField(controller: controller, keyboardType: keyboard, inputFormatters: formatters, decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest), onChanged: onChanged);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(l10n.kycWizardLicense),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: DocPhotoTile(label: l10n.kycWizardLicenseFront, file: draft.licenseFrontPhoto, buttonKey: const ValueKey('step3_license_front'), onPick: () => _captureLicense(front: true), onRemove: () { setState(() => draft.licenseFrontPhoto = null); widget.onChanged(); }, removeButtonKey: const ValueKey('step3_license_front_remove'), scanning: _scanningLicenseFront)),
            const SizedBox(width: 12),
            Expanded(child: DocPhotoTile(label: l10n.kycWizardLicenseBack, file: draft.licenseBackPhoto, buttonKey: const ValueKey('step3_license_back'), onPick: () => _captureLicense(front: false), onRemove: () { setState(() => draft.licenseBackPhoto = null); widget.onChanged(); }, removeButtonKey: const ValueKey('step3_license_back_remove'), scanning: _scanningLicenseBack)),
          ],
        ),
        const SizedBox(height: 12),
        _field(_licenseNumberController, l10n.kycWizardLicenseNumber, onChanged: (v) { draft.licenseNumber = v; widget.onChanged(); }),
        const SizedBox(height: 12),
        _field(_licenseExpiryController, l10n.kycWizardLicenseExpiry, hint: '01.01.2030', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)], onChanged: (v) { draft.licenseExpiry = v; widget.onChanged(); }),
        const SizedBox(height: 20),
        _section(l10n.kycWizardUtilityBill),
        DocPhotoTile(label: l10n.kycWizardUtilityBill, file: draft.utilityBillPhoto, buttonKey: const ValueKey('step3_bill'), onPick: () => _pick((f) => draft.utilityBillPhoto = f), onRemove: () { setState(() => draft.utilityBillPhoto = null); widget.onChanged(); }, removeButtonKey: const ValueKey('step3_bill_remove')),
        const SizedBox(height: 20),
        _section(l10n.kycWizardExtraDocs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < draft.extraPhotos.length; i++)
              Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(draft.extraPhotos[i].path), width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded))),
                  // 48dp hit area (was a 20px icon) with the icon
                  // centred in the top-right corner of the thumb.
                  Positioned(right: 0, top: 0, child: SizedBox(width: 48, height: 48, child: IconButton(key: ValueKey('step3_extra_remove_$i'), padding: EdgeInsets.zero, tooltip: l10n.kycWizardRemoveImage, icon: const Icon(Icons.cancel_rounded, size: 24), onPressed: () { setState(() => draft.extraPhotos.removeAt(i)); widget.onChanged(); }))),
                ],
              ),
            OutlinedButton.icon(key: const ValueKey('step3_extra_add'), onPressed: () => _pick((f) => draft.extraPhotos.add(f)), icon: const Icon(Icons.add_a_photo_rounded), label: Text(l10n.kycWizardAddPhoto)),
          ],
        ),
        const SizedBox(height: 20),
        _section(l10n.kycWizardSignature),
        Container(
          height: 120,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _signed && draft.signaturePng != null
                ? Image.memory(draft.signaturePng!, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded))
                : Signature(controller: _signatureController, backgroundColor: Colors.white),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(key: const ValueKey('step3_signature_clear'), onPressed: _clearSignature, icon: const Icon(Icons.clear_rounded, size: 16), label: Text(l10n.kycWizardSignatureClear)),
            if (!_signed) ElevatedButton(key: const ValueKey('step3_signature_confirm'), onPressed: _confirmSignature, child: Text(l10n.commonConfirm)),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          key: const ValueKey('step3_terms_checkbox'),
          value: draft.termsAgreed,
          title: Text(l10n.kycWizardAgreeTerms),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) { setState(() => draft.termsAgreed = v ?? false); widget.onChanged(); },
        ),
        Align(alignment: Alignment.centerLeft, child: TextButton(key: const ValueKey('step3_view_terms'), onPressed: _showTerms, child: Text(l10n.kycWizardViewTerms))),
      ],
    );
  }
}
