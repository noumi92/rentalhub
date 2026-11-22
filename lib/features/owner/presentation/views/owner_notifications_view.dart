import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../notifications/presentation/widgets/notification_inbox_widgets.dart';

/// Phase B (G2): the owner's inbox — booking requests, payment
/// proofs waiting for verification, and the rest. Tapping a
/// notification marks it read and opens its booking when it has one.
class OwnerNotificationsView extends StatefulWidget {
  final String shopId;

  const OwnerNotificationsView({super.key, required this.shopId});

  @override
  State<OwnerNotificationsView> createState() => _OwnerNotificationsViewState();
}

class _OwnerNotificationsViewState extends State<OwnerNotificationsView> {
  List<NotificationEntity> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all'; // 'all' | 'unread' | 'bookings'
  StreamSubscription<void>? _changesSub;

  @override
  void initState() {
    super.initState();
    _load();
    _changesSub = sl<NotificationDataSource>().changes.listen((_) {
      if (mounted) _refreshSilently();
    });
  }

  @override
  void dispose() {
    _changesSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshSilently() async {
    try {
      final items = await sl<NotificationDataSource>()
          .getShopNotifications(widget.shopId);
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final items = await sl<NotificationDataSource>()
          .getShopNotifications(widget.shopId);
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await sl<NotificationDataSource>().markAllRead(widget.shopId);
      if (mounted) {
        setState(() =>
            _items = _items.map((i) => i.copyWith(read: true)).toList());
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, l10n.notificationsMarkReadError);
      }
    }
  }

  Future<void> _open(NotificationEntity n) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await sl<NotificationDataSource>().markRead(n.notificationId);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, l10n.notificationsMarkReadError);
      }
    }
    if (mounted) {
      setState(() => _items = _items
          .map((i) => i.notificationId == n.notificationId
              ? i.copyWith(read: true)
              : i)
          .toList());
    }
    if (!mounted) return;
    if (n.targetRoute != null && n.targetRoute!.isNotEmpty) {
      context.push(n.targetRoute!);
      return;
    }
    if (n.bookingId != null) {
      final dest = n.type == 'payment_proof'
          ? RouteNames.ownerPaymentProof
          : RouteNames.ownerRequestsDetail;
      context.push(dest.replaceFirst(':id', n.bookingId!));
    }
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'booking_request' => Icons.inbox_rounded,
      'booking_cancelled' => Icons.cancel_outlined,
      'payment_proof' => Icons.fact_check_rounded,
      'handover' => Icons.key_rounded,
      'return' => Icons.assignment_return_rounded,
      'dispute_filed' => Icons.gavel_rounded,
      'new_review' => Icons.star_rate_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _iconColorFor(BuildContext context, String type) {
    final brightness = Theme.of(context).brightness;
    return switch (type) {
      'booking_request' => AppColors.primaryTextFor(brightness),
      'booking_cancelled' || 'dispute_filed' =>
        AppColors.dangerTextFor(brightness),
      'payment_proof' => AppColors.successTextFor(brightness),
      'handover' || 'new_review' => AppColors.orangeTextFor(brightness),
      'return' => AppColors.warningTextFor(brightness),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  List<NotificationEntity> get _filteredItems {
    if (_filter == 'unread') return _items.where((i) => !i.read).toList();
    if (_filter == 'bookings') {
      return _items.where((i) => i.bookingId != null).toList();
    }
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.notifications,
              subtitle: l10n.notificationsSubtitle,
              onBack: () => context.pop(),
              actions: [
                if (_items.any((i) => !i.read))
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        l10n.notificationsMarkAllRead,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (!_isLoading && !_hasError && _items.isNotEmpty)
              NotificationFilterBar(
                filter: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
            Expanded(
              child: NotificationInboxBody(
                isLoading: _isLoading,
                hasError: _hasError,
                items: _filteredItems,
                onRefresh: _load,
                onRetry: _load,
                itemBuilder: (context, n) => NotificationCardTile(
                  notification: n,
                  icon: _iconFor(n.type),
                  iconColor: _iconColorFor(context, n.type),
                  onTap: () => _open(n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
