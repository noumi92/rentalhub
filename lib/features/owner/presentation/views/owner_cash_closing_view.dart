import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/cash_closing_data_source.dart';
import '../../../finance/data/datasources/finance_account_data_source.dart';
import '../../../finance/data/datasources/finance_transfer_data_source.dart';
import '../../../finance/domain/entities/cash_closing_entity.dart';
import '../../../finance/domain/entities/finance_account_entity.dart';
import '../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../finance/utils/finance_summary.dart';
import '../widgets/finance/cash_closing_cards.dart';
import '../widgets/finance/cash_closing_history.dart';
import '../widgets/finance/cash_closing_form.dart';
import '../widgets/finance/finance_pnl_report.dart';
import '../../../../core/utils/money_format.dart';

/// Phase B (H5): the day's cash closing — what the till should
/// hold (computed from the cash account, never typed in), what the
/// owner counted, and the difference. Below it, the P&L statement
/// with a CSV export.
class OwnerCashClosingView extends StatefulWidget {
  final String shopId;

  const OwnerCashClosingView({super.key, required this.shopId});

  @override
  State<OwnerCashClosingView> createState() => _OwnerCashClosingViewState();
}

class _OwnerCashClosingViewState extends State<OwnerCashClosingView> {
  List<FinanceAccountEntity> _accounts = [];
  List<FinanceTransferEntity> _transfers = [];
  List<BookingEntity> _bookings = [];
  List<CashClosingEntity> _closings = [];
  final _countedController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadShopName();
  }

  // Audit §26: the P&L CSV was labelled with the raw shop id — load the real shop name like Settings.
  // Shop-id linking (2026-11-15): this IS a `shops` doc read, so the bare UID is resolved to the canonical shop doc id first. The finance reads/writes below pass widget.shopId through, and each finance data source resolves candidates on read and canonicalizes on write, so both id forms match.
  Future<void> _loadShopName() async {
    try {
      FirebaseFirestore? fs;
      try { fs = FirebaseFirestore.instance; } catch (_) {} if (fs == null) return;
      final doc = await fs.collection('shops').doc(await canonicalShopId(fs, currentShopId())).get();
      final name = (doc.data()?['name'] ?? doc.data()?['shopName']) as String?;
      if (name != null && name.isNotEmpty && mounted) {
        setState(() => _shopName = name);
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final accounts =
          await sl<FinanceAccountDataSource>().getShopAccounts(widget.shopId);
      final transfers =
          await sl<FinanceTransferDataSource>().getShopTransfers(widget.shopId);
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(widget.shopId);
      final closings =
          await sl<CashClosingDataSource>().getShopClosings(widget.shopId);
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _transfers = transfers;
          _bookings = bookings;
          _closings = closings;
        });
      }
    } catch (e) { debugPrint('OwnerCashClosingView load failed: $e'); // Audit 2026-11-15 DS-6: raw error logged for diagnostics; the user only ever sees the localized per-screen message.
      // Audit §26/C4: a failed load used to render as "expected Rs. 0".
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  FinanceAccountEntity? get _cashAccount =>
      _accounts.where((a) => a.type == 'cash').firstOrNull ??
      _accounts.where((a) => a.isDefault).firstOrNull;

  int get _expectedCash {
    final cash = _cashAccount;
    if (cash == null) return 0;
    return FinanceSummary.expectedCashToday(
      cashAccount: cash,
      transfers: _transfers,
    );
  }

  int get _openingCash {
    final last = _closings.firstOrNull;
    if (last != null) return last.countedCash;
    return _cashAccount?.openingBalancePkr ?? 0;
  }

  /// Today's cash movement on the cash account, for the expected-cash
  /// breakdown line (opening + cash in − cash out).
  ({int cashIn, int cashOut}) get _todayCashFlow {
    final cash = _cashAccount;
    if (cash == null) return (cashIn: 0, cashOut: 0);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    var cashIn = 0;
    var cashOut = 0;
    for (final t in _transfers) {
      if (t.accountId != cash.accountId) continue;
      if (t.createdAt.isBefore(start) || !t.createdAt.isBefore(end)) continue;
      if (t.kind == 'income') {
        cashIn += t.amountPkr;
      } else {
        cashOut += t.amountPkr;
      }
    }
    return (cashIn: cashIn, cashOut: cashOut);
  }

  Future<void> _saveClosing() async {
  final l10n = AppLocalizations.of(context)!;
    final counted = int.tryParse(_countedController.text.trim());
    if (counted == null) {
      AppFeedback.showError(context, l10n.financeClosingEnterCounted);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await sl<CashClosingDataSource>().saveClosing(
        shopId: widget.shopId,
        date: DateTime.now(),
        openingCash: _openingCash,
        expectedCash: _expectedCash,
        countedCash: counted,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.financeClosingClosed(formatRs(counted - _expectedCash)));
        _countedController.clear();
        _noteController.clear();
        _load();
      }
    } catch (_) {
      // Audit §26: a save failure used to be silent.
      if (mounted) {
        AppFeedback.showError(context, l10n.shopSaveError);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _countedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Audit §26: the difference is null until the owner types — `?? 0` used to show a false difference on first paint.
    final counted = int.tryParse(_countedController.text.trim());
    final diff = counted == null ? null : counted - _expectedCash;
    final flow = _todayCashFlow;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.financeCashClosing,
              subtitle: l10n.financeClosingSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.cashClosingLoadError,
                          onRetry: _load,
                        )
                      : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CashClosingSummaryCard(
                            expectedCash: _expectedCash,
                            openingCash: _openingCash,
                            difference: diff,
                            countedCash: counted,
                            cashInToday: flow.cashIn,
                            cashOutToday: flow.cashOut,
                          ),
                          const SizedBox(height: 12),
                          CashClosingForm(
                            countedController: _countedController,
                            noteController: _noteController,
                            isSaving: _isSaving,
                            onCountedChanged: () => setState(() {}),
                            onSave: _saveClosing,
                          ),
                          const SizedBox(height: 20),
                          FinancePnLReport(
                            shopName: _shopName.isNotEmpty ? _shopName : widget.shopId,
                            bookings: _bookings,
                            transfers: _transfers,
                          ),
                          const SizedBox(height: 20),
                          CashClosingHistory(closings: _closings),
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
