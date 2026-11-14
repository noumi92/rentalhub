import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_review_card.dart';
import '../widgets/admin_shell.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final reviews = await sl<AdminPlatformDataSource>().getReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
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
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // scrollable: the reason field + actions must not overflow
        // vertically on a phone at large text scales.
        scrollable: true,
        title: Text('Mark as $status?'),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Reason (stored with the decision)',
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      if (mounted) {
        AppFeedback.showError(context, 'A reason is required.');
      }
      return;
    }
    final synced = await sl<AdminPlatformDataSource>().setReviewModeration(
      reviewId: r.id,
      status: status,
      reason: reason,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, 'Review marked as $status.');
      await _load();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _reviews.where(_inQueue).toList();
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminReviews,
      title: 'Reviews moderation',
      subtitle: 'Abusive, fake and revenge queues',
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
                    'abusive': 'Abusive',
                    'fake': 'Fake',
                    'revenge': 'Revenge',
                    'clear': 'Clear',
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
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: 'Could not load the reviews.',
                          onRetry: _load,
                        )
                      : visible.isEmpty
                          ? const AppEmptyState(
                              title: 'No reviews in this queue.',
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
