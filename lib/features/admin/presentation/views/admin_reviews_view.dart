import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_platform_data_source.dart';
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
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reviews = await sl<AdminPlatformDataSource>().getReviews();
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
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
        title: Text('Mark as $status?'),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Reason (stored with the decision)',
            border: OutlineInputBorder(),
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
    return AdminShell(
      activeRoute: RouteNames.adminReviews,
      title: 'Reviews moderation',
      subtitle: 'Abusive, fake and revenge queues',
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
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? const Center(
                          child: Text(
                            'No reviews in this queue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = visible[i];
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
                                    Text(
                                      '${r.customerName ?? r.customerId} • ${r.vehicleName ?? r.bookingId}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Shop ${r.shopRating ?? '—'}/5 • Car ${r.vehicleRating ?? '—'}/5 • Owner: punctuality ${r.ownerPunctuality ?? '—'}, care ${r.ownerCare ?? '—'}, behaviour ${r.ownerBehavior ?? '—'}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted),
                                    ),
                                    if (r.customerComment.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('"${r.customerComment}"',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic)),
                                    ],
                                    if (r.signals.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: r.signals
                                            .map((s) => Chip(
                                                  label: Text(s,
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      'Moderation: ${r.moderationStatus}${r.moderationReason.isNotEmpty ? ' — ${r.moderationReason}' : ''}',
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
                                              _moderate(r, 'visible'),
                                          child: const Text('Keep'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _moderate(r, 'hidden'),
                                          child: const Text('Hide'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => _moderate(
                                              r, 'edit_requested'),
                                          child: const Text('Ask to edit'),
                                        ),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _moderate(r, 'warned'),
                                          child: const Text('Warn'),
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
