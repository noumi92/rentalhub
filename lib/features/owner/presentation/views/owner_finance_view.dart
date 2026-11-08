import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/finance_account_data_source.dart';
import '../../../finance/data/datasources/finance_transfer_data_source.dart';
import '../../../finance/data/datasources/partner_share_data_source.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/domain/entities/finance_account_entity.dart';
import '../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../finance/domain/entities/partner_share_entity.dart';
import '../../../finance/domain/entities/security_deposit_entity.dart';
import '../../../finance/utils/finance_summary.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/finance/add_transfer_sheet.dart';
import '../widgets/finance/finance_dialogs.dart';
import '../widgets/finance/finance_month_summary.dart';
import '../widgets/finance/finance_accounts_section.dart';
import '../widgets/finance/finance_deposits_section.dart';
import '../widgets/finance/finance_ledger_section.dart';
import '../widgets/finance/finance_partners_section.dart';

/// Phase B (H): the finance hub — accounts and their live
/// balances, the ledger, the deposits held, partners, and the
/// month's P&L. Dues, cash closing and per-car P&L live on their
/// own screens, linked from here.
class OwnerFinanceView extends StatefulWidget {
  final String shopId;

  const OwnerFinanceView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerFinanceView> createState() => _OwnerFinanceViewState();
}

class _OwnerFinanceViewState extends State<OwnerFinanceView> {
  List<FinanceAccountEntity> _accounts = [];
  List<FinanceTransferEntity> _transfers = [];
  List<SecurityDepositEntity> _deposits = [];
  List<PartnerShareEntity> _partners = [];
  List<BookingEntity> _bookings = [];
  List<VehicleEntity> _vehicles = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final shopId = widget.shopId;
      final accounts =
          await sl<FinanceAccountDataSource>().getShopAccounts(shopId);
      final transfers =
          await sl<FinanceTransferDataSource>().getShopTransfers(shopId);
      final deposits =
          await sl<SecurityDepositDataSource>().getShopDeposits(shopId);
      final partners =
          await sl<PartnerShareDataSource>().getShopPartners(shopId);
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(shopId);
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(shopId);
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _transfers = transfers;
          _deposits = deposits;
          _partners = partners;
          _bookings = bookings;
          _vehicles = vehicles;
        });
      }
    } catch (_) {
      // Audit §24/C4: a failed load used to render as "empty / Rs. 0"
      // — surface it with a retry instead.
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ({int income, int expenses, int net}) get _monthTotals {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month);
    final to = DateTime(now.year, now.month + 1);
    return FinanceSummary.periodTotals(_transfers, from: from, to: to);
  }

  int get _monthBookingRevenue {
    final now = DateTime.now();
    return _bookings
        .where((b) =>
            (b.status == 'completed' ||
                b.status == 'paid' ||
                b.status == 'active') &&
            b.pickupTime.year == now.year &&
            b.pickupTime.month == now.month)
        .fold(0, (total, b) => total + b.totalAmount);
  }

  Future<void> _addAccount() async {
    if (await FinanceDialogs.showAddAccount(context, widget.shopId)) {
      _load();
    }
  }

  Future<void> _addPartner() async {
    if (await FinanceDialogs.showAddPartner(context, widget.shopId)) {
      _load();
    }
  }

  Future<void> _addTransfer() async {
    await showDialog(
      context: context,
      builder: (context) => AddTransferSheet(
        shopId: widget.shopId,
        accounts: _accounts,
        vehicles: _vehicles,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final month = _monthTotals;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.finance,
              subtitle: l10n.financeSubtitle,
              onBack: () => context.pop(),
              actions: [
                IconButton(
                  tooltip: l10n.dashboardRefreshTooltip,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _load,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError,
                          onRetry: _load,
                        )
                      : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FinanceMonthSummary(
                            bookingRevenue: _monthBookingRevenue,
                            ledgerIncome: month.income,
                            expenses: month.expenses,
                          ),
                          const SizedBox(height: 16),
                          FinanceAccountsSection(
                            accounts: _accounts,
                            transfers: _transfers,
                            onAddAccount: _addAccount,
                          ),
                          const SizedBox(height: 16),
                          FinanceDepositsSection(deposits: _deposits),
                          const SizedBox(height: 16),
                          FinancePartnersSection(
                            partners: _partners,
                            onAddPartner: _addPartner,
                          ),
                          const SizedBox(height: 16),
                          FinanceLedgerSection(
                            transfers: _transfers,
                            accounts: _accounts,
                            onAddTransfer: _addTransfer,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
