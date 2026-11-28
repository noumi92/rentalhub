import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_review_card.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_sort_menu.dart';

/// Phase D (D3) — reviews moderation: the Abusive / Fake / Revenge
/// queues. A review lands in a queue only when an auto-check signal
/// fires; the signal never hides it — the admin decides Keep, Hide,
/// Ask-to-edit, or Warn.
class AdminReviewsView extends StatefulWidget {
  const AdminReviewsView({super.key});

  @override
  State<AdminReviewsView> createState() => _AdminReviewsViewState();
}

class _AdminReviewsViewState extends State<AdminReviewsView> {
  List<AdminReview> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all';
  String _sort = AdminListSort.ratingHigh;
  int? _total;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final ds = sl<AdminPlatformDataSource>();
      final reviews = await ds.getReviews();
      final total = await ds.countReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _total = total;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _inQueue(AdminReview r) {
    return switch (_filter) {
      'abusive' => r.signals.any((s) => s.contains('Abusive')),
      'fake' => r.signals.any((s) => s.contains('Fake review')),
      'revenge' => r.signals.any((s) => s.contains('Revenge')),
      'clear' => r.signals.isEmpty,
      _ => true,
    };
  }

  Future<void> _moderate(AdminReview r, String status) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          // scrollable: the reason field + actions must not overflow
          // vertically on a phone at large text scales.
          scrollable: true,
          title: Text(l10n.admin2_reviewsMarkAs(reviewActionLabel(status, l10n))),
          content: TextField(
            controller: reasonController,
            // AD-m7: the dialog rebuilds on every keystroke so the
            // Confirm button enables only once a reason is typed.
            onChanged: (_) => setDialogState(() {}),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.admin2_reviewsReasonLabel,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              // AD-m7: Confirm stays disabled while the reason is
              // empty — the old flow popped true first and only then
              // complained that the reason was required.
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text(l10n.admin2_confirm),
            ),
          ],
        ),
      ),
    );
    final reason = reasonController.text.trim();
    // AD-m7: the controller is disposed — the old flow leaked one
    // per moderation dialog.
    reasonController.dispose();
    if (confirmed != true) return;
    if (reason.isEmpty) {
      if (mounted) {
        AppFeedback.showError(context, l10n.admin2_reasonRequired);
      }
      return;
    }
    // F-C1: reviews moderation rides on managePlatform (super
    // admin + operations only — the matrix has no dedicated reviews
    // permission). See the shop application sheet for the check's
    // contract.
    if (!mounted) return;
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    final synced = await sl<AdminPlatformDataSource>().setReviewModeration(
      reviewId: r.id,
      status: status,
      reason: reason,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
          context, l10n.admin2_reviewsMarked(reviewActionLabel(status, l10n)));
      await _load();
    } else {
      AppFeedback.showError(context, l10n.admin2_serverUnreachable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Phase 4 (4.3) — client-side sort (the list is client-side:
    // [AdminPlatformDataSource.getReviews] caps at 200).
    final visible = AdminPlatformDataSource.sortReviews(
        _reviews.where(_inQueue).toList(), _sort);
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminReviews,
      title: l10n.admin2_reviewsTitle,
      subtitle: l10n.admin2_reviewsSubtitle,
      subTabs: AdminSectionTabs.bookings(
        context,
        activeRoute: RouteNames.adminReviews,
      ),
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
                    'all': l10n.filterAll,
                    'abusive': l10n.admin2_reviewsFilterAbusive,
                    'fake': l10n.admin2_reviewsFilterFake,
                    'revenge': l10n.admin2_reviewsFilterRevenge,
                    'clear': l10n.admin2_reviewsFilterClear,
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) =>
                          setState(() => _filter = entry.key),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminSortMenu(
                  options: [
                    AdminSortOption(
                        id: AdminListSort.ratingHigh,
                        label: l10n.adminSortRatingHigh),
                    AdminSortOption(
                        id: AdminListSort.ratingLow,
                        label: l10n.adminSortRatingLow),
                    AdminSortOption(
                        id: AdminListSort.statusAsc,
                        label: l10n.adminSortStatus),
                  ],
                  selectedId: _sort,
                  onSelected: (sort) => setState(() => _sort = sort),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (!_isLoading && !_hasError && visible.isNotEmpty)
              AdminCountLine(shown: visible.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_reviewsLoadFailed,
                          onRetry: _load,
                        )
                      : visible.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_reviewsEmpty,
                            )
                          : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            return AdminReviewCard(
                              review: visible[i],
                              onModerate: _moderate,
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
