import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../core/widgets/app_icon_chip.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_entity.dart';

/// Shared locale-aware timestamp formatter for notification rows:
/// time-only for today, date + time otherwise.
String formatNotificationTime(BuildContext context, DateTime t) {
  final locale = Localizations.localeOf(context).languageCode;
  final now = DateTime.now();
  if (DateTime(t.year, t.month, t.day) ==
      DateTime(now.year, now.month, now.day)) {
    return DateFormat.jm(locale).format(t);
  }
  return DateFormat.MMMd(locale).add_jm().format(t);
}

/// Shared All / Unread / Bookings filter chips for both customer and
/// owner notification inboxes.
class NotificationFilterBar extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onChanged;

  const NotificationFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.filterAll),
              selected: filter == 'all',
              onSelected: (_) => onChanged('all'),
            ),
            ChoiceChip(
              label: Text(l10n.notificationsFilterUnread),
              selected: filter == 'unread',
              onSelected: (_) => onChanged('unread'),
            ),
            ChoiceChip(
              label: Text(l10n.bookingsTitle),
              selected: filter == 'bookings',
              onSelected: (_) => onChanged('bookings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared loading / error / empty / pull-to-refresh list body for
/// both notification inbox screens.
class NotificationInboxBody extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<NotificationEntity> items;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, NotificationEntity item)
      itemBuilder;

  const NotificationInboxBody({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.items,
    required this.onRefresh,
    required this.onRetry,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) return const AppLoadingState();
    if (hasError) {
      return AppErrorState(
        message: l10n.notificationsLoadError,
        onRetry: onRetry,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: AppEmptyState(
                    title: l10n.notificationsEmpty,
                    icon: Icons.notifications_rounded,
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  itemBuilder(context, items[index]),
            ),
    );
  }
}

/// Shared dark-mode compliant, screen-reader accessible notification card.
class NotificationCardTile extends StatelessWidget {
  final NotificationEntity notification;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const NotificationCardTile({
    super.key,
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final primaryAccent = AppColors.primaryTextFor(brightness);
    return Semantics(
      button: true,
      hint: notification.read ? null : l10n.notificationsFilterUnread,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.read
                ? scheme.surface
                : scheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border:
                notification.read ? null : Border.all(color: primaryAccent),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Row(
            children: [
              AppIconChip(
                icon: icon,
                iconColor: iconColor,
                background: iconColor.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: notification.read
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                    ),
                    Text(
                      notification.body,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatNotificationTime(context, notification.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
