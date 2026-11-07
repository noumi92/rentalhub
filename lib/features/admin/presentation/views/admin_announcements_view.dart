import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await sl<AdminSupportDataSource>().getAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = list;
        _isLoading = false;
      });
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
    return AdminShell(
      activeRoute: RouteNames.adminAnnouncements,
      title: 'Announcements',
      subtitle: 'Broadcasts to owners and customers',
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _announcements.isEmpty
                      ? const Center(
                          child: Text(
                            'No announcements yet — create the first one above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted),
                          ),
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
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: AppColors.borderSubtle),
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
                                            color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Text(a.bodyEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${a.audienceRole} • ${a.audienceCity} • ${a.audiencePlan} • ${a.channel} • ${a.status} • Sent ${a.sent} • Delivered ${a.delivered} • Opened ${a.opened}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () =>
                                              _send(a, test: true),
                                          child: const Text('Send test'),
                                        ),
                                        FilledButton(
                                          onPressed: a.status == 'sent'
                                              ? null
                                              : () => _send(a, test: false),
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
