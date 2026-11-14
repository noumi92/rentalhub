import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_shell.dart';
import '../widgets/announcement_form_sheet.dart';

/// Phase E (E3) — announcements: broadcasts to owners/customers by
/// audience (role, city, plan), authored in English and Urdu, Push
/// and/or WhatsApp, scheduled or sent now, with a send-test that
/// delivers only to the calling admin's own device. History shows
/// the real sent count and the real opened count (the announcement
/// detail screen reports an open); delivered is labelled "not
/// tracked yet" — FCM delivery receipts are not reported, and the
/// count is never estimated.
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
    // F-C1: super admin + operations only (managePlatform). See
    // the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    final result = await sl<AdminSupportDataSource>().sendAnnouncement(
      announcementId: a.id,
      test: test,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (result != null) {
      AppFeedback.showSuccess(context,
          result['message'] as String? ?? (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_anncSent);
      await _load();
    } else {
      AppFeedback.showError(context,
          (AppLocalizations.of(context) ?? AppLocalizationsEn()).admin2_anncSendFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminAnnouncements,
      title: l10n.admin2_navAnnouncements,
      subtitle: l10n.admin2_anncSubtitle,
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
                label: Text(l10n.admin2_anncNew),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_anncLoadFailed,
                          onRetry: _load,
                        )
                      : _announcements.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_anncEmptyTitle,
                              message: l10n.admin2_anncEmptyHint,
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
                                            )),
                                    const SizedBox(height: 4),
                                    Text(a.bodyEn,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    // AD-m11: the authored Urdu copy was
                                    // never previewed — show it under the
                                    // English so the admin can check it.
                                    if (a.titleUr.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(a.titleUr,
                                          textDirection: TextDirection.rtl,
                                          style: const TextStyle(
                                              fontSize: 14)),
                                    ],
                                    if (a.bodyUr.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(a.bodyUr,
                                          textDirection: TextDirection.rtl,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      '${a.audienceRole} • ${a.audienceCity} • ${a.audiencePlan} • ${a.channel} • ${a.status} • ${l10n.admin2_anncSentCount(a.sent)} • ${l10n.adminAnncDeliveredNotTracked} • ${l10n.admin2_anncOpenedCount(a.opened)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton(
                                          // AD-m20: no test send on an
                                          // already-sent announcement.
                                          onPressed: a.status == 'sent'
                                              ? null
                                              : () => _send(a, test: true),
                                          style: OutlinedButton.styleFrom(
                                              minimumSize:
                                                  const Size(0, 48)),
                                          child: Text(l10n.admin2_anncSendTest),
                                        ),
                                        FilledButton(
                                          // F-M14: a `pending_whatsapp`
                                          // announcement already had its
                                          // push delivered — "Send now"
                                          // would push-notify everyone a
                                          // second time. Only drafts and
                                          // scheduled (due) announcements
                                          // can be sent.
                                          onPressed: a.status == 'sent' ||
                                                  a.status ==
                                                      'pending_whatsapp'
                                              ? null
                                              : () => _send(a, test: false),
                                          style: FilledButton.styleFrom(
                                              minimumSize:
                                                  const Size(0, 48)),
                                          child: Text(l10n.admin2_anncSendNow),
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
