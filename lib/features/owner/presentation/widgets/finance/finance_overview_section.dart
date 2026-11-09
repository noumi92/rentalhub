import 'package:flutter/material.dart';

import '../../../../finance/domain/entities/finance_account_entity.dart';
import '../../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../../finance/domain/entities/partner_share_entity.dart';
import '../../../../finance/domain/entities/security_deposit_entity.dart';
import 'finance_accounts_section.dart';
import 'finance_deposits_section.dart';
import 'finance_month_summary.dart';
import 'finance_partners_section.dart';

/// Audit impl (O34): the finance hub's Overview tab — the month
/// summary (with its links to dues, cash closing and car P&L),
/// accounts, deposits and partners. Extracted from
/// [OwnerFinanceView] so the view stays under the 250-line cap.
class FinanceOverviewSection extends StatelessWidget {
  final int bookingRevenue;
  final int ledgerIncome;
  final int expenses;
  final String periodLabel;
  final List<FinanceAccountEntity> accounts;
  final List<FinanceTransferEntity> transfers;
  final List<SecurityDepositEntity> deposits;
  final List<PartnerShareEntity> partners;
  final VoidCallback onAddAccount;
  final VoidCallback onAddPartner;

  const FinanceOverviewSection({
    super.key,
    required this.bookingRevenue,
    required this.ledgerIncome,
    required this.expenses,
    required this.periodLabel,
    required this.accounts,
    required this.transfers,
    required this.deposits,
    required this.partners,
    required this.onAddAccount,
    required this.onAddPartner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FinanceMonthSummary(
          bookingRevenue: bookingRevenue,
          ledgerIncome: ledgerIncome,
          expenses: expenses,
          periodLabel: periodLabel,
        ),
        const SizedBox(height: 16),
        FinanceAccountsSection(
          accounts: accounts,
          transfers: transfers,
          onAddAccount: onAddAccount,
        ),
        const SizedBox(height: 16),
        FinanceDepositsSection(deposits: deposits),
        const SizedBox(height: 16),
        FinancePartnersSection(
          partners: partners,
          onAddPartner: onAddPartner,
        ),
      ],
    );
  }
}
