import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/theme/card_decoration.dart';

/// Audit §25 (extracted from [OwnerDuesView] so the view stays under
/// the 250-line cap): the total-due summary card and one customer's
/// grouped dues card, with a per-booking sub-line (id • date •
/// amount) so the owner can see which booking the money is for.
class DuesTotalCard extends StatelessWidget {
  final int totalDue;

  const DuesTotalCard({super.key, required this.totalDue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.financeDuesTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(l10n.amountRs(formatRs(totalDue)),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.dangerTextFor(
                      Theme.of(context).brightness))),
        ],
      ),
    );
  }
}

class DuesGroupCard extends StatelessWidget {
  final List<BookingEntity> bookings;
  final DateTime? lastReminded;
  final VoidCallback onRemind;

  /// Item 6 (2026-11-21): collect a due later, per booking —
  /// dues are recorded and ledgered per booking, so each booking
  /// line gets its own action. Null keeps the plain sub-lines.
  final void Function(BookingEntity booking)? onCollect;

  const DuesGroupCard({
    super.key,
    required this.bookings,
    required this.lastReminded,
    required this.onRemind,
    this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final due =
        bookings.fold(0, (total, b) => total + b.remainingBalance);
    final name =
        bookings.first.customerName ?? l10n.requestsCustomerFallback;
    final phone = bookings.first.customerPhone;
    final last = lastReminded;
    final overdue = last == null ||
        DateTime.now().difference(last).inDays >= 3;
    final locale = Localizations.localeOf(context).languageCode;
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(l10n.amountRs(formatRs(due)),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dangerTextFor(
                          Theme.of(context).brightness))),
            ],
          ),
          Text(
              l10n.financeDuesBookingsLine(
                  bookings.length, phone ?? l10n.financeDuesNoPhone),
              style: Theme.of(context).textTheme.labelSmall),
          // Audit §25: a grouped total used to hide which booking is
          // owed — one sub-line per booking (id • date • amount),
          // each with its own collect action (Item 6): dues are
          // collected per booking, so the amount defaults to that
          // booking's remaining due. The 6px vertical padding keeps
          // the row on the 48dp touch target with the 36dp button.
          ...bookings.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${b.bookingId} • ${DateFormat.yMMMd(locale).format(b.pickupTime)} • ${l10n.amountRs(formatRs(b.remainingBalance))}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: variant)),
                    ),
                    TextButton(
                      onPressed: onCollect == null
                          ? null
                          : () => onCollect!(b),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.financeDuesCollect),
                    ),
                  ],
                ),
              )),
          // Audit §25: the last-reminded date is formatted with
          // `intl` per locale (was raw day/month/year) and carried
          // by the financeDuesLastRemindedDate key.
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 14, color: variant),
                  const SizedBox(width: 4),
                  Text(
                      l10n.financeDuesLastRemindedDate(
                          DateFormat.yMMMd(locale).format(last)),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: variant)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: Text(overdue
                  ? l10n.financeDuesRemind
                  : l10n.financeDuesRemindAgain),
              onPressed: onRemind,
            ),
          ),
        ],
      ),
    );
  }
}
