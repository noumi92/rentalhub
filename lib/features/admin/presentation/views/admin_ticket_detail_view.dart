import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/ticket_thread_panel.dart';

/// Phase 2 (2.4) — one support ticket as a route, like the shop,
/// customer, booking and KYC detail routes: the inbox navigates here
/// instead of opening the detail sheet, so a ticket is deep-linkable
/// and the back button returns to the inbox. The thread itself is
/// [TicketThreadPanel] (shared with the sheet); closing or escalating
/// reloads the ticket instead of popping.
class AdminTicketDetailView extends StatefulWidget {
  const AdminTicketDetailView({super.key, required this.ticketId, this.loadTicket});

  final String ticketId;

  /// Test seam (data access). Defaults read the real data source;
  /// tests pass a fake so no Firebase/DI is needed.
  final Future<SupportTicket?> Function(String ticketId)? loadTicket;

  @override
  State<AdminTicketDetailView> createState() => _AdminTicketDetailViewState();
}

class _AdminTicketDetailViewState extends State<AdminTicketDetailView> {
  SupportTicket? _ticket;
  bool _isLoading = true;
  bool _hasError = false;
  final _threadController = TicketThreadController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final ticket = await (widget.loadTicket?.call(widget.ticketId) ??
          sl<AdminSupportDataSource>().getTicket(widget.ticketId));
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final ticket = _ticket;
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminTickets,
      title: ticket == null
          ? l10n.admin2_ticketsTitle
          : l10n.admin2_ticketTitle(ticket.id),
      subtitle: l10n.admin2_ticketsSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminTickets),
      // Phase 4 (4.4a) — Close / Escalate are the sticky bar now
      // (a closed ticket has nothing left to decide).
      bottomBar: ticket == null || ticket.status == 'closed'
          ? null
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _threadController.escalate(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    child: Text(l10n.admin2_ticketEscalate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _threadController.close(),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    child: Text(l10n.admin2_ticketClose),
                  ),
                ),
              ],
            ),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_ticketsLoadFailed,
                  onRetry: _load,
                )
              : ticket == null
                  ? AppEmptyState(title: l10n.admin2_ticketDetailNotFound)
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 16 : 24),
                      child: TicketThreadPanel(
                        ticket: ticket,
                        onChanged: _load,
                        popAfterClose: false,
                        popBeforeCustomerNavigation: false,
                        controller: _threadController,
                        showStatusButtons: false,
                      ),
                    ),
    );
  }
}
