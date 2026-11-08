import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit §26 (extracted from [OwnerCashClosingView] so the view
/// stays under the 250-line cap): the counted-cash + note fields
/// and the save CTA. The counted field is digits-only with the
/// theme input border (radius 16) — "12.5" used to fail
/// `int.tryParse` with only a toast.
class CashClosingForm extends StatelessWidget {
  final TextEditingController countedController;
  final TextEditingController noteController;
  final bool isSaving;
  final VoidCallback onCountedChanged;
  final VoidCallback onSave;

  const CashClosingForm({
    super.key,
    required this.countedController,
    required this.noteController,
    required this.isSaving,
    required this.onCountedChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(16));
    return Column(
      children: [
        TextField(
          controller: countedController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onCountedChanged(),
          decoration: InputDecoration(
            labelText: l10n.financeClosingCountedLabel,
            border: border,
            filled: true,
            fillColor: fill,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: l10n.financeNoteOptional,
            border: border,
            filled: true,
            fillColor: fill,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: DebouncedButton(
            text: isSaving
                ? l10n.financeClosingSaving
                : l10n.financeClosingButton,
            icon: Icons.lock_rounded,
            isLoading: isSaving,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}
