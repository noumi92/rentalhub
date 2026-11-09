import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

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

  String _time(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final amPm = t.hour < 12 ? 'AM' : 'PM';
    return '$hour:${t.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _date(DateTime t) => '${t.day}/${t.month}/${t.year}';

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
          _row(context, _scheduleLabel(l10n, b), b),
        const SizedBox(height: 20),
        _sectionTitle(context, l10n.dashboardUpcomingReturns),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Text(l10n.dashboardReturnsEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        for (final b in upcoming)
          _row(context, _date(b.returnTime), b),
      ],
    );
  }

  String _scheduleLabel(AppLocalizations l10n, BookingEntity b) {
    if (_isToday(b.pickupTime) && b.status != 'active') {
      return '${_time(b.pickupTime)} · ${l10n.dashboardScheduleHandover}';
    }
    if (_isToday(b.returnTime)) {
      return '${_time(b.returnTime)} · ${l10n.dashboardScheduleReturn}';
    }
    return '${_time(b.pickupTime)} · ${l10n.dashboardScheduleBooking}';
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ));
  }

  Widget _row(BuildContext context, String label, BookingEntity b) {
    final name = b.customerName ?? '';
    final vehicle = b.vehicleName ?? b.vehiclePlate ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
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
    );
  }
}
