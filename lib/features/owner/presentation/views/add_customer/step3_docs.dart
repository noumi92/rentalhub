import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/date_picker_helper.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trust/data/services/cnic_ocr_service.dart';
import 'doc_photo_tile.dart';
import 'kyc_draft.dart';
import 'kyc_step.dart';

/// Wizard step 2 — driving license (front/back, number, expiry) and
/// rental terms. KYC documents are strictly CNIC & Driving License.
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
  bool _scanningLicenseFront = false;
  bool _scanningLicenseBack = false;

  @override
  void initState() {
    super.initState();
    _licenseNumberController = TextEditingController(text: widget.draft.licenseNumber);
    _licenseExpiryController = TextEditingController(text: widget.draft.licenseExpiry);
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
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

  @override
  Future<bool> validate() async {
    final d = widget.draft;
    final l10n = AppLocalizations.of(context)!;
    // Driving license photos & details are optional for walk-in customers;
    // validate expiry format only if the owner typed one, and require terms.
    final missing = d.licenseExpiry.trim().isNotEmpty &&
            _validateDate(d.licenseExpiry, l10n.kycWizardDateFormatError) !=
                null
        ? l10n.kycWizardDateFormatError
        : !d.termsAgreed
            ? l10n.kycWizardTermsMissing
            : null;
    if (missing != null && mounted) AppFeedback.showError(context, missing);
    return missing == null;
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

  Widget _field(TextEditingController controller, String label, {String? hint, TextInputType keyboard = TextInputType.text, List<TextInputFormatter>? formatters, Widget? suffixIcon, required ValueChanged<String> onChanged}) {
    // Filled like step 1's fields (were unfilled here).
    return TextFormField(controller: controller, keyboardType: keyboard, inputFormatters: formatters, decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: suffixIcon, filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest), onChanged: onChanged);
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
            Expanded(child: DocPhotoTile(label: l10n.kycWizardLicenseFront, file: draft.licenseFrontPhoto, existingUrl: draft.existingUrlFor('licenseFrontUrl'), buttonKey: const ValueKey('step3_license_front'), onPick: () => _captureLicense(front: true), onRemove: () { setState(() { draft.licenseFrontPhoto = null; draft.clearExisting('licenseFrontUrl'); }); widget.onChanged(); }, removeButtonKey: const ValueKey('step3_license_front_remove'), scanning: _scanningLicenseFront)),
            const SizedBox(width: 12),
            Expanded(child: DocPhotoTile(label: l10n.kycWizardLicenseBack, file: draft.licenseBackPhoto, existingUrl: draft.existingUrlFor('licenseBackUrl'), buttonKey: const ValueKey('step3_license_back'), onPick: () => _captureLicense(front: false), onRemove: () { setState(() { draft.licenseBackPhoto = null; draft.clearExisting('licenseBackUrl'); }); widget.onChanged(); }, removeButtonKey: const ValueKey('step3_license_back_remove'), scanning: _scanningLicenseBack)),
          ],
        ),
        const SizedBox(height: 12),
        _field(_licenseNumberController, l10n.kycWizardLicenseNumber, onChanged: (v) { draft.licenseNumber = v; widget.onChanged(); }),
        const SizedBox(height: 12),
        _field(_licenseExpiryController, l10n.kycWizardLicenseExpiry, hint: '01.01.2030', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(10)], suffixIcon: IconButton(key: const ValueKey('step3_license_expiry_picker'), tooltip: l10n.kycWizardLicenseExpiry, icon: const Icon(Icons.calendar_today_outlined, size: 20), onPressed: () async { await pickFormattedDate(context: context, controller: _licenseExpiryController, isDob: false); draft.licenseExpiry = _licenseExpiryController.text; widget.onChanged(); }), onChanged: (v) { draft.licenseExpiry = v; widget.onChanged(); }),
        const SizedBox(height: 16),
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
