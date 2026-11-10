import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';


/// Phase B (E2): the damage notes the owner records at handover.
/// Starts empty — the old flow hardcoded three notes, including a
/// scratch that may not exist on the car being handed over.
class HandoverDamageNotesEditor extends StatefulWidget {
  final List<String> initialNotes;
  final ValueChanged<List<String>> onChanged;
  final String? title;
  final String? subtitle;

  const HandoverDamageNotesEditor({
    super.key,
    this.initialNotes = const [],
    required this.onChanged,
    this.title,
    this.subtitle,
  });

  @override
  State<HandoverDamageNotesEditor> createState() =>
      _HandoverDamageNotesEditorState();
}

class _HandoverDamageNotesEditorState
    extends State<HandoverDamageNotesEditor> {
  final _controller = TextEditingController();
  late List<String> _notes;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    setState(() {
      _notes.add(note);
      _controller.clear();
    });
    widget.onChanged(List.unmodifiable(_notes));
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title ?? l10n.handoverDamageTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          Text(widget.subtitle ?? l10n.handoverDamageSubtitle,
              style:
                  Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          if (_notes.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _notes
                  .map((n) => Chip(
                        label: Text(n),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          setState(() => _notes.remove(n));
                          widget.onChanged(List.unmodifiable(_notes));
                        },
                      ))
                  .toList(),
            ),
          if (_notes.isNotEmpty) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: l10n.handoverDamageHint,
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _add, child: Text(l10n.handoverAdd)),
            ],
          ),
        ],
      ),
    );
  }
}
