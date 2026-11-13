import 'package:flutter/material.dart';

/// One on/off row of the finance settings form (payment methods,
/// auto-receipt). Extracted from `OwnerFinanceSettingsView` so the
/// view stays under the 250-line cap — five `SwitchListTile`s in
/// full take ~40 lines.
class FinanceSettingsSwitch extends StatelessWidget {
  const FinanceSettingsSwitch(
      {super.key,
      required this.title,
      this.subtitle,
      required this.value,
      required this.onChanged});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}
