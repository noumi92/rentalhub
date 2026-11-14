import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/dispute_decision_sheet.dart';

/// Phase D (D2) — the disputes centre: every dispute with its 72 h
/// SLA state. Tap one for the decision sheet (both statements, the
/// Full / Partial / Full-to-owner decision, the amount, the note).
class AdminDisputesView extends StatefulWidget {
  const AdminDisputesView({super.key});

  @override
  State<AdminDisputesView> createState() => _AdminDisputesViewState();
}

class _AdminDisputesViewState extends State<AdminDisputesView> {
  List<DisputeRecord> _disputes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final disputes = await sl<AdminPlatformDataSource>()
          .getDisputes(status: _filter);
      if (mounted) {
        setState(() {
          _disputes = disputes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _slaText(DisputeRecord d) {
    final created = d.createdAt;
    if (created == null) return 'SLA unknown';
    final left =
        created.add(const Duration(hours: 72)).difference(DateTime.now());
    if (left.isNegative) return 'SLA overdue by ${-left.inHours}h';
    return '${left.inHours}h of SLA left';
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminDisputes,
      title: 'Disputes centre',
      subtitle: 'Third side of every dispute — 72 h SLA',
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
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
                    'in_review': 'In review',
                    'resolved': 'Resolved',
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
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: 'Could not load the disputes.',
                          onRetry: _load,
                        )
                      : _disputes.isEmpty
                          ? const AppEmptyState(
                              title: 'No disputes',
                              message:
                                  'The centre reads the disputes collection.',
                            )
                          : ListView.separated(
                          itemCount: _disputes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final d = _disputes[i];
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: const Icon(Icons.gavel_rounded,
                                      ),
                                ),
                                title: Text(
                                    '${d.category} • ${d.bookingId}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        )),
                                subtitle: Text(
                                  '${d.description} — ${humanizeStatus(d.status)} • ${_slaText(d)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16),
                                onTap: d.status == 'resolved'
                                    ? null
                                    : () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) =>
                                              DisputeDecisionSheet(
                                            dispute: d,
                                            onDecided: _load,
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
