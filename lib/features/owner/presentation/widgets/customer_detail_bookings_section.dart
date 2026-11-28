import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import 'operations/owner_add_payment_sheet.dart';

/// CRM bookings list inside [CustomerDetailBody]: includes status-wise
/// filter chips, a clear status badge on every booking, and 1-tap next
/// step buttons (Add Payment, Start Handover, Return & Settle, Collect
/// Dues) so the owner can operate directly from the customer's profile.
class CustomerDetailBookingsSection extends StatefulWidget {
  final List<BookingEntity> bookings;
  final VoidCallback? onBookingUpdated;

  const CustomerDetailBookingsSection({
    super.key,
    required this.bookings,
    this.onBookingUpdated,
  });

  @override
  State<CustomerDetailBookingsSection> createState() =>
      _CustomerDetailBookingsSectionState();
}

class _CustomerDetailBookingsSectionState
    extends State<CustomerDetailBookingsSection> {
  String _statusFilter = 'all';

  static const _filterOrder = [
    'all',
    'approved',
    'paid',
    'active',
    'completed',
    'cancelled',
  ];

  String _statusLabel(AppLocalizations l10n, String status) =>
      {
        'all': l10n.customersFilterAll,
        'requested': l10n.requestsStatusRequested,
        'payment_submitted': l10n.statusProofSubmitted,
        'approved': l10n.statusApproved,
        'paid': l10n.statusPaid,
        'active': l10n.active,
        'completed': l10n.statusCompleted,
        'rejected': l10n.statusRejected,
        'cancelled': l10n.statusCancelled,
        'disputed': l10n.statusDisputed,
      }[status] ??
      status;

  (Color bg, Color fg) _badgeColors(BuildContext context, String status) {
    final brightness = Theme.of(context).brightness;
    return switch (status) {
      'approved' || 'payment_submitted' || 'disputed' => (
          AppColors.orangeContainerFor(brightness),
          AppColors.orangeTextFor(brightness),
        ),
      'paid' || 'active' || 'completed' => (
          AppColors.successContainerFor(brightness),
          AppColors.successTextFor(brightness),
        ),
      'rejected' || 'cancelled' => (
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
      _ => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
  }

  Future<void> _openPaymentSheet(BookingEntity b) async {
    final updated = await showOwnerAddPaymentSheet(context, booking: b);
    if (updated != null && mounted) widget.onBookingUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = widget.bookings;
    final filtered = _statusFilter == 'all'
        ? all
        : all.where((b) => b.status == _statusFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customerDetailRentalHistory,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (all.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final key in _filterOrder) ...[
                  if (key == 'all' ||
                      all.any((b) => b.status == key) ||
                      _statusFilter == key)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '${_statusLabel(l10n, key)} (${key == 'all' ? all.length : all.where((b) => b.status == key).length})',
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: _statusFilter == key,
                        onSelected: (_) => setState(() => _statusFilter = key),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (all.isEmpty)
          Text(l10n.customersNoBookings,
              style: Theme.of(context).textTheme.bodySmall)
        else if (filtered.isEmpty)
          Text(l10n.customerDetailNoBookingsInFilter,
              style: Theme.of(context).textTheme.bodySmall)
        else
          ...filtered.map((b) => _buildBookingCard(context, l10n, b)),
      ],
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    AppLocalizations l10n,
    BookingEntity b,
  ) {
    final (chipBg, chipFg) = _badgeColors(context, b.status);
    final step = resolveOwnerNextStep(b);
    final dest = step.destination(b);
    final isWalkIn = b.origin == 'walk_in';
    final canAddPayment = isWalkIn &&
        b.remainingBalance > 0 &&
        const {'approved', 'paid', 'active', 'completed'}.contains(b.status);

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? cs.outlineVariant : AppColors.borderSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          RouteNames.ownerRequestsDetail.replaceFirst(':id', b.bookingId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${b.vehicleName ?? l10n.summaryVehicle} • ${b.packageType}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(l10n, b.status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: chipFg,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDate(context, b.pickupTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    l10n.amountRs(formatRs(b.totalAmount)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (b.remainingBalance > 0 &&
                  b.status != 'cancelled' &&
                  b.status != 'rejected') ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.bookingFareRemaining}: ${l10n.amountRs(formatRs(b.remainingBalance))}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.orangeTextFor(
                            Theme.of(context).brightness),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color:
                          AppColors.orangeTextFor(Theme.of(context).brightness),
                    ),
                  ],
                ),
              ],
              if (step.kind == BookingNextStepKind.recordPayment ||
                  dest != null ||
                  canAddPayment) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (step.kind == BookingNextStepKind.recordPayment) ...[
                      FilledButton.tonalIcon(
                        onPressed: () => _openPaymentSheet(b),
                        icon: const Icon(Icons.payments_rounded, size: 16),
                        label: Text(l10n.walkInAddPayment),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                          RouteNames.ownerHandover
                              .replaceFirst(':id', b.bookingId),
                        ),
                        icon: const Icon(Icons.key_rounded, size: 16),
                        label: Text(l10n.bookingConfirmedStartHandover),
                      ),
                    ] else if (dest != null) ...[
                      FilledButton.tonalIcon(
                        onPressed: () => context.push(dest),
                        icon: Icon(
                          step.kind == BookingNextStepKind.startHandover
                              ? Icons.key_rounded
                              : step.kind ==
                                      BookingNextStepKind.returnSettlement
                                  ? Icons.keyboard_return_rounded
                                  : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                        label: Text(step.label(l10n, b)),
                      ),
                      if (canAddPayment)
                        OutlinedButton.icon(
                          onPressed: () => _openPaymentSheet(b),
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: Text(
                            b.status == 'completed'
                                ? l10n.walkInCollectDues
                                : l10n.walkInAddPayment,
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
