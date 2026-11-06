import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
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
import '../widgets/finance/finance_pnl_report.dart';

/// Phase B (H5): the day's cash closing — what the till should
/// hold (computed from the cash account, never typed in), what the
/// owner counted, and the difference. Below it, the P&L statement
/// with a CSV export.
class OwnerCashClosingView extends StatefulWidget {
  final String shopId;

  const OwnerCashClosingView({super.key, this.shopId = 'shop-1'});

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final accounts =
          await sl<FinanceAccountDataSource>().getShopAccounts(widget.shopId);
      final transfers = await sl<FinanceTransferDataSource>()
          .getShopTransfers(widget.shopId);
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
    } catch (_) {} finally {
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

  int get _counted => int.tryParse(_countedController.text.trim()) ?? 0;

  Future<void> _saveClosing() async {
    final counted = int.tryParse(_countedController.text.trim());
    if (counted == null) {
      AppFeedback.showError(context, 'Enter the counted cash first.');
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
        AppFeedback.showSuccess(context,
            'Day closed — difference Rs. ${counted - _expectedCash}.');
        _countedController.clear();
        _noteController.clear();
        _load();
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
    final diff = _counted - _expectedCash;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash Closing',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text('Count the till, close the day',
                      style: TextStyle(
                          color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _countedController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Counted cash (Rs.)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: 'Note (optional)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: DebouncedButton(
                              text: _isSaving
                                  ? 'Closing...'
                                  : 'Close the day',
                              icon: Icons.lock_rounded,
                              isLoading: _isSaving,
                              onPressed: _saveClosing,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FinancePnLReport(
                            shopName: widget.shopId,
                            bookings: _bookings,
                            transfers: _transfers,
                          ),
                          const SizedBox(height: 20),
                          const Text('Past closings',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.midnightNavy)),
                          const SizedBox(height: 8),
                          if (_closings.isEmpty)
                            const Text('No closings yet.',
                                style:
                                    TextStyle(color: AppColors.textMuted)),
                          ..._closings.take(10).map((c) => CashClosingRow(closing: c)),
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
