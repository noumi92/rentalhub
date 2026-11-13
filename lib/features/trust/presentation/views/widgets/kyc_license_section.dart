import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/services/cnic_ocr_service.dart';
import '../../../domain/entities/kyc_document_entity.dart';
import 'document_slot_tile.dart';
import 'pick_image_source.dart';

/// The driving license part of the customer KYC submission, kept in
/// its own widget so [KycSubmissionForm] stays under the line cap.
///
/// Front + back are captured with the rear camera only (no gallery —
/// [pickImageFile] enforces that). The front capture is OCR-scanned
/// on-device for the license number and expiry, which fill the fields
/// below; the back capture scans again as a fallback for fields the
/// front did not yield. Both images are saved with the submission.
class KycLicenseData {
  File? front;
  File? back;
  String number = '';
  String expiry = '';
}

class KycLicenseSection extends StatefulWidget {
  const KycLicenseSection({
    super.key,
    required this.data,
    required this.onChanged,
    this.existing,
  });

  final KycLicenseData data;
  final VoidCallback onChanged;

  /// CU-M7: the stored submission, so each licence slot can report
  /// its own stored document (like the CNIC slots) instead of only
  /// ever showing newly picked files.
  final KycDocumentEntity? existing;

  @override
  State<KycLicenseSection> createState() => _KycLicenseSectionState();
}

class _KycLicenseSectionState extends State<KycLicenseSection> {
  late final TextEditingController _numberController;
  late final TextEditingController _expiryController;
  bool _scanningFront = false;
  bool _scanningBack = false;

  @override
  void initState() {
    super.initState();
    _numberController =
        TextEditingController(text: widget.data.number);
    _expiryController =
        TextEditingController(text: widget.data.expiry);
    _numberController.addListener(() {
      widget.data.number = _numberController.text;
      widget.onChanged();
    });
    _expiryController.addListener(() {
      widget.data.expiry = _expiryController.text;
      widget.onChanged();
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _applyScan({required String? number, required String? expiry, required bool overwrite}) {
    if (number != null && (overwrite || _numberController.text.isEmpty)) {
      _numberController.text = number;
    }
    if (expiry != null && (overwrite || _expiryController.text.isEmpty)) {
      _expiryController.text = expiry;
    }
  }

  Future<void> _pickSlot(String slot) async {
    final front = slot == 'front';
    // Per-side guard: a front OCR still in flight must not block
    // the back capture (and vice versa).
    if (front ? _scanningFront : _scanningBack) return;
    final l10n = AppLocalizations.of(context)!;
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    setState(() {
      if (front) {
        widget.data.front = file;
        _scanningFront = true;
      } else {
        widget.data.back = file;
        _scanningBack = true;
      }
    });
    widget.onChanged();
    try {
      final result = await CnicOcrService().scanLicense(file);
      if (!mounted) return;
      if (result.hasAnything) {
        setState(() => _applyScan(
            number: result.licenseNumber,
            expiry: result.dateOfExpiry,
            overwrite: front));
        widget.onChanged();
      } else if (front) {
        AppFeedback.showWarning(context, l10n.kyc2_licenseUnreadable);
      }
    } catch (_) {
      if (mounted && front) {
        AppFeedback.showWarning(context, l10n.kyc2_licenseUnreadable);
      }
    } finally {
      if (mounted) setState(() { if (front) { _scanningFront = false; } else { _scanningBack = false; } });
    }
  }

  String _fileName(File? file) =>
      file == null ? '' : file.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DocumentSlotTile(
          title: l10n.kycWizardLicenseFront,
          subtitle: widget.data.front != null
              ? l10n.kycSelectedFile(_fileName(widget.data.front))
              : l10n.kycSelfDriveNote,
          isUploaded: widget.data.front != null ||
              (widget.existing?.licenseKey.isNotEmpty ?? false),
          onTap: _scanningFront ? () {} : () => _pickSlot('front'),
        ),
        const SizedBox(height: 10),
        DocumentSlotTile(
          title: l10n.kycWizardLicenseBack,
          subtitle: widget.data.back != null
              ? l10n.kycSelectedFile(_fileName(widget.data.back))
              : l10n.kycSelfDriveNote,
          isUploaded: widget.data.back != null ||
              (widget.existing?.licenseBackKey.isNotEmpty ?? false),
          onTap: _scanningBack ? () {} : () => _pickSlot('back'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _numberController,
          decoration: InputDecoration(
            labelText: l10n.kycWizardLicenseNumber,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _expiryController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.kycWizardLicenseExpiry,
            hintText: '01.01.2030',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
