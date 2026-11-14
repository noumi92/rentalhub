import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/announcement_form_sheet.dart';

/// Phase E (E3) — announcements: broadcasts to owners/customers by
/// audience (role, city, plan), authored in English and Urdu, Push
/// and/or WhatsApp, scheduled or sent now, with a send-test that
/// delivers only to the calling admin's own device. History shows
/// the real sent count; delivered/opened stay 0 until the app
/// reports them.
class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() =>
      _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  List<AdminAnnouncement> _announcements = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final list = await sl<AdminSupportDataSource>().getAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send(AdminAnnouncement a, {required bool test}) async {
    final result = await sl<AdminSupportDataSource>().sendAnnouncement(
      announcementId: a.id,
      test: test,
    );
    if (!mounted) return;
    if (result != null) {
      AppFeedback.showSuccess(
          context, result['message'] as String? ?? 'Sent.');
      await _load();
    } else {
      AppFeedback.showError(
          context, 'Could not reach the Functions server — try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminAnnouncements,
      title: 'Announcements',
      subtitle: 'Broadcasts to owners and customers',
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AnnouncementFormSheet(onCreated: _load),
                ),
                icon: const Icon(Icons.campaign_rounded, size: 18),
                label: const Text('New announcement'),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: 'Could not load the announcements.',
                          onRetry: _load,
                        )
                      : _announcements.isEmpty
                          ? const AppEmptyState(
                              title: 'No announcements yet',
                              message: 'Create the first one above.',
                            )
                          : ListView.separated(
                          itemCount: _announcements.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final a = _announcements[i];
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(a.titleEn,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            )),
                                    const SizedBox(height: 4),
                                    Text(a.bodyEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${a.audienceRole} • ${a.audienceCity} • ${a.audiencePlan} • ${a.channel} • ${a.status} • Sent ${a.sent} • Delivered ${a.delivered} • Opened ${a.opened}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () =>
                                              _send(a, test: true),
                                          style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size(0, 48)),
                                          child: const Text('Send test'),
                                        ),
                                        FilledButton(
                                          onPressed: a.status == 'sent'
                                              ? null
                                              : () => _send(a, test: false),
                                          style: FilledButton.styleFrom(
                                              minimumSize:
                                                  const Size(0, 48)),
                                          child: const Text('Send now'),
                                        ),
                                      ],
                                    ),
                                  ],
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
