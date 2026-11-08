import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/finance_transfer_data_source.dart';
import '../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../finance/utils/finance_summary.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase B (H2): one car's profit and loss — its booking revenue
/// plus the ledger income tagged to it, minus the ledger expenses
/// tagged to it (fuel, maintenance, and the rest).
class OwnerCarPnLView extends StatefulWidget {
  final String shopId;

  const OwnerCarPnLView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerCarPnLView> createState() => _OwnerCarPnLViewState();
}

class _OwnerCarPnLViewState extends State<OwnerCarPnLView> {
  List<VehicleEntity> _vehicles = [];
  List<BookingEntity> _bookings = [];
  List<FinanceTransferEntity> _transfers = [];
  String? _vehicleId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(widget.shopId);
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(widget.shopId);
      final transfers =
          await sl<FinanceTransferDataSource>().getShopTransfers(widget.shopId);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _bookings = bookings;
          _transfers = transfers;
          _vehicleId ??= vehicles.firstOrNull?.vehicleId;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final selected = _vehicleId == null
        ? null
        : FinanceSummary.vehiclePnL(
            vehicleId: _vehicleId!,
            bookings: _bookings,
            transfers: _transfers,
          );
    final tagged = _vehicleId == null
        ? const <FinanceTransferEntity>[]
        : _transfers.where((t) => t.vehicleId == _vehicleId).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.financeCarPnl,
              subtitle: l10n.financeCarPnlSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _vehicles.isEmpty
                      ? Center(
                          child: Text(l10n.financeCarPnlNoCars,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w700)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                dropdownColor:
                                    Theme.of(context).colorScheme.surface,
                                initialValue: _vehicleId,
                                decoration: InputDecoration(
                                    labelText: l10n.summaryVehicle,
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest),
                                items: _vehicles
                                    .map((v) => DropdownMenuItem(
                                        value: v.vehicleId,
                                        child: Text(v.displayName)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _vehicleId = v),
                              ),
                              const SizedBox(height: 16),
                              if (selected != null) ...[
                                _pnlCard(selected),
                                const SizedBox(height: 16),
                                Text(l10n.financeCarPnlTagged,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                if (tagged.isEmpty)
                                  Text(
                                      l10n.financeCarPnlNoTagged,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                ...tagged.map((t) => _transferRow(t)),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pnlCard(({int revenue, int income, int expenses, int net}) pnl) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.financeNetAmount(pnl.net),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
              l10n.financeCarPnlBreakdown(pnl.revenue, pnl.income, pnl.expenses),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _transferRow(FinanceTransferEntity t) {
  final l10n = AppLocalizations.of(context)!;
    final isIncome = t.kind == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_categoryLabel(l10n, t.category),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(
            l10n.financeLedgerAmount(isIncome ? '+' : '−', t.amountPkr),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
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
