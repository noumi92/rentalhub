import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/finance_transfer_data_source.dart';
import '../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../finance/utils/finance_summary.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/finance/report_earnings_chart.dart';
import '../widgets/finance/report_pdf_download_button.dart';
import '../widgets/finance/report_selector.dart';
import '../widgets/finance/report_tables.dart';

/// Audit impl (O37/O38): reports — report cards (Monthly Earnings
/// Report, Car-wise Earnings, Customer History), a period selector,
/// a bar chart built from Flutter primitives (no chart dependency),
/// an all-cars Car — Bookings — Earnings table, and Share Report.
/// Export stays CSV (the `excel` package cannot coexist with the
/// agreement PDF's xml version) — never reintroduce it.
class OwnerReportsView extends StatefulWidget {
  final String shopId;

  const OwnerReportsView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerReportsView> createState() => _OwnerReportsViewState();
}

class _OwnerReportsViewState extends State<OwnerReportsView> {
  List<BookingEntity> _bookings = [];
  List<FinanceTransferEntity> _transfers = [];
  List<VehicleEntity> _vehicles = [];
  String _period = 'this_month';
  String _report = 'monthly';
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
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(widget.shopId);
      final transfers =
          await sl<FinanceTransferDataSource>().getShopTransfers(widget.shopId);
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(widget.shopId);
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _transfers = transfers;
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

  bool _inRange(DateTime t) {
    final range = _range;
    if (range.from != null && t.isBefore(range.from!)) return false;
    if (range.to != null && !t.isBefore(range.to!)) return false;
    return true;
  }

  List<(String, int, int)> get _carRows {
    final periodBookings =
        _bookings.where((b) => _inRange(b.pickupTime)).toList();
    final periodTransfers =
        _transfers.where((t) => _inRange(t.createdAt)).toList();
    final rows = _vehicles.map((v) {
      final pnl = FinanceSummary.vehiclePnL(
        vehicleId: v.vehicleId,
        bookings: periodBookings,
        transfers: periodTransfers,
      );
      final count = periodBookings
          .where((b) =>
              b.vehicleId == v.vehicleId &&
              (b.status == 'completed' ||
                  b.status == 'paid' ||
                  b.status == 'active'))
          .length;
      return (
        v.displayName,
        count,
        pnl.revenue + pnl.income - pnl.expenses,
      );
    }).toList()
      ..sort((a, b) => b.$3.compareTo(a.$3));
    return rows;
  }

  List<(String, int, int)> get _customerRows {
    final periodBookings =
        _bookings.where((b) => _inRange(b.pickupTime)).toList();
    final byCustomer = <String, List<BookingEntity>>{};
    for (final b in periodBookings) {
      byCustomer.putIfAbsent(b.customerId, () => []).add(b);
    }
    return byCustomer.entries
        .map((e) => (
              e.value.first.customerName ?? e.key,
              e.value.length,
              e.value.fold<int>(0, (total, b) => total + b.totalAmount),
            ))
        .toList()
      ..sort((a, b) => b.$3.compareTo(a.$3));
  }

  Future<void> _shareReport() async {
    final rows = <List<String>>[
      ['RentalHub Report', widget.shopId, _period],
      [],
      ['Car', 'Bookings', 'Earnings (Rs)'],
      for (final row in _carRows)
        [row.$1, '${row.$2}', '${row.$3}'],
    ];
    final csv = rows.map((r) => r.join(',')).join('\n');
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(csv),
            name: 'rentalhub-report-$_period.csv',
            mimeType: 'text/csv',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.reportTitle,
              subtitle: l10n.reportSubtitle,
              onBack: () => context.pop(),
              actions: [
                // Audit impl (O37): real A4 report PDF; CSV share stays.
                ReportPdfDownloadButton(shopId: widget.shopId, period: _period,
                    bookings: _bookings, carRows: _carRows),
                IconButton(
                  tooltip: l10n.reportShare,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: _shareReport,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError, onRetry: _load)
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
                                  Text(l10n.reportPeriod,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  ReportPeriodDropdown(
                                    period: _period,
                                    onChanged: (v) => setState(
                                        () => _period = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ReportSelector(
                                selected: _report,
                                onSelect: (key) =>
                                    setState(() => _report = key),
                              ),
                              const SizedBox(height: 20),
                              if (_report == 'monthly')
                                ReportEarningsChart(bookings: _bookings),
                              if (_report == 'carwise')
                                ReportCarTable(rows: _carRows),
                              if (_report == 'customer')
                                ReportCustomerTable(rows: _customerRows),
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
