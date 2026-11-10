import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_support_data_source.dart';

/// The E1 ticket thread: the customer's message, the reply thread
/// (admin replies — customer-visible once a customer thread view
/// exists), internal notes (never shown to the customer), quick
/// replies, and Close / Escalate.
class TicketDetailSheet extends StatefulWidget {
  const TicketDetailSheet({
    super.key,
    required this.ticket,
    required this.onChanged,
  });

  final SupportTicket ticket;
  final VoidCallback onChanged;

  @override
  State<TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<TicketDetailSheet> {
  final _replyController = TextEditingController();
  final _noteController = TextEditingController();
  List<TicketMessage> _replies = [];
  List<TicketMessage> _notes = [];
  bool _isWorking = false;

  static const _quickReplies = [
    'Thanks for reaching out — we are looking into this and will update you on WhatsApp.',
    'Could you share the booking ID and a photo of the issue?',
    'This has been resolved. Please let us know if it comes back.',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ds = sl<AdminSupportDataSource>();
    final replies = await ds.getTicketReplies(widget.ticket.id);
    final notes = await ds.getTicketNotes(widget.ticket.id);
    if (mounted) {
      setState(() {
        _replies = replies;
        _notes = notes;
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().replyToTicket(
      ticketId: widget.ticket.id,
      text: text,
    );
    if (!mounted) return;
    if (synced) {
      _replyController.clear();
      await _load();
      widget.onChanged();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
    }
    setState(() => _isWorking = false);
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().addTicketNote(
      ticketId: widget.ticket.id,
      text: text,
    );
    if (!mounted) return;
    if (synced) {
      _noteController.clear();
      await _load();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
    }
    setState(() => _isWorking = false);
  }

  Future<void> _setStatus(String status) async {
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().setTicketStatus(
      ticketId: widget.ticket.id,
      status: status,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, 'Ticket $status.');
      widget.onChanged();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket ${t.id}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    )),
            const SizedBox(height: 4),
            Text(
                '${t.priority.toUpperCase()} • ${t.status} • ${t.slaText()}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(t.message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(
                RouteNames.adminCustomerDetail
                    .replaceFirst(':customerId', t.customerId),
              ),
              child: const Text('Open the customer'),
            ),
            const SizedBox(height: 12),
            const Text('Replies',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 6),
            if (_replies.isEmpty)
              Text('No replies yet.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ..._replies.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${r.authorRole}: ${r.text}',
                      style: const TextStyle(fontSize: 13)),
                )),
            const SizedBox(height: 12),
            const Text('Quick replies',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 6),
            // Compact-safe: a Wrap of long quick-reply chips overflows
            // at 360px (a chip takes its label's intrinsic width). A
            // full-width column lets each label wrap instead.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _quickReplies
                  .map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ActionChip(
                          label: Text(q,
                              softWrap: true,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () =>
                              _replyController.text = q,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _replyController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reply to the customer…',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isWorking ? null : _sendReply,
                child: const Text('Send reply'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Internal notes (the customer never sees these)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 6),
            ..._notes.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• ${n.text}',
                      style: const TextStyle(fontSize: 13)),
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Add an internal note…',
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isWorking ? null : _addNote,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isWorking ? null : () => _setStatus('escalated'),
                    child: const Text('Escalate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isWorking ? null : () => _setStatus('closed'),
                    child: const Text('Close ticket'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
