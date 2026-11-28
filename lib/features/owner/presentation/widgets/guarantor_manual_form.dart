import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/cnic_input_formatter.dart';
import '../../../../core/widgets/profile_signature_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../views/add_customer/kyc_draft.dart';

/// Manual guarantor form fields extracted from [Step4Guarantor] so the
/// wizard step view stays strictly under the 250-line cap.
class GuarantorManualForm extends StatelessWidget {
  final KycDraft draft;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cnicController;
  final TextEditingController addressController;
  final List<String> relations;
  final Map<String, String> relationLabels;
  final VoidCallback onChanged;

  const GuarantorManualForm({
    super.key,
    required this.draft,
    required this.nameController,
    required this.phoneController,
    required this.cnicController,
    required this.addressController,
    required this.relations,
    required this.relationLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _input(
          context,
          key: const ValueKey('guarantor_name_field'),
          controller: nameController,
          label: l10n.guarantorNameLabel,
          icon: Icons.person_outline_rounded,
          onChanged: (v) {
            draft.guarantorName = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _input(
          context,
          key: const ValueKey('guarantor_phone_field'),
          controller: phoneController,
          label: l10n.guarantorPhoneLabel,
          icon: Icons.phone_outlined,
          keyboard: TextInputType.phone,
          onChanged: (v) {
            draft.guarantorPhone = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _input(
          context,
          key: const ValueKey('guarantor_cnic_field'),
          controller: cnicController,
          label: l10n.guarantorCnicLabel,
          hint: '35201-1234567-1',
          icon: Icons.badge_outlined,
          keyboard: TextInputType.number,
          formatters: const [CnicInputFormatter()],
          onChanged: (v) {
            draft.guarantorCnic = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const ValueKey('guarantor_manual_relation'),
          decoration: InputDecoration(
            labelText: l10n.kycWizardRelation,
            prefixIcon: const Icon(Icons.group_outlined),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          initialValue: draft.guarantorRelation,
          items: relations
              .map((r) =>
                  DropdownMenuItem(value: r, child: Text(relationLabels[r]!)))
              .toList(),
          onChanged: (v) {
            draft.guarantorRelation = v ?? 'Friend';
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        _input(
          context,
          key: const ValueKey('guarantor_address_field'),
          controller: addressController,
          label: l10n.guarantorAddressLabel,
          icon: Icons.location_on_outlined,
          onChanged: (v) {
            draft.guarantorAddress = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        ProfileSignatureCard(
          key: const ValueKey('guarantor_manual_signature_card'),
          title: l10n.agreementWizardGuarantor,
          initialPng: draft.guarantorSignaturePng,
          onSave: (bytes) async {
            draft.guarantorSignaturePng = bytes;
            onChanged();
            return true;
          },
        ),
      ],
    );
  }

  Widget _input(
    BuildContext context, {
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      onChanged: onChanged,
    );
  }
}
