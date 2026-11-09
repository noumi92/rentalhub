import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
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

  /// dd.mm.yyyy only; the label itself carries the format, so it
  /// doubles as the (localized) error text — no new .arb key needed.
  static String? _validateDate(String? value, String label) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(t);
    if (m == null) return label;
    final day = int.parse(m[1]!); final month = int.parse(m[2]!); final year = int.parse(m[3]!);
    final parsed = DateTime.tryParse('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
    if (parsed == null || parsed.day != day || parsed.month != month || parsed.year != year) return label;
    return null;
  }

  @override
  Future<bool> validate() async {
    final d = widget.draft;
    final expiryOk = d.licenseExpiry.trim().isNotEmpty && _validateDate(d.licenseExpiry, '') == null;
    final ok = d.hasLicenseFront && d.hasLicenseBack && d.licenseNumber.trim().isNotEmpty && expiryOk && d.hasUtilityBill && d.hasSignature && d.termsAgreed;
    if (!ok && mounted) AppFeedback.showError(context, AppLocalizations.of(context)!.kycWizardStepIncomplete);
    return ok;
  }

  Future<void> _pick(ValueSetter<XFile> set) async {
    await MediaPickerHelper.showMediaSourceSheet(
      context: context,
      onImageSelected: (file) {
        if (file == null || !mounted) return;
        setState(() => set(file));
        widget.onChanged();
      },
    );
  }

  Future<void> _confirmSignature() async {
    if (_signatureController.isEmpty) {
      AppFeedback.showError(context, AppLocalizations.of(context)!.kycWizardStepIncomplete);
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

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(top: 4, bottom: 10), child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)));

  Widget _photoTile({required String label, required XFile? file, required Key buttonKey, required VoidCallback onPick}) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
          child: file == null
              ? const Center(child: Icon(Icons.image_rounded, size: 40))
              : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(file.path), width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded)))),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(key: buttonKey, onPressed: onPick, icon: const Icon(Icons.camera_alt_rounded), label: Text(l10n.kycTakePhoto)),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, {String? hint, TextInputType keyboard = TextInputType.text, List<TextInputFormatter>? formatters, required ValueChanged<String> onChanged}) {
    return TextFormField(controller: controller, keyboardType: keyboard, inputFormatters: formatters, decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()), onChanged: onChanged);
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
            Expanded(child: _photoTile(label: l10n.kycWizardLicenseFront, file: draft.licenseFrontPhoto, buttonKey: const ValueKey('step3_license_front'), onPick: () => _pick((f) => draft.licenseFrontPhoto = f))),
            const SizedBox(width: 12),
            Expanded(child: _photoTile(label: l10n.kycWizardLicenseBack, file: draft.licenseBackPhoto, buttonKey: const ValueKey('step3_license_back'), onPick: () => _pick((f) => draft.licenseBackPhoto = f))),
          ],
        ),
        const SizedBox(height: 12),
        _field(_licenseNumberController, l10n.kycWizardLicenseNumber, onChanged: (v) { draft.licenseNumber = v; widget.onChanged(); }),
        const SizedBox(height: 12),
        _field(_licenseExpiryController, l10n.kycWizardLicenseExpiry, hint: '01.01.2030', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)], onChanged: (v) { draft.licenseExpiry = v; widget.onChanged(); }),
        const SizedBox(height: 20),
        _section(l10n.kycWizardUtilityBill),
        _photoTile(label: l10n.kycWizardUtilityBill, file: draft.utilityBillPhoto, buttonKey: const ValueKey('step3_bill'), onPick: () => _pick((f) => draft.utilityBillPhoto = f)),
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
                  Positioned(right: 0, top: 0, child: InkWell(key: ValueKey('step3_extra_remove_$i'), onTap: () { setState(() => draft.extraPhotos.removeAt(i)); widget.onChanged(); }, child: const Icon(Icons.cancel_rounded, size: 20))),
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
