import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit item 4 (O19 2/2): the handover checklist — Documents Given
/// (Registration, Insurance), Accessories (Spare Tyre, Jack, Tool
/// Kit) and the Keys Handed Over toggle. Pure display + callbacks;
/// the owning view holds the sets and persists them with the
/// handover record.
class HandoverChecklistSection extends StatelessWidget {
  final Set<String> documentsGiven;
  final Set<String> accessories;
  final bool keysHandedOver;
  final ValueChanged<Set<String>> onDocumentsChanged;
  final ValueChanged<Set<String>> onAccessoriesChanged;
  final ValueChanged<bool> onKeysChanged;

  const HandoverChecklistSection({
    super.key,
    required this.documentsGiven,
    required this.accessories,
    required this.keysHandedOver,
    required this.onDocumentsChanged,
    required this.onAccessoriesChanged,
    required this.onKeysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, l10n.handoverDocumentsTitle),
          _checkRow(
            context,
            label: l10n.handoverDocumentRegistration,
            value: documentsGiven.contains('registration'),
            onChanged: (v) => onDocumentsChanged(
                _toggled(documentsGiven, 'registration', v)),
          ),
          _checkRow(
            context,
            label: l10n.handoverDocumentInsurance,
            value: documentsGiven.contains('insurance'),
            onChanged: (v) => onDocumentsChanged(
                _toggled(documentsGiven, 'insurance', v)),
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, l10n.handoverAccessoriesTitle),
          _checkRow(
            context,
            label: l10n.handoverAccessorySpareTyre,
            value: accessories.contains('spare_tyre'),
            onChanged: (v) => onAccessoriesChanged(
                _toggled(accessories, 'spare_tyre', v)),
          ),
          _checkRow(
            context,
            label: l10n.handoverAccessoryJack,
            value: accessories.contains('jack'),
            onChanged: (v) =>
                onAccessoriesChanged(_toggled(accessories, 'jack', v)),
          ),
          _checkRow(
            context,
            label: l10n.handoverAccessoryToolKit,
            value: accessories.contains('tool_kit'),
            onChanged: (v) => onAccessoriesChanged(
                _toggled(accessories, 'tool_kit', v)),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.handoverKeysTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              value: keysHandedOver,
              onChanged: onKeysChanged,
            ),
          ),
        ],
      ),
    );
  }

  Set<String> _toggled(Set<String> set, String value, bool? on) {
    final next = Set<String>.from(set);
    if (on == true) {
      next.add(value);
    } else {
      next.remove(value);
    }
    return next;
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _checkRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    // A ListTile inside the section's decorated Container asserts in
    // debug builds (its ink effects would be hidden by the
    // DecoratedBox) — give each tile its own transparent Material.
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(label,
            style: Theme.of(context).textTheme.bodyMedium),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
