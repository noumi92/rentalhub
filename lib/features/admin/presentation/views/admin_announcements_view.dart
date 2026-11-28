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
import '../widgets/admin_announcement_card.dart';
import '../widgets/admin_announcements_header.dart';
import '../widgets/admin_sort_menu.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_load_more_button.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_shell.dart';
import '../widgets/announcement_form_sheet.dart';

/// Platform announcements broadcast center.
class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() =>
      _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  static const _pageSize = 20;

  List<AdminAnnouncement> _announcements = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  Object? _cursor;
  bool _hasMore = false;
  String _sort = AdminListSort.dateNewest;
  int? _total;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _announcements = [];
        _cursor = null;
        _hasMore = false;
        _total = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final page = await sl<AdminSupportDataSource>().getAnnouncementsPage(
        limit: _pageSize,
        cursor: reset ? null : _cursor,
        sort: _sort,
      );
      if (mounted) {
        setState(() {
          _announcements =
              reset ? page.items : [..._announcements, ...page.items];
          _cursor = page.cursor;
          _hasMore = page.hasMore;
          _total = page.total;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _send(AdminAnnouncement a, {required bool test}) async {
    // F-C1: super admin + operations only (managePlatform). See
    // the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    if (!mounted) return;
    // Phase 1 (1.1): a real send broadcasts to the whole audience —
    // confirm it. A test send goes only to the calling admin's own
    // device and needs no confirm.
    if (!test) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showAdminConfirmDialog(
        context,
        title: l10n?.admin2_anncSendConfirmTitle ??
            'Send this announcement now?',
        body: l10n?.admin2_anncSendConfirmBody ??
            'This sends the announcement to its audience right away. A sent announcement cannot be recalled.',
      );
      if (!confirmed) return;
    }
    if (!mounted) return;
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

  String _countLine(AppLocalizations l10n) {
    final total = _total;
    if (total != null && total > _announcements.length) {
      return l10n.adminAuditShowingFirstOf(_announcements.length, total);
    }
    return l10n.adminAuditShowing(_announcements.length);
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
      subTabs: AdminSectionTabs.trustAndSupport(
        context,
        activeRoute: RouteNames.adminAnnouncements,
      ),
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            AdminAnnouncementsHeader(
              onNew: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                // Phase 1 (1.5): drag handle on the sheet.
                showDragHandle: true,
                builder: (_) => AnnouncementFormSheet(onCreated: _load),
              ),
              sort: _sort,
              onSort: (sort) {
                if (sort == _sort) return;
                setState(() => _sort = sort);
                _load();
              },
            ),
            const SizedBox(height: 16),
            if (!_isLoading && !_hasError && _announcements.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _countLine(l10n),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                ),
              ),
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
                          itemCount: _announcements.length +
                              (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            if (i >= _announcements.length) {
                              return AdminLoadMoreButton(
                                isLoadingMore: _isLoadingMore,
                                onPressed: () => _load(reset: false),
                              );
                            }
                            final a = _announcements[i];
                            return AdminAnnouncementCard(
                              announcement: a,
                              onTap: () => context.go(
                                RouteNames.adminAnnouncementDetail
                                    .replaceFirst(
                                        ':announcementId', a.id),
                              ),
                              onSendTest: () => _send(a, test: true),
                              onSendNow: () => _send(a, test: false),
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
