import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import  '../../../../bookings/domain/entities/booking_entity.dart';
import  '../../../../finance/domain/entities/finance_account_entity.dart';
import  '../../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Phase B (H1/H2): the ledger — every income and expense, newest
/// first, with the account and category it was posted to.
/// Audit impl (O34): All / Income / Expense filter chips, and a
/// booking # + customer name on rows whose entry carries a
/// bookingId (entries without one show nothing there — honestly).
class FinanceLedgerSection extends StatefulWidget {
  final List<FinanceTransferEntity> transfers;
  final List<FinanceAccountEntity> accounts;
  final List<BookingEntity> bookings;
  final VoidCallback onAddTransfer;

  const FinanceLedgerSection({
    super.key,
    required this.transfers,
    required this.accounts,
    this.bookings = const [],
    required this.onAddTransfer,
  });

  @override
  State<FinanceLedgerSection> createState() => _FinanceLedgerSectionState();
}

class _FinanceLedgerSectionState extends State<FinanceLedgerSection> {
  static const _pageSize = 20;
  bool _showAll = false;
  String _filter = 'all';

  List<FinanceTransferEntity> get _filtered {
    switch (_filter) {
      case 'income':
        return widget.transfers.where((t) => t.kind == 'income').toList();
      case 'expense':
        return widget.transfers.where((t) => t.kind == 'expense').toList();
      case 'all':
      default:
        return widget.transfers;
    }
  }

  List<FinanceTransferEntity> get _visible => _showAll
      ? _filtered
      : _filtered.take(_pageSize).toList();

  String _accountName(AppLocalizations l10n, String accountId) {
    return widget.accounts
            .where((a) => a.accountId == accountId)
            .firstOrNull
            ?.name ??
        l10n.financeAccountFallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transfers = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.financeLedgerTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.financeAddEntry),
              onPressed: widget.onAddTransfer,
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.financeFilterAll),
              selected: _filter == 'all',
              onSelected: (_) => setState(() => _filter = 'all'),
            ),
            ChoiceChip(
              label: Text(l10n.financeIncome),
              selected: _filter == 'income',
              onSelected: (_) => setState(() => _filter = 'income'),
            ),
            ChoiceChip(
              label: Text(l10n.financeExpense),
              selected: _filter == 'expense',
              onSelected: (_) => setState(() => _filter = 'expense'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transfers.isEmpty)
          Text(l10n.financeLedgerEmpty,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ..._visible.map((t) {
          final isIncome = t.kind == 'income';
          final booking = t.bookingId == null
              ? null
              : widget.bookings
                  .where((b) => b.bookingId == t.bookingId)
                  .firstOrNull;
          final bookingLine = booking == null
              ? null
              : '#${booking.bookingId}'
                  '${booking.customerName == null ? '' : ' • ${booking.customerName}'}';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppCardDecoration.shadow(context)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_categoryLabel(l10n, t.category),
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                          '${_accountName(l10n, t.accountId)} • ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}${t.note != null ? ' • ${t.note}' : ''}',
                          style: Theme.of(context).textTheme.labelSmall),
                      if (bookingLine != null)
                        Text(bookingLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Text(
                  l10n.financeLedgerAmount(isIncome ? '+' : '−', formatRs(t.amountPkr)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isIncome
                          ? AppColors.successTextFor(Theme.of(context).brightness)
                          : AppColors.dangerTextFor(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
          );
        }),
        // Audit §24: the ledger was silently capped at 20 with no
        // count and no way to see the rest. The button label carries
        // the total, and expands the full list in place.
        if (transfers.length > _pageSize && !_showAll)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(l10n.disputesFilterAll(transfers.length)),
            ),
          ),
      ],
    );
  }
}

/// Stored ledger category codes mapped to localized labels — the
/// stored value itself is never changed.
String _categoryLabel(AppLocalizations l10n, String category) => {'rent': l10n.financeCategoryRent, 'advance': l10n.financeCategoryAdvance, 'deposit': l10n.addVehicleReviewDeposit, 'other': l10n.blacklistReasonOther, 'fuel': l10n.financeCategoryFuel, 'maintenance': l10n.fleetFilterMaintenance, 'wash': l10n.financeCategoryWash, 'salary': l10n.financeCategorySalary, 'partner_share': l10n.financeCategoryPartnerShare, 'deposit_refund': l10n.financeCategoryDepositRefund}[category] ?? category;
