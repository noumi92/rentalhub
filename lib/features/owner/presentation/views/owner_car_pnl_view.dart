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
import '../../../finance/domain/entities/finance_account_entity.dart';
import '../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../finance/utils/finance_summary.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/car_pnl_widgets.dart';

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
  List<FinanceAccountEntity> _accounts = [];
  String? _vehicleId;
  String _period = 'this_month';
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
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(widget.shopId);
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(widget.shopId);
      final transfers =
          await sl<FinanceTransferDataSource>().getShopTransfers(widget.shopId);
      final accounts =
          await sl<FinanceAccountDataSource>().getShopAccounts(widget.shopId);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          _bookings = bookings;
          _transfers = transfers;
          _accounts = accounts;
          _vehicleId ??= vehicles.firstOrNull?.vehicleId;
        });
      }
    } catch (_) {
      // Audit §27/C4: a failed load used to render as "no cars".
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Audit §27: the same period range as the closing screen's P&L
  /// report (this / last month / all time) — the car P&L was
  /// all-time only.
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

  bool _inRange(DateTime t) {
    final range = _range;
    if (range.from != null && t.isBefore(range.from!)) return false;
    if (range.to != null && !t.isBefore(range.to!)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final periodBookings =
        _bookings.where((b) => _inRange(b.pickupTime)).toList();
    final periodTransfers =
        _transfers.where((t) => _inRange(t.createdAt)).toList();
    final selected = _vehicleId == null
        ? null
        : FinanceSummary.vehiclePnL(
            vehicleId: _vehicleId!,
            bookings: periodBookings,
            transfers: periodTransfers,
          );
    final tagged = _vehicleId == null
        ? const <FinanceTransferEntity>[]
        : periodTransfers.where((t) => t.vehicleId == _vehicleId).toList();
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.financeCarPnl,
              subtitle: l10n.financeCarPnlSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError,
                          onRetry: _load,
                        )
                      : _vehicles.isEmpty
                          ? AppEmptyState(
                              title: l10n.financeCarPnlNoCars,
                              icon: Icons.directions_car_rounded,
                            )
                          : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(l10n.financePnlTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    dropdownColor: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    value: _period,
                                    items: [
                                      DropdownMenuItem(
                                          value: 'this_month',
                                          child:
                                              Text(l10n.financeThisMonth)),
                                      DropdownMenuItem(
                                          value: 'last_month',
                                          child:
                                              Text(l10n.financeLastMonth)),
                                      DropdownMenuItem(
                                          value: 'all',
                                          child: Text(l10n.financeAllTime)),
                                    ],
                                    onChanged: (v) => setState(
                                        () => _period = v ?? 'this_month'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                                        child: Text(v.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _vehicleId = v),
                              ),
                              const SizedBox(height: 16),
                              if (selected != null) ...[
                                CarPnlCard(pnl: selected),
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
                                ...tagged.map((t) => CarPnlTransferRow(
                                      transfer: t,
                                      accountName: _accountName(t.accountId),
                                    )),
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

  String _accountName(String accountId) {
    return _accounts
            .where((a) => a.accountId == accountId)
            .firstOrNull
            ?.name ??
        AppLocalizations.of(context)!.financeAccountFallback;
  }

}
