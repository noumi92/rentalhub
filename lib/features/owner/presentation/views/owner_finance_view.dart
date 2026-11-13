import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
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
import '../widgets/finance/finance_hub_header.dart';
import '../widgets/finance/finance_ledger_section.dart';
import '../widgets/finance/finance_overview_section.dart';
import '../widgets/finance/finance_reports_section.dart';
import '../widgets/finance/finance_summary_cards.dart';

/// Phase B (H): the finance hub — accounts and their live
/// balances, the ledger, the deposits held, partners, and the
/// month's P&L. Audit impl (O34): Overview / Transactions /
/// Reports tabs, a period selector, and separate earnings /
/// expenses / net summary cards. Dues, cash closing and per-car
/// P&L live on their own screens, linked from here.
class OwnerFinanceView extends StatefulWidget {
  final String shopId;

  const OwnerFinanceView({super.key, required this.shopId});

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
  String _tab = 'overview';
  String _period = 'this_month';

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
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ({DateTime? from, DateTime? to}) get _range {
    final now = DateTime.now();
    switch (_period) {
      case 'last_month':
        return (
          from: DateTime(now.year, now.month - 1),
          to: DateTime(now.year, now.month),
        );
      case 'all':
        return (from: null, to: null);
      case 'this_month':
      default:
        return (
          from: DateTime(now.year, now.month),
          to: DateTime(now.year, now.month + 1),
        );
    }
  }

  ({int income, int expenses, int net}) get _periodTotals {
    final range = _range;
    return FinanceSummary.periodTotals(_transfers,
        from: range.from, to: range.to);
  }

  int get _periodBookingRevenue {
    final range = _range;
    return _bookings
        .where((b) =>
            (b.status == 'completed' ||
                b.status == 'paid' ||
                b.status == 'active') &&
            (range.from == null || !b.pickupTime.isBefore(range.from!)) &&
            (range.to == null || b.pickupTime.isBefore(range.to!)))
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
    final month = _periodTotals;
    final earnings = _periodBookingRevenue + month.income;
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
                          FinanceSummaryCards(
                            earnings: earnings,
                            expenses: month.expenses,
                          ),
                          const SizedBox(height: 12),
                          FinanceHubHeader(
                            tab: _tab,
                            period: _period,
                            onTabChanged: (tab) =>
                                setState(() => _tab = tab),
                            onPeriodChanged: (period) =>
                                setState(() => _period = period),
                          ),
                          const SizedBox(height: 16),
                          if (_tab == 'overview')
                            FinanceOverviewSection(
                              bookingRevenue: _periodBookingRevenue,
                              ledgerIncome: month.income,
                              expenses: month.expenses,
                              periodLabel: _period == 'last_month'
                                  ? l10n.financeLastMonth
                                  : _period == 'all'
                                      ? l10n.financeAllTime
                                      : l10n.financeThisMonth,
                              accounts: _accounts,
                              transfers: _transfers,
                              deposits: _deposits,
                              partners: _partners,
                              onAddAccount: _addAccount,
                              onAddPartner: _addPartner,
                            ),
                          if (_tab == 'transactions')
                            FinanceLedgerSection(
                              transfers: _transfers,
                              accounts: _accounts,
                              bookings: _bookings,
                              onAddTransfer: _addTransfer,
                            ),
                          if (_tab == 'reports')
                            FinanceReportsSection(
                              shopId: widget.shopId,
                              bookings: _bookings,
                              transfers: _transfers,
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
