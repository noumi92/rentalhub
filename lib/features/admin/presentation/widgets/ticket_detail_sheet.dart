import 'package:flutter/material.dart';

import '../../data/datasources/admin_support_data_source.dart';
import 'ticket_thread_panel.dart';

/// The E1 ticket thread sheet — a thin wrapper: the thread itself is
/// [TicketThreadPanel], shared with the ticket detail route (Phase 2,
/// 2.4), so the sheet and the route never drift. The sheet keeps the
/// drag handle and the pop-on-close behaviour; the detail route keeps
/// the panel on screen and reloads instead.
class TicketDetailSheet extends StatelessWidget {
  const TicketDetailSheet({
    super.key,
    required this.ticket,
    required this.onChanged,
  });

  final SupportTicket ticket;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: TicketThreadPanel(ticket: ticket, onChanged: onChanged),
      ),
    );
  }
}
