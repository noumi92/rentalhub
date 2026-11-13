import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../customer/data/services/customer_home_service.dart';

/// Customer rework (Worker C): the Home "Upcoming" section — the
/// events that need the customer next. Overdue payments come first
/// (approved, advance unpaid, pickup already passed), then payments
/// still due, then the next handover. An overdue payment is flagged
/// in danger colours with its amount and a Pay action — never
/// hidden. Empty means nothing is coming up, not a load failure
/// (the caller hides this section when the bookings load failed).
class HomeUpcomingEvents extends StatelessWidget {
  const HomeUpcomingEvents({
    super.key,
    required this.data,
    this.onOpenBooking,
    this.onPayAdvance,
  });

  final CustomerHomeData data;
  final ValueChanged<BookingEntity>? onOpenBooking;
  final ValueChanged<BookingEntity>? onPayAdvance;

  /// "Pay Advance" follows the bookings list's flow: the approved
  /// screen first ([RouteNames.customerBookingApproved]), whose own
  /// Pay button opens the payment screen — not a shortcut past it.
  void _payAdvance(BuildContext context, BookingEntity booking) {
    if (onPayAdvance != null) {
      onPayAdvance!(booking);
      return;
    }
    context.push(
      RouteNames.customerBookingApproved
          .replaceFirst(':id', booking.bookingId),
    );
  }

  bool get _isEmpty =>
      data.overduePayments.isEmpty &&
      data.paymentsDue.isEmpty &&
      data.nextHandover == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.home2_upcoming,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (_isEmpty)
          AppEmptyState(
            title: l10n.home2_noUpcoming,
            icon: Icons.event_available_rounded,
          )
        else ...[
          for (final booking in data.overduePayments)
            _EventRow(
              booking: booking,
              icon: Icons.error_outline_rounded,
              color: AppColors.dangerTextFor(Theme.of(context).brightness),
              title: l10n.home2_paymentOverdue,
              detail: l10n.amountRs(formatRs(booking.remainingBalance)),
              actionLabel: l10n.bookingsPayAdvance,
              onTap: () => onOpenBooking?.call(booking),
              onAction: () => _payAdvance(context, booking),
            ),
          for (final booking in data.paymentsDue)
            _EventRow(
              booking: booking,
              icon: Icons.schedule_rounded,
              color: AppColors.warningTextFor(Theme.of(context).brightness),
              title: l10n.home2_paymentDue,
              detail: l10n.amountRs(formatRs(booking.remainingBalance)),
              actionLabel: l10n.bookingsPayAdvance,
              onTap: () => onOpenBooking?.call(booking),
              onAction: () => _payAdvance(context, booking),
            ),
          if (data.nextHandover != null)
            _EventRow(
              booking: data.nextHandover!,
              icon: Icons.key_rounded,
              color: AppColors.primary,
              title: l10n.dashboardScheduleHandover,
              detail: l10n.ticketPickupDate(
                data.nextHandover!.pickupTime.day,
                data.nextHandover!.pickupTime.month,
                data.nextHandover!.pickupTime.year,
              ),
              onTap: () => onOpenBooking?.call(data.nextHandover!),
            ),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.booking,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onTap,
    this.onAction,
  });

  final BookingEntity booking;
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final middle = [
      booking.vehicleName,
      booking.shopName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' • ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                                fontWeight: FontWeight.w800, color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        middle.isEmpty ? booking.bookingId : middle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 8),
                  // At 200% text scale the 'Pay Advance' label is wider
                  // than the remaining row — shrink and ellipsize it
                  // instead of overflowing.
                  Flexible(
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        // CU-M3: 48dp minimum tap target.
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        actionLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
