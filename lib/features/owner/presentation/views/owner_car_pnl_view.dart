import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Car P&L',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('One car, all its money',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _vehicles.isEmpty
                      ? Center(
                          child: Text('No cars in the fleet yet.',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                dropdownColor: Theme.of(context).colorScheme.surface,
                                initialValue: _vehicleId,
                                decoration: InputDecoration(
                                    labelText: 'Vehicle',
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest),
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
                                Text('Tagged entries',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                if (tagged.isEmpty)
                                  Text(
                                      'Nothing tagged to this car yet — tag an entry in the ledger.',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  Widget _pnlCard(
      ({int revenue, int income, int expenses, int net}) pnl) {
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
          Text('Net Rs. ${pnl.net}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
              'Booking revenue Rs. ${pnl.revenue} • Other income Rs. ${pnl.income} • Expenses Rs. ${pnl.expenses}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _transferRow(FinanceTransferEntity t) {
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
          Text(t.category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(
            '${isIncome ? '+' : '−'} Rs. ${t.amountPkr}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: isIncome ? AppColors.successTextFor(Theme.of(context).brightness) : AppColors.dangerTextFor(Theme.of(context).brightness)),
          ),
        ],
      ),
    );
  }
}
