import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Audit impl (O29): "Today's Schedule" (today's handovers,
/// returns and new bookings, from the real booking pickup/return
/// times) and "Upcoming Returns" (active trips due back in the
/// next 7 days). Empty sections render an honest empty line, not a
/// fabricated schedule.
class DashboardScheduleSection extends StatelessWidget {
  final List<BookingEntity> bookings;

  const DashboardScheduleSection({super.key, required this.bookings});

  bool _isToday(DateTime t) {
    final now = DateTime.now();
    return t.year == now.year && t.month == now.month && t.day == now.day;
  }

  // OW-m35: intl with the current locale — the hand-rolled "3:05 PM"
  // and d/m/y never localised (Urdu digits, 24-hour preference).
  String _time(DateTime t, String locale) => DateFormat.jm(locale).format(t);

  String _date(DateTime t, String locale) => DateFormat.yMd(locale).format(t);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = bookings.where((b) =>
        _isToday(b.pickupTime) || _isToday(b.returnTime)).toList()
      ..sort((a, b) => a.pickupTime.compareTo(b.pickupTime));
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    final upcoming = bookings
        .where((b) =>
            b.status == 'active' &&
            b.returnTime.isAfter(now) &&
            b.returnTime.isBefore(weekEnd))
        .toList()
      ..sort((a, b) => a.returnTime.compareTo(b.returnTime));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, l10n.dashboardTodaySchedule),
        const SizedBox(height: 8),
        if (today.isEmpty)
          Text(l10n.dashboardScheduleEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final b in today)
          _row(context, _scheduleLabel(l10n, b, Localizations.localeOf(context).languageCode), b),
        const SizedBox(height: 20),
        _sectionTitle(context, l10n.dashboardUpcomingReturns),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Text(l10n.dashboardReturnsEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final b in upcoming)
          _row(context, _date(b.returnTime, Localizations.localeOf(context).languageCode), b),
      ],
    );
  }

  String _scheduleLabel(AppLocalizations l10n, BookingEntity b, String locale) {
    if (_isToday(b.pickupTime) && b.status != 'active') {
      return '${_time(b.pickupTime, locale)} · ${l10n.dashboardScheduleHandover}';
    }
    if (_isToday(b.returnTime)) {
      return '${_time(b.returnTime, locale)} · ${l10n.dashboardScheduleReturn}';
    }
    return '${_time(b.pickupTime, locale)} · ${l10n.dashboardScheduleBooking}';
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ));
  }

  Widget _row(BuildContext context, String label, BookingEntity b) {
    final name = b.customerName ?? '';
    final vehicle = b.vehicleName ?? b.vehiclePlate ?? '';
    // PW-19 (UI/UX audit 2026-11-15): schedule rows open the booking
    // detail — the row used to be inert, so the owner had to re-find
    // the booking under Requests.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(RouteNames.ownerRequestsDetail
              .replaceFirst(':id', b.bookingId)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // Phase 1 showroom redesign: the canonical card
              // language — 1 px borderSubtle hairline — on the
              // schedule rows too (the decoration stays colourless
              // so the InkWell ripple above the Material still shows).
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.borderSubtle,
              ),
              boxShadow: AppCardDecoration.shadow(context),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        [name, vehicle].where((s) => s.isNotEmpty).join(' — '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
