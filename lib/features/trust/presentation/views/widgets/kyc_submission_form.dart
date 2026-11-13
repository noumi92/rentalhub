import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/pakistani_validators.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../cubit/kyc_cubit.dart';
import '../../../data/services/cnic_ocr_service.dart';
import '../../../data/services/document_qr_service.dart';
import '../../../domain/entities/kyc_document_entity.dart';
import 'document_slot_tile.dart';
import 'kyc_license_section.dart';
import 'pick_image_source.dart';
import '../../../../../l10n/app_localizations.dart';

/// G3: the KYC submission form — the CNIC field (prefilled from the
/// customer's real record), the on-device CNIC scan, the three document
/// slots holding photos the customer actually picks, and the real
/// submit through KycCubit. Extracted from [CustomerDocumentsView] so
/// the view stays under the 250-line cap.
///
/// Camera rule (2026-11-10): every capture opens the BACK camera, no
/// gallery photo is accepted; the CNIC back-QR number is stored in the
/// restricted `customer_qr_codes` doc and never shown here.
class KycSubmissionForm extends StatefulWidget {
  const KycSubmissionForm({
    super.key,
    required this.initialCnic,
    required this.existing,
    required this.userUid,
    required this.onSubmitted,
    this.qrService,
  });

  final String initialCnic;
  final KycDocumentEntity? existing;
  final String userUid;
  final void Function(String cnic) onSubmitted;

  /// Test seam: the QR reader. Defaults to the real
  /// [DocumentQrService] (mobile_scanner, on-device).
  final DocumentQrService? qrService;

  @override
  State<KycSubmissionForm> createState() => _KycSubmissionFormState();
}

class _KycSubmissionFormState extends State<KycSubmissionForm> {
  late final TextEditingController _cnicController;
  late final DocumentQrService _qrService;
  File? _cnicFront;
  File? _cnicBack;
  final _licenseData = KycLicenseData();

  /// The CNIC back-QR number, held only until submit writes it to
  /// the restricted doc. Never rendered anywhere in this app.
  String _qrCode = '';
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _cnicController = TextEditingController(text: widget.initialCnic);
    _qrService = widget.qrService ?? DocumentQrService();
  }

  @override
  void didUpdateWidget(KycSubmissionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCnic != oldWidget.initialCnic &&
        _cnicController.text.isEmpty) {
      _cnicController.text = widget.initialCnic;
    }
  }

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _pickSlot(String slot) async {
    final file = await pickImageFile(context);
    if (file == null || !mounted) return;
    setState(() {
      if (slot == 'front') {
        _cnicFront = file;
      } else {
        _cnicBack = file;
      }
    });
    // CNIC back: read the QR number off the captured photo and hold
    // it for the restricted doc at submit. The number is never shown
    // here; the back image itself is saved either way.
    if (slot == 'back') {
      final code = await _qrService.readQr(file);
      if (!mounted || code == null || code.isEmpty) return;
      setState(() => _qrCode = code);
      AppFeedback.showSuccess(context, AppLocalizations.of(context)!.kyc2_qrRead);
    }
  }

  // Scans the CNIC front with on-device OCR and fills the number; the
  // scanned photo becomes the front-side file. Rear camera only.
  Future<void> _scanCnic() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final result = await CnicOcrService().scanFront(File(picked.path));
      if (!mounted) return;
      if (result.cnicNumber != null && result.cnicNumber!.isNotEmpty) {
        setState(() {
          _cnicController.text = result.cnicNumber!;
          _cnicFront = File(picked.path);
        });
        AppFeedback.showSuccess(context, l10n.kycCnicRead);
      } else {
        AppFeedback.showWarning(context, l10n.kycScanUnreadable);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.kycScanError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _submit(KycCubit cubit) async {
    final l10n = AppLocalizations.of(context)!;
    final cnicErr = PakistaniValidators.validateCnic(_cnicController.text);
    if (cnicErr != null) {
      AppFeedback.showError(context, cnicErr);
      return;
    }
    if (_cnicFront == null || _cnicBack == null) {
      AppFeedback.showWarning(context, l10n.kycAttachBoth);
      return;
    }
    await cubit.submitKyc(
      userUid: widget.userUid,
      cnicNumber: _cnicController.text.trim(),
      cnicFront: _cnicFront,
      cnicBack: _cnicBack,
      license: _licenseData.front,
      licenseBack: _licenseData.back,
      licenseNumber:
          _licenseData.number.trim().isEmpty ? null : _licenseData.number.trim(),
      licenseExpiry:
          _licenseData.expiry.trim().isEmpty ? null : _licenseData.expiry.trim(),
      qrCode: _qrCode.isEmpty ? null : _qrCode,
    );
  }

  String _fileName(File? file) =>
      file == null ? '' : file.path.split('/').last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<KycCubit, KycState>(
      listener: (context, state) {
        if (state is KycSubmitted) {
          widget.onSubmitted(_cnicController.text.trim());
        } else if (state is KycError) {
          AppFeedback.showError(context, state.message);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.kycCnicNumber,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge_outlined),
              hintText: '35202-1234567-1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanning ? null : _scanCnic,
              icon: const Icon(Icons.document_scanner_rounded, size: 18),
              label: Text(
                  _scanning ? l10n.kycScanning : l10n.kycScanCard),
            ),
          ),
          const SizedBox(height: 14),
          DocumentSlotTile(
            title: l10n.kycCnicFront,
            subtitle: _cnicFront != null
                ? l10n.kycSelectedFile(_fileName(_cnicFront))
                : l10n.kycHighResHint,
            // CU-M7: each slot reports its OWN stored document — the
            // old `widget.existing != null` marked BOTH slots uploaded
            // as soon as any submission existed, even a partial one.
            isUploaded: _cnicFront != null ||
                (widget.existing?.cnicFrontKey.isNotEmpty ?? false),
            onTap: () => _pickSlot('front'),
          ),
          const SizedBox(height: 10),
          DocumentSlotTile(
            title: l10n.kycCnicBack,
            subtitle: _cnicBack != null
                ? l10n.kycSelectedFile(_fileName(_cnicBack))
                : l10n.kycQrHint,
            isUploaded: _cnicBack != null ||
                (widget.existing?.cnicBackKey.isNotEmpty ?? false),
            onTap: () => _pickSlot('back'),
          ),
          const SizedBox(height: 10),
          KycLicenseSection(
            data: _licenseData,
            existing: widget.existing,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          BlocBuilder<KycCubit, KycState>(
            builder: (context, state) {
              final uploading = state is KycUploading;
              return DebouncedButton(
                text: uploading ? l10n.kycUploading : l10n.kycSubmit,
                icon: Icons.cloud_upload_rounded,
                isLoading: uploading,
                onPressed: () => _submit(context.read<KycCubit>()),
              );
            },
          ),
        ],
      ),
    );
  }
}
