import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';


/// Phase B (F1): the damage noted when the car left, shown at return
/// so the owner only charges for damage that is new.
class HandoverNotesBanner extends StatelessWidget {
  final List<String> notes;

  const HandoverNotesBanner({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        l10n.handoverNotedAt(notes.join('; ')),
        style:
            Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
