import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// RQ-F9: the manual WhatsApp-confirmation toggle on the
/// manual-booking confirm step. Extracted from
/// `OwnerManualBookingConfirmView` so the view stays under the
/// 250-line cap (rulebook §2.2).
///
/// OFF by default; when ON, confirming opens the owner's WhatsApp
/// with the confirmation already written — the owner taps send,
/// nothing auto-sends.
class ManualBookingWhatsappToggle extends StatelessWidget {
  const ManualBookingWhatsappToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(l10n.manualBookingWhatsappToggle,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      secondary: const Icon(Icons.chat_rounded),
    );
  }
}
