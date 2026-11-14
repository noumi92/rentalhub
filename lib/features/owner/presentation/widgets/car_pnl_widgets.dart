import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/theme/card_decoration.dart';

/// Audit §27 (extracted from [OwnerCarPnLView] so the view stays
/// under the 250-line cap): the net card — a loss is coloured with
/// the danger token and prefixed "Loss" instead of looking like a
/// profit — and one tagged ledger row with its date • account line.
class CarPnlCard extends StatelessWidget {
  final ({int revenue, int income, int expenses, int net}) pnl;

  const CarPnlCard({super.key, required this.pnl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The card is navy in both modes, so the loss uses the
    // dark-mode danger text token for contrast.
    final isLoss = pnl.net < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              isLoss
                  ? '${l10n.pnlLoss} • ${l10n.financeNetAmount(formatRs(pnl.net))}'
                  : l10n.financeNetAmount(formatRs(pnl.net)),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isLoss
                      ? AppColors.dangerTextFor(Brightness.dark)
                      : Colors.white)),
          const SizedBox(height: 8),
          Text(
              l10n.financeCarPnlBreakdown(
                  formatRs(pnl.revenue), formatRs(pnl.income), formatRs(pnl.expenses)),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class CarPnlTransferRow extends StatelessWidget {
  final FinanceTransferEntity transfer;
  final String accountName;

  const CarPnlTransferRow({
    super.key,
    required this.transfer,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = transfer;
    final isIncome = t.kind == 'income';
    final locale = Localizations.localeOf(context).languageCode;
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ),
                Text(
                    '${DateFormat.yMMMd(locale).format(t.createdAt)} • $accountName',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            l10n.financeLedgerAmount(isIncome ? '+' : '−', formatRs(t.amountPkr)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isIncome
                    ? AppColors.successTextFor(Theme.of(context).brightness)
                    : AppColors.dangerTextFor(Theme.of(context).brightness)),
          ),
        ],
      ),
    );
  }
}

/// Stored ledger category codes mapped to localized labels — the
/// stored value itself is never changed.
String _categoryLabel(AppLocalizations l10n, String category) => {'rent': l10n.financeCategoryRent, 'deposit': l10n.addVehicleReviewDeposit, 'other': l10n.blacklistReasonOther, 'fuel': l10n.financeCategoryFuel, 'maintenance': l10n.fleetFilterMaintenance, 'salary': l10n.financeCategorySalary, 'partner_share': l10n.financeCategoryPartnerShare, 'deposit_refund': l10n.financeCategoryDepositRefund}[category] ?? category;
