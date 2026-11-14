import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One labelled field on the platform settings screen: filled,
/// radius 12, divider border — the same field style the admin lists
/// use for search. Number fields take [digitsOnly], so `7,500` can
/// never reach the save-time `int.tryParse` as an unparseable value
/// (the only feedback before was the generic "must be numbers" error).
/// [errorText] shows an AD-M12 range-validation error inline.
class AdminSettingsField extends StatelessWidget {
  const AdminSettingsField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.digitsOnly = false,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool digitsOnly;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
