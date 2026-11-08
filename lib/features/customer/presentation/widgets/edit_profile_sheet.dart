import 'package:flutter/material.dart';

import '../../../../core/utils/pakistani_validators.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';

/// H1: the edit-profile sheet — name, phone and CNIC with validation.
/// The caller saves the values (the `customers` record + the Auth
/// display name); this sheet only collects and validates them.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.initialCnic,
    required this.onSave,
  });

  final String initialName;
  final String initialPhone;
  final String initialCnic;
  final Future<void> Function({
    required String name,
    required String phone,
    required String cnic,
  }) onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _cnicController = TextEditingController(text: widget.initialCnic);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
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
      await widget.onSave(name: name, phone: phone, cnic: cnic);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppFeedback.showError(context, l10n.editSaveError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.editProfile,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration:  InputDecoration(labelText: l10n.editFullName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration:  InputDecoration(
              labelText: l10n.editPhone,
              hintText: '03xx-xxxxxxx',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            decoration:  InputDecoration(
              labelText: l10n.editCnicOptional,
              hintText: '35202-1234567-1',
            ),
          ),
          const SizedBox(height: 18),
          DebouncedButton(
            text: _saving ? l10n.editSaving : l10n.editSaveProfile,
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
