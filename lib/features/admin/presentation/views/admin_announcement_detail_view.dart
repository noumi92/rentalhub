import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_detail_section.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_shell.dart';
import '../widgets/announcement_form_sheet.dart';

/// Phase 3 (3.2) — one announcement: the full English + Urdu copy,
/// audience, channel, schedule and delivery stats. Drafts and
/// scheduled (not-yet-sent) announcements can be edited and deleted
/// from here; sent (and `pending_whatsapp`) announcements are
/// read-only history — their push already went out, and
/// `sendAnnouncement` refuses a re-send server-side, so the client
/// never offers to rewrite them either.
class AdminAnnouncementDetailView extends StatefulWidget {
  const AdminAnnouncementDetailView({super.key, required this.announcementId});

  final String announcementId;

  @override
  State<AdminAnnouncementDetailView> createState() =>
      _AdminAnnouncementDetailViewState();
}

class _AdminAnnouncementDetailViewState
    extends State<AdminAnnouncementDetailView> {
  AdminAnnouncement? _announcement;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final a = await sl<AdminSupportDataSource>()
          .getAnnouncement(widget.announcementId);
      if (mounted) {
        setState(() {
          _announcement = a;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _editable {
    final status = _announcement?.status;
    return status == 'draft' || status == 'scheduled';
  }

  Future<void> _edit() async {
    final a = _announcement;
    if (a == null || !_editable) return;
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AnnouncementFormSheet(
        existing: a,
        onCreated: _load,
      ),
    );
  }

  Future<void> _delete() async {
    final a = _announcement;
    if (a == null || !_editable) return;
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    if (!mounted) return;
    final confirmed = await showAdminConfirmDialog(
      context,
      title: l10n.admin2_anncDeleteConfirmTitle,
      body: l10n.admin2_anncDeleteConfirmBody,
    );
    if (!confirmed || !mounted) return;
    setState(() => _isWorking = true);
    final deleted = await sl<AdminSupportDataSource>().deleteAnnouncement(
      a.id,
      adminRole: check.role,
    );
    if (!mounted) return;
    setState(() => _isWorking = false);
    if (deleted) {
      AppFeedback.showSuccess(context, l10n.admin2_anncDeleted);
      context.go(RouteNames.adminAnnouncements);
    } else {
      AppFeedback.showError(context, l10n.admin2_serverUnreachable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final a = _announcement;
    return AdminShell(
      activeRoute: RouteNames.adminAnnouncements,
      title: l10n.admin2_anncDetailTitle,
      subtitle: l10n.admin2_anncSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminAnnouncements),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_anncDetailLoadFailed,
                  onRetry: _load,
                )
              : a == null
                  ? AppEmptyState(title: l10n.admin2_anncDetailNotFound)
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(
                          windowSizeClassOf(context) ==
                                  WindowSizeClass.compact
                              ? 16
                              : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.titleEn,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600)),
                          if (a.titleUr.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(a.titleUr,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(fontSize: 18)),
                          ],
                          const SizedBox(height: 12),
                          Text(a.bodyEn,
                              style: const TextStyle(fontSize: 14)),
                          if (a.bodyUr.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(a.bodyUr,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(fontSize: 14)),
                          ],
                          const SizedBox(height: 20),
                          AdminDetailSection(
                            title: l10n.admin2_anncFormAudienceRole,
                            lines: [
                              '${a.audienceRole} • ${a.audienceCity} • ${a.audiencePlan}',
                              '${a.channel} • ${a.status}',
                              l10n.admin2_anncStats(
                                  a.sent, a.delivered, a.opened),
                              if (a.scheduledAt != null)
                                l10n.admin2_anncFormScheduled(
                                    a.scheduledAt!.toIso8601String()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!_editable)
                            Text(l10n.admin2_anncReadOnly,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          if (_editable) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed:
                                      _isWorking ? null : _edit,
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 18),
                                  label: Text(l10n.admin2_anncEdit),
                                  style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 48)),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      _isWorking ? null : _delete,
                                  icon: const Icon(Icons.delete_rounded,
                                      size: 18),
                                  label:
                                      Text(l10n.admin2_anncDelete),
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .error),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
