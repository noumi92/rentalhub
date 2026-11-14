import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../domain/admin_permissions.dart';
import 'admin_permission_check.dart';
import 'admin_status_chip.dart';
import 'ticket_linked_info.dart';

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
  // AD-M7: the thread load has its own loading/error state — a
  // failure must never read as "No replies yet".
  bool _isLoadingReplies = true;
  bool _hasError = false;

  // AD-m22: the old wording promised a WhatsApp update the
  // platform cannot send yet (gated on D2) — the customer is
  // updated here, in the ticket thread, until WhatsApp exists.
  List<String> _quickReplies(AppLocalizations l10n) => [
        l10n.admin2_ticketQuickReply1,
        l10n.admin2_ticketQuickReply2,
        l10n.admin2_ticketQuickReply3,
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
    if (mounted) setState(() => _hasError = false);
    try {
      final ds = sl<AdminSupportDataSource>();
      final replies = await ds.getTicketReplies(widget.ticket.id);
      final notes = await ds.getTicketNotes(widget.ticket.id);
      if (mounted) {
        setState(() {
          _replies = replies;
          _notes = notes;
          _isLoadingReplies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoadingReplies = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    // F-C1: replying is triage (triageTicket — every admin role).
    // See the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.triageTicket);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().replyToTicket(
      ticketId: widget.ticket.id,
      text: text,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      _replyController.clear();
      await _load();
      widget.onChanged();
    } else {
      AppFeedback.showError(
          context, (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_serverUnreachable);
    }
    setState(() => _isWorking = false);
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    // F-C1: an internal note is triage (triageTicket).
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.triageTicket);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().addTicketNote(
      ticketId: widget.ticket.id,
      text: text,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      _noteController.clear();
      await _load();
    } else {
      AppFeedback.showError(
          context, (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_serverUnreachable);
    }
    setState(() => _isWorking = false);
  }

  Future<void> _setStatus(String status) async {
    // F-C1: closing needs resolveTicket (super admin + operations
    // only); any other move is triage (triageTicket).
    final permission = status == 'closed'
        ? AdminPermission.resolveTicket
        : AdminPermission.triageTicket;
    final check =
        await AdminPermissionCheck.check(context, permission);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().setTicketStatus(
      ticketId: widget.ticket.id,
      status: status,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
      AppFeedback.showSuccess(context,
          l10n.admin2_ticketStatusDone(humanizeStatus(status, l10n)));
      widget.onChanged();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(
          context, (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_serverUnreachable);
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
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
            Text(l10n.admin2_ticketTitle(t.id),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 4),
            Text(
                '${t.priority.toUpperCase()} • ${humanizeStatus(t.status, l10n)} • ${t.slaTextL10n(l10n)}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(t.message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(
              // AD-M13: pop the sheet first, then navigate — a `go`
              // from inside the modal leaves the sheet covering the
              // customer detail screen.
              onPressed: () {
                final route = RouteNames.adminCustomerDetail
                    .replaceFirst(':customerId', t.customerId);
                Navigator.of(context).pop();
                context.go(route);
              },
              child: Text(l10n.admin2_ticketOpenCustomer),
            ),
            // F-M19: the linked shop / purchase, where the ticket
            // carries one — nothing renders for older tickets.
            TicketLinkedInfo(ticket: t),
            const SizedBox(height: 12),
            Text(l10n.admin2_ticketReplies,
                style: TextStyle(
                    fontSize: 14,
                    )),
            const SizedBox(height: 6),
            // AD-M7: loading spinner while the thread loads, an error
            // state with retry on failure, "No replies yet" only when
            // the load succeeded and the thread is genuinely empty.
            if (_isLoadingReplies)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_hasError)
              AppErrorState(
                message: AppLocalizations.of(context)
                        ?.admin2_ticketRepliesLoadFailed ??
                    'Could not load the replies.',
                onRetry: _load,
              )
            else if (_replies.isEmpty)
              Text(l10n.admin2_ticketNoReplies,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (!_isLoadingReplies && !_hasError)
              ..._replies.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${r.authorRole}: ${r.text}',
                        style: const TextStyle(fontSize: 13)),
                  )),
            const SizedBox(height: 12),
            Text(l10n.admin2_ticketQuickReplies,
                style: TextStyle(
                    fontSize: 14,
                    )),
            const SizedBox(height: 6),
            // Compact-safe: a Wrap of long quick-reply chips overflows
            // at 360px (a chip takes its label's intrinsic width). A
            // full-width column lets each label wrap instead.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _quickReplies(l10n)
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
                hintText: l10n.admin2_ticketReplyHint,
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
                // AD-M8: 48dp minimum touch target (rulebook §4.6).
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48)),
                child: Text(l10n.admin2_ticketSendReply),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.admin2_ticketInternalNotes,
                style: TextStyle(
                    fontSize: 14,
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
                      hintText: l10n.admin2_ticketAddNoteHint,
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
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_ticketAdd),
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
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    child: Text(l10n.admin2_ticketEscalate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isWorking ? null : () => _setStatus('closed'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    child: Text(l10n.admin2_ticketClose),
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
