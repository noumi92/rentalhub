import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../../notifications/domain/entities/notification_entity.dart';

/// Phase B (G2): the owner's inbox — booking requests, payment
/// proofs waiting for verification, and the rest. Tapping a
/// notification marks it read and opens its booking when it has one.
class OwnerNotificationsView extends StatefulWidget {
  final String shopId;

  const OwnerNotificationsView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerNotificationsView> createState() =>
      _OwnerNotificationsViewState();
}

class _OwnerNotificationsViewState extends State<OwnerNotificationsView> {
  List<NotificationEntity> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await sl<NotificationDataSource>()
          .getShopNotifications(widget.shopId);
      if (mounted) setState(() => _items = items);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _open(NotificationEntity n) async {
    await sl<NotificationDataSource>().markRead(n.notificationId);
    if (mounted) {
      setState(() => _items = _items
          .map((i) => i.notificationId == n.notificationId
              ? i.copyWith(read: true)
              : i)
          .toList());
    }
    if (n.bookingId != null && mounted) {
      context.push(RouteNames.ownerRequestsDetail
          .replaceFirst(':id', n.bookingId!));
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.inbox_rounded;
      case 'payment_proof':
        return Icons.fact_check_rounded;
      case 'handover':
        return Icons.key_rounded;
      case 'return':
        return Icons.assignment_return_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifications',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text('What needs your attention',
                      style: TextStyle(
                          color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await sl<NotificationDataSource>()
                        .markAllRead(widget.shopId);
                    if (mounted) {
                      setState(() => _items =
                          _items.map((i) => i.copyWith(read: true)).toList());
                    }
                  },
                  child: const Text('Mark all read',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(
                          child: Text('No notifications yet.',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final n = _items[index];
                            return InkWell(
                              onTap: () => _open(n),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: n.read
                                      ? Colors.white
                                      : AppColors.royalNavy
                                          .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: n.read
                                          ? AppColors.border
                                          : AppColors.royalNavy),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_iconFor(n.type),
                                        color: AppColors.royalNavy),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(n.title,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AppColors.midnightNavy)),
                                          Text(n.body,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary)),
                                        ],
                                      ),
                                    ),
                                    if (!n.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            color: AppColors.royalNavy,
                                            shape: BoxShape.circle),
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
