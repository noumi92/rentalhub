import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/pakistani_validators.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../cubit/kyc_cubit.dart';
import '../../../data/services/cnic_ocr_service.dart';
import '../../../domain/entities/kyc_document_entity.dart';
import 'document_slot_tile.dart';
import 'pick_image_source.dart';

/// G3: the KYC submission form — the CNIC field (prefilled from the
/// customer's real record), the on-device CNIC scan, the three document
/// slots holding photos the customer actually picks, and the real
/// submit through KycCubit. Extracted from [CustomerDocumentsView] so
/// the view stays under the 250-line cap.
class KycSubmissionForm extends StatefulWidget {
  const KycSubmissionForm({
    super.key,
    required this.initialCnic,
    required this.existing,
    required this.userUid,
    required this.onSubmitted,
  });

  final String initialCnic;
  final KycDocumentEntity? existing;
  final String userUid;
  final void Function(String cnic) onSubmitted;

  @override
  State<KycSubmissionForm> createState() => _KycSubmissionFormState();
}

class _KycSubmissionFormState extends State<KycSubmissionForm> {
  late final TextEditingController _cnicController;
  File? _cnicFront;
  File? _cnicBack;
  File? _license;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _cnicController = TextEditingController(text: widget.initialCnic);
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
      } else if (slot == 'back') {
        _cnicBack = file;
      } else {
        _license = file;
      }
    });
  }

  // Scans the CNIC front with on-device OCR and fills the number; the
  // scanned photo becomes the front-side file.
  Future<void> _scanCnic() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
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
        AppFeedback.showSuccess(context, 'CNIC number read from the card.');
      } else {
        AppFeedback.showWarning(
          context,
          'Could not read a CNIC number from that photo — please type it.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'CNIC scan failed: $e');
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _submit(KycCubit cubit) async {
    final cnicErr = PakistaniValidators.validateCnic(_cnicController.text);
    if (cnicErr != null) {
      AppFeedback.showError(context, cnicErr);
      return;
    }
    if (_cnicFront == null || _cnicBack == null) {
      AppFeedback.showWarning(
        context,
        'Please attach both front and back photos of your NADRA CNIC.',
      );
      return;
    }
    await cubit.submitKyc(
      userUid: widget.userUid,
      cnicNumber: _cnicController.text.trim(),
      cnicFront: _cnicFront,
      cnicBack: _cnicBack,
      license: _license,
    );
  }

  String _fileName(File? file) =>
      file == null ? '' : file.path.split('/').last;

  @override
  Widget build(BuildContext context) {
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
            '13-Digit NADRA CNIC Number',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
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
                  _scanning ? 'Scanning card...' : 'Scan CNIC card'),
            ),
          ),
          const SizedBox(height: 14),
          DocumentSlotTile(
            title: 'NADRA CNIC — Front Side',
            subtitle: _cnicFront != null
                ? 'Selected: ${_fileName(_cnicFront)}'
                : 'High-resolution scan with clear photo',
            isUploaded:
                _cnicFront != null || widget.existing != null,
            onTap: () => _pickSlot('front'),
          ),
          const SizedBox(height: 10),
          DocumentSlotTile(
            title: 'NADRA CNIC — Back Side',
            subtitle: _cnicBack != null
                ? 'Selected: ${_fileName(_cnicBack)}'
                : 'QR code & address clearly visible',
            isUploaded: _cnicBack != null || widget.existing != null,
            onTap: () => _pickSlot('back'),
          ),
          const SizedBox(height: 10),
          DocumentSlotTile(
            title: 'Valid Pakistan Driving License (LTV/HTV)',
            subtitle: _license != null
                ? 'Selected: ${_fileName(_license)}'
                : 'Required for Self-Drive rental packages',
            isUploaded: _license != null || widget.existing != null,
            onTap: () => _pickSlot('license'),
          ),
          const SizedBox(height: 18),
          BlocBuilder<KycCubit, KycState>(
            builder: (context, state) {
              final uploading = state is KycUploading;
              return DebouncedButton(
                text: uploading ? 'Uploading...' : 'Submit KYC Documents',
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
