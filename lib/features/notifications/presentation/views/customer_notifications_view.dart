import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/signed_in_user.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/notification_data_source.dart';
import '../../domain/entities/notification_entity.dart';
import '../widgets/notification_inbox_widgets.dart';

/// Customer in-app notifications inbox: booking approvals, payment
/// verifications, handover/return milestones, KYC decisions, dispute
/// resolutions, and announcements. Tapping an item marks it read and
/// deep-links to the corresponding screen.
class CustomerNotificationsView extends StatefulWidget {
  final String? customerId;

  const CustomerNotificationsView({super.key, this.customerId});

  @override
  State<CustomerNotificationsView> createState() =>
      _CustomerNotificationsViewState();
}

class _CustomerNotificationsViewState extends State<CustomerNotificationsView> {
  List<NotificationEntity> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all'; // 'all' | 'unread' | 'bookings'
  StreamSubscription<void>? _changesSub;

  String get _resolvedCustomerId => widget.customerId ?? SignedInUser.uid();

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
          .getCustomerNotifications(_resolvedCustomerId);
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
          .getCustomerNotifications(_resolvedCustomerId);
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
      await sl<NotificationDataSource>()
          .markAllCustomerRead(_resolvedCustomerId);
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
    final bookingId = n.bookingId;
    if (bookingId == null || bookingId.isEmpty) return;
    switch (n.type) {
      case 'booking_approved':
      case 'payment_rejected':
        context.push(
            RouteNames.customerPaymentProof.replaceFirst(':id', bookingId));
      case 'payment_verified':
        context.push(
            RouteNames.customerPickupPass.replaceFirst(':id', bookingId));
      case 'handover':
      case 'trip_started':
        context.push(
            RouteNames.customerActiveTrip.replaceFirst(':id', bookingId));
      case 'return':
      case 'trip_completed':
        context.push(
            RouteNames.customerRateTrip.replaceFirst(':id', bookingId));
      case 'dispute_resolved':
        context.push('${RouteNames.customerDisputes}?bookingId=$bookingId');
      default:
        context.push(
            RouteNames.customerBookingDetail.replaceFirst(':id', bookingId));
    }
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'booking_approved' || 'payment_verified' => Icons.check_circle_rounded,
      'booking_rejected' || 'payment_rejected' => Icons.error_outline_rounded,
      'handover' || 'trip_started' => Icons.key_rounded,
      'return' || 'trip_completed' => Icons.assignment_turned_in_rounded,
      'kyc_status' => Icons.verified_user_rounded,
      'dispute_resolved' => Icons.gavel_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _iconColorFor(BuildContext context, String type) {
    final brightness = Theme.of(context).brightness;
    return switch (type) {
      'booking_approved' ||
      'payment_verified' ||
      'return' ||
      'trip_completed' =>
        AppColors.successTextFor(brightness),
      'booking_rejected' || 'payment_rejected' =>
        AppColors.dangerTextFor(brightness),
      'handover' || 'trip_started' => AppColors.orangeTextFor(brightness),
      _ => AppColors.primaryTextFor(brightness),
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
