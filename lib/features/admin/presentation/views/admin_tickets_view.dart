import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/ticket_detail_sheet.dart';

/// Phase E (E1) — the support tickets inbox: every ticket the
/// customer form wrote, with its SLA countdown (High 1 h, Medium
/// 4 h, Low 24 h). Tap a ticket for the thread — replies, internal
/// notes, quick replies, Close / Escalate.
class AdminTicketsView extends StatefulWidget {
  const AdminTicketsView({super.key});

  @override
  State<AdminTicketsView> createState() => _AdminTicketsViewState();
}

class _AdminTicketsViewState extends State<AdminTicketsView> {
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tickets = await sl<AdminSupportDataSource>()
        .getTickets(status: _filter);
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: RouteNames.adminTickets,
      title: 'Support tickets',
      subtitle: 'The inbox the customer plan promised',
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in {
                    'all': 'All',
                    'open': 'Open',
                    'in_progress': 'In progress',
                    'escalated': 'Escalated',
                    'closed': 'Closed',
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) {
                        setState(() {
                          _filter = entry.key;
                          _isLoading = true;
                        });
                        _load();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tickets.isEmpty
                      ? const Center(
                          child: Text(
                            'No tickets — the inbox reads the support_tickets collection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _tickets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final t = _tickets[i];
                            final breached = t.createdAt != null &&
                                DateTime.now().isAfter(t.createdAt!
                                    .add(Duration(hours: t.slaHours)));
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: breached
                                        ? Colors.red.shade300
                                        : AppColors.borderSubtle),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: const Icon(
                                      Icons.support_agent_rounded,
                                      color: AppColors.primary),
                                ),
                                title: Text(
                                    t.message.length > 80
                                        ? '${t.message.substring(0, 80)}…'
                                        : t.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                                subtitle: Text(
                                  '${t.priority.toUpperCase()} • ${t.status} • ${t.slaText()}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: breached
                                          ? Colors.red.shade700
                                          : AppColors.textMuted,
                                      fontWeight: breached
                                          ? FontWeight.w700
                                          : FontWeight.normal),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16),
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => TicketDetailSheet(
                                    ticket: t,
                                    onChanged: _load,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
