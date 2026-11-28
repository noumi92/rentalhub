import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../auth/presentation/views/widgets/profile_avatar_picker.dart';
import '../../../../l10n/app_localizations.dart';

/// The values the edit-profile flow collects.
class EditProfileData {
  const EditProfileData({
    required this.name,
    required this.phone,
    required this.cnic,
    required this.dateOfBirth,
    required this.fatherName,
    required this.address,
    required this.photoFile,
  });

  final String name;
  final String phone;
  final String cnic;
  final String dateOfBirth;
  final String fatherName;
  final String address;
  final File? photoFile;
}

/// Profile hub (2026-11-25): the full edit-profile form — name,
/// phone, CNIC, date of birth, father's name, address and profile
/// photo. It replaces the old edit-profile sheet (name/phone/CNIC only).
/// The caller saves the values; this form only collects and
/// validates them.
///
/// A CNIC change on a verified record shows the re-review warning:
/// the save flags the KYC record for re-review instead of silently
/// diverging the two CNIC sources (see the edit view).
class EditProfileForm extends StatefulWidget {
  const EditProfileForm({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.initialCnic,
    required this.initialDateOfBirth,
    required this.initialFatherName,
    required this.initialAddress,
    required this.initialPhotoUrl,
    required this.kycVerified,
    required this.onSave,
  });

  final String initialName;
  final String initialPhone;
  final String initialCnic;
  final String initialDateOfBirth;
  final String initialFatherName;
  final String initialAddress;
  final String? initialPhotoUrl;
  final bool kycVerified;
  final Future<void> Function(EditProfileData data) onSave;

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  late final TextEditingController _dobController;
  late final TextEditingController _fatherController;
  late final TextEditingController _addressController;
  File? _photoFile;
  bool _saving = false;

  bool get _cnicChanged =>
      _cnicController.text.trim() != widget.initialCnic.trim();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _cnicController = TextEditingController(text: widget.initialCnic);
    _dobController =
        TextEditingController(text: widget.initialDateOfBirth);
    _fatherController =
        TextEditingController(text: widget.initialFatherName);
    _addressController =
        TextEditingController(text: widget.initialAddress);
    _cnicController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _dobController.dispose();
    _fatherController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showError(context, l10n.editEnterName);
      return;
    }
    final phoneErr = PakistaniValidators.validatePakistaniPhone(phone);
    if (phoneErr != null) {
      AppFeedback.showError(context, phoneErr);
      return;
    }
    if (cnic.isNotEmpty) {
      final cnicErr = PakistaniValidators.validateCnic(cnic);
      if (cnicErr != null) {
        AppFeedback.showError(context, cnicErr);
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(EditProfileData(
        name: name,
        phone: phone,
        cnic: cnic,
        dateOfBirth: _dobController.text.trim(),
        fatherName: _fatherController.text.trim(),
        address: _addressController.text.trim(),
        photoFile: _photoFile,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppFeedback.showError(context, l10n.editSaveError(e.toString()));
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 25, now.month, now.day);
    final parts = _dobController.text.trim().split(RegExp(r'[./-]'));
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null && y >= 1900 && y <= now.year) {
        initial = DateTime(y, m, d);
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null && mounted) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      _dobController.text = '$dd.$mm.${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ProfileAvatarPicker(
            imageFile: _photoFile,
            imageUrl: widget.initialPhotoUrl,
            onImagePicked: (file) => setState(() => _photoFile = file),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.editFullName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.editPhone,
            hintText: '03xx-xxxxxxx',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cnicController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.editCnicOptional,
            hintText: '35202-1234567-1',
          ),
        ),
        if (widget.kycVerified &&
            widget.initialCnic.isNotEmpty &&
            _cnicChanged) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.editCnicReReviewWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _dobController,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.editDateOfBirth,
            hintText: 'dd.mm.yyyy',
            suffixIcon: IconButton(
              tooltip: l10n.editDateOfBirth,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              onPressed: _pickDateOfBirth,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fatherController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.editFatherName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          maxLines: 2,
          decoration: InputDecoration(labelText: l10n.editAddress),
        ),
        const SizedBox(height: 18),
        DebouncedButton(
          text: _saving ? l10n.editSaving : l10n.editSaveProfile,
          icon: Icons.check_rounded,
          isLoading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
