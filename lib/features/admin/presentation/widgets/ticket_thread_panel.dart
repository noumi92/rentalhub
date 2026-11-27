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
import 'admin_confirm_dialog.dart';
import 'admin_permission_check.dart';
import 'admin_status_chip.dart';
import 'ticket_linked_info.dart';

/// Phase 2 (2.4) — the ticket thread, extracted from
/// [TicketDetailSheet] so the same thread serves the ticket detail
/// route: the customer's message, the reply thread (admin replies —
/// customer-visible once a customer thread view exists), internal
/// notes (never shown to the customer), quick replies, and Close /
/// Escalate.
///
/// The panel is scroll-view agnostic: the sheet wraps it in a
/// [DraggableScrollableSheet], the detail route in a
/// [SingleChildScrollView]. Inside the sheet, closing a ticket pops
/// back to the inbox and opening the customer pops first
/// ([popAfterClose]/[popBeforeCustomerNavigation]); on the detail
/// route both stay false — the route reloads the ticket instead and
/// navigates directly.
/// Phase 4 (4.4a) — lets the detail route drive the panel's
/// Close / Escalate from its sticky action bar: the panel
/// registers them here, and the route's bar calls [close] /
/// [escalate].
class TicketThreadController {
  Future<void> Function()? _close;
  Future<void> Function()? _escalate;

  Future<void> close() async => await _close?.call();
  Future<void> escalate() async => await _escalate?.call();
}

class TicketThreadPanel extends StatefulWidget {
  const TicketThreadPanel({
    super.key,
    required this.ticket,
    required this.onChanged,
    this.popAfterClose = true,
    this.popBeforeCustomerNavigation = true,
    this.controller,
    this.showStatusButtons = true,
  });

  final SupportTicket ticket;
  final VoidCallback onChanged;

  /// True inside the sheet (closing pops back to the inbox); false
  /// on the detail route (the route reloads the closed ticket).
  final bool popAfterClose;

  /// The detail route's controller (see [TicketThreadController]).
  final TicketThreadController? controller;

  /// False on the detail route, where the sticky action bar holds
  /// the Close / Escalate buttons instead.
  final bool showStatusButtons;

  /// True inside the sheet (AD-M13: pop the sheet first, then
  /// navigate — a `go` from inside the modal leaves the sheet
  /// covering the customer detail screen); false on the route.
  final bool popBeforeCustomerNavigation;

  @override
  State<TicketThreadPanel> createState() => _TicketThreadPanelState();
}

class _TicketThreadPanelState extends State<TicketThreadPanel> {
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
    widget.controller?._close = () => _setStatus('closed');
    widget.controller?._escalate = () => _setStatus('escalated');
    _load();
  }

  @override
  void dispose() {
    if (widget.controller?._close != null) {
      widget.controller?._close = null;
      widget.controller?._escalate = null;
    }
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
    if (!mounted) return;
    // Phase 1 (1.1): close and escalate used to fire on one tap —
    // confirm the move first.
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final confirmed = await showAdminConfirmDialog(
      context,
      title: status == 'closed'
          ? l10n.admin2_ticketCloseConfirmTitle
          : l10n.admin2_ticketEscalateConfirmTitle,
      body: status == 'closed'
          ? l10n.admin2_ticketCloseConfirmBody
          : l10n.admin2_ticketEscalateConfirmBody,
    );
    if (!confirmed) return;
    if (!mounted) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminSupportDataSource>().setTicketStatus(
      ticketId: widget.ticket.id,
      status: status,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context,
          l10n.admin2_ticketStatusDone(humanizeStatus(status, l10n)));
      widget.onChanged();
      if (widget.popAfterClose) Navigator.of(context).pop();
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
    return Column(
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
          onPressed: () {
            final route = RouteNames.adminCustomerDetail
                .replaceFirst(':customerId', t.customerId);
            if (widget.popBeforeCustomerNavigation) {
              Navigator.of(context).pop();
            }
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
        if (widget.showStatusButtons)
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
    );
  }
}
