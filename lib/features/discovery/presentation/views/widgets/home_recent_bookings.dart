import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/app_state_views.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../customer/data/services/customer_home_service.dart';
import '../../../../customer/presentation/widgets/booking_ticket_card.dart';

/// Customer rework (Worker C): the Home "Recent bookings" section —
/// the customer's three most recent bookings as [BookingTicketCard]s,
/// with the same actions as the bookings list (Pay Advance / View
/// Pass / Rate Trip). A booking with an outstanding advance carries
/// a visible payment banner above its card — overdue in danger
/// colours when the pickup has already passed, due in warning
/// colours otherwise. The section header links to the full list.
class HomeRecentBookings extends StatelessWidget {
  const HomeRecentBookings({
    super.key,
    required this.data,
    this.onOpenBooking,
    this.onPayAdvance,
    this.onRateTrip,
    this.onRetry,
  });

  final CustomerHomeData data;
  final ValueChanged<BookingEntity>? onOpenBooking;
  final ValueChanged<BookingEntity>? onPayAdvance;
  final ValueChanged<BookingEntity>? onRateTrip;
  final VoidCallback? onRetry;

  void _openBooking(BuildContext context, BookingEntity booking) {
    if (onOpenBooking != null) {
      onOpenBooking!(booking);
      return;
    }
    context.push(
      RouteNames.customerBookingDetail.replaceFirst(':id', booking.bookingId),
    );
  }

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

  void _rateTrip(BuildContext context, BookingEntity booking) {
    if (onRateTrip != null) {
      onRateTrip!(booking);
      return;
    }
    context.push(
      RouteNames.customerRateTrip.replaceFirst(':id', booking.bookingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recent = data.recentBookings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.home2_recentBookings,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => context.go(RouteNames.customerBookings),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.home2_viewAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.bookingsFailed)
          AppErrorState(
            message: l10n.bookingsLoadError,
            onRetry: onRetry,
          )
        else if (recent.isEmpty)
          AppEmptyState(
            title: l10n.home2_noBookings,
            message: l10n.bookingsEmptyHint,
            actionLabel: l10n.quickBookCar,
            actionIcon: Icons.directions_car_rounded,
            onAction: () => context.go(RouteNames.customerShops),
          )
        else
          for (final booking in recent) ...[
            if (data.isPaymentOutstanding(booking))
              _PaymentBanner(
                booking: booking,
                overdue: data.isPaymentOverdue(booking),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(
                builder: (context) {
                  String? actionLabel;
                  VoidCallback? actionCallback;
                  if (booking.status == 'approved') {
                    actionLabel = l10n.bookingsPayAdvance;
                    actionCallback = () => _payAdvance(context, booking);
                  } else if (booking.status == 'paid' ||
                      booking.status == 'active') {
                    actionLabel = l10n.bookingsViewPass;
                    actionCallback = () => _openBooking(context, booking);
                  } else if (booking.status == 'completed') {
                    actionLabel = l10n.bookingsRateTrip;
                    actionCallback = () => _rateTrip(context, booking);
                  }
                  return BookingTicketCard(
                    booking: booking,
                    onTap: () => _openBooking(context, booking),
                    actionLabel: actionLabel,
                    onAction: actionCallback,
                  );
                },
              ),
            ),
          ],
      ],
    );
  }
}

/// The outstanding-advance flag above a recent booking's card. The
/// overdue variant (pickup passed, advance unpaid) is danger; the
/// due variant (pickup ahead) is warning. Both show the amount. The
/// card below carries the Pay Advance action, so the banner is a
/// flag only — no second button.
class _PaymentBanner extends StatelessWidget {
  const _PaymentBanner({
    required this.booking,
    required this.overdue,
  });

  final BookingEntity booking;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final color = overdue
        ? AppColors.dangerTextFor(brightness)
        : AppColors.warningTextFor(brightness);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              overdue
                  ? Icons.error_outline_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${overdue ? l10n.home2_paymentOverdue : l10n.home2_paymentDue} • ${l10n.amountRs(formatRs(booking.remainingBalance))}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
