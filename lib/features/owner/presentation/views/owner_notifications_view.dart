import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_icon_chip.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../../core/theme/card_decoration.dart';

/// Phase B (G2): the owner's inbox — booking requests, payment
/// proofs waiting for verification, and the rest. Tapping a
/// notification marks it read and opens its booking when it has one.
class OwnerNotificationsView extends StatefulWidget {
  final String shopId;

  const OwnerNotificationsView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerNotificationsView> createState() => _OwnerNotificationsViewState();
}

class _OwnerNotificationsViewState extends State<OwnerNotificationsView> {
  List<NotificationEntity> _items = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
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
      // Audit §3/C4: a load failure used to masquerade as "No
      // notifications" — surface it with a retry instead.
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
      if (mounted) AppFeedback.showError(context, l10n.notificationsMarkReadError);
    }
  }

  Future<void> _open(NotificationEntity n) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await sl<NotificationDataSource>().markRead(n.notificationId);
    } catch (_) {
      // Marking read is best-effort: the booking still opens, but
      // the owner is told the read state may not have stuck.
      if (mounted) AppFeedback.showError(context, l10n.notificationsMarkReadError);
    }
    if (mounted) {
      setState(() => _items = _items
          .map((i) => i.notificationId == n.notificationId
              ? i.copyWith(read: true)
              : i)
          .toList());
    }
    if (n.bookingId != null && mounted) {
      context.push(
          RouteNames.ownerRequestsDetail.replaceFirst(':id', n.bookingId!));
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

  Color _iconColorFor(BuildContext context, String type) {
    final brightness = Theme.of(context).brightness;
    switch (type) {
      case 'booking_request':
        return Theme.of(context).colorScheme.primary;
      case 'payment_proof':
        return AppColors.successTextFor(brightness);
      case 'handover':
        return AppColors.orangeTextFor(brightness);
      case 'return':
        return AppColors.warningTextFor(brightness);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// Audit §3: the entity carries `createdAt` but the row never
  /// showed it. No relative-time helper exists in the app, so the
  /// timestamp is formatted with `intl` per locale: time today,
  /// date + time otherwise.
  String _formatTime(BuildContext context, DateTime t) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    if (DateTime(t.year, t.month, t.day) ==
        DateTime(now.year, now.month, now.day)) {
      return DateFormat.jm(locale).format(t);
    }
    return DateFormat.MMMd(locale).add_jm().format(t);
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
                if (_items.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: _markAllRead,
                      child: Text(l10n.notificationsMarkAllRead,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400)),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.notificationsLoadError,
                          onRetry: _load,
                        )
                      : _items.isEmpty
                          ? AppEmptyState(
                              title: l10n.notificationsEmpty,
                              icon: Icons.notifications_rounded,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  _row(context, _items[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, NotificationEntity n) {
    final iconColor = _iconColorFor(context, n.type);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _open(n),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.read
              ? scheme.surface
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: n.read
              ? null
              : Border.all(color: AppColors.primary),
          boxShadow: AppCardDecoration.shadow(context),
        ),
        child: Row(
          children: [
            AppIconChip(
              icon: _iconFor(n.type),
              iconColor: iconColor,
              background: iconColor.withValues(alpha: 0.12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(n.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(_formatTime(context, n.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: scheme.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
