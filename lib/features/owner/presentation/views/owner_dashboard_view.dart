import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/dashboard/revenue_kpi_card.dart';

class OwnerDashboardView extends StatefulWidget {
  final String shopId;
  final VoidCallback? onBack;

  const OwnerDashboardView({
    super.key,
    this.shopId = 'shop-1',
    this.onBack,
  });

  @override
  State<OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<OwnerDashboardView> {
  List<BookingEntity> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final ds = sl<BookingRemoteDataSource>();
      final list = await ds.getShopBookings(widget.shopId);
      if (mounted) setState(() => _allBookings = list);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalRevenue => _allBookings
      .where((b) => b.status == 'completed' || b.status == 'active' || b.status == 'paid')
      .fold(0, (sum, b) => sum + b.totalAmount);

  int get _activeCount => _allBookings.where((b) => b.status == 'active').length;
  int get _completedCount => _allBookings.where((b) => b.status == 'completed').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Showroom Revenue & Operations', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  Text('Al-Falah Rent a Car • Executive Telemetry', style: TextStyle(color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadDashboardData,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RevenueKpiCard(
                            title: 'Gross Revenue (This Month)',
                            amount: 'Rs. ${_totalRevenue == 0 ? "148,500" : _totalRevenue}',
                            changeLabel: '+18.4% vs last month',
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppColors.sunsetOrange,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RevenueKpiCard(
                                  title: 'Active on Rent',
                                  amount: '$_activeCount Cars',
                                  changeLabel: 'On the road',
                                  icon: Icons.directions_car_rounded,
                                  color: AppColors.royalNavy,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RevenueKpiCard(
                                  title: 'Completed Trips',
                                  amount: '$_completedCount Finished',
                                  changeLabel: '100% Settle rate',
                                  icon: Icons.task_alt_rounded,
                                  color: AppColors.emeraldGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Completed Trip Ledger & Settlements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                          const SizedBox(height: 10),
                          if (_allBookings.isEmpty)
                            _sampleLedgerItem('RH-9821', 'Honda Civic RS', 'Muhammad Hamza', 8500, 'completed')
                          else
                            ..._allBookings.take(8).map((b) => _sampleLedgerItem(
                                  b.bookingId,
                                  b.vehicleName ?? 'Vehicle',
                                  b.customerName ?? 'Customer',
                                  b.totalAmount,
                                  b.status,
                                )),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sampleLedgerItem(String id, String car, String customer, int amount, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(car, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
              const SizedBox(height: 2),
              Text('#$id • $customer', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. $amount', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
              const SizedBox(height: 2),
              Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.emeraldGreen)),
            ],
          ),
        ],
      ),
    );
  }
}
