import 'package:flutter/material.dart';

/// A titled list of lines, shared by the admin detail screens
/// (booking, customer, shop) and the reports screen, which all had
/// their own identical `_section` helper. When [lines] is empty and
/// [emptyText] is given, the empty text renders instead of nothing.
/// [muted] renders the lines in the secondary text colour (reports).
class AdminDetailSection extends StatelessWidget {
  const AdminDetailSection({
    super.key,
    required this.title,
    required this.lines,
    this.emptyText,
    this.muted = false,
  });

  final String title;
  final List<String> lines;
  final String? emptyText;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final shown = lines.isEmpty && emptyText != null ? [emptyText!] : lines;
    final lineColor =
        muted ? Theme.of(context).colorScheme.onSurfaceVariant : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...shown.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: TextStyle(fontSize: 13, color: lineColor)),
              )),
        ],
      ),
    );
  }
}
