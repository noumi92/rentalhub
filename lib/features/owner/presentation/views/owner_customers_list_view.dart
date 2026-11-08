import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../customer/domain/usecases/get_shop_customers_usecase.dart';
import '../../../customer/utils/customer_grouping.dart';

/// Phase B (C1): the shop's customers — every person who booked,
/// rolled up with their booking count, total spent and last booking,
/// plus scanned/guarantor records that have not booked yet. A row
/// expands to that customer's bookings. Blacklisted CNICs are badged.
class OwnerCustomersListView extends StatefulWidget {
  final String? shopId;

  const OwnerCustomersListView({super.key, this.shopId});

  @override
  State<OwnerCustomersListView> createState() => _OwnerCustomersListViewState();
}

class _OwnerCustomersListViewState extends State<OwnerCustomersListView> {
  List<CustomerSummary> _customers = [];
  Set<String> _blacklistedCnics = {};
  bool _loading = true;
  // E2: a load failure used to throw out of [_load] unhandled; it
  // now renders an error state with retry.
  bool _hasError = false;
  String _query = '';
  String? _expandedKey;

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(_shopId);
      final saved = await sl<GetShopCustomersUseCase>()(_shopId);
      final blacklist = await sl<BlacklistRemoteDataSource>().getAllRecords();
      if (!mounted) return;
      setState(() {
        _customers = groupCustomerSummaries(
          bookings: bookings,
          savedCustomers: saved,
        );
        _blacklistedCnics = blacklist
            .where((r) => r.isActive)
            .map((r) => r.cnicNumber.replaceAll('-', '').trim())
            .toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  bool _isBlacklisted(CustomerSummary c) {
    final cnic = c.cnic?.replaceAll('-', '').trim();
    return cnic != null && _blacklistedCnics.contains(cnic);
  }

  List<CustomerSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          (c.cnic ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              // Tab root: no back button. The header's back policy
              // renders one only when the route can pop, which a
              // branch root never can.
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.customersTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(_loading ? l10n.customersLoading : l10n.customersCount(_customers.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: l10n.customersScanCnic,
                  icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                  onPressed: () => context.push('/owner/customers/scan'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.customersSearchHint,
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              // E2: shared loading / error / empty states.
              child: _loading
                  ? AppLoadingState(message: l10n.customersLoadingMessage)
                  : _hasError
                      ? AppErrorState(
                          message: l10n.customersLoadError, onRetry: _load)
                      : filtered.isEmpty
                          ? AppEmptyState(
                              title: l10n.customersEmptyTitle,
                              message: l10n.customersEmptyMessage,
                              actionLabel: l10n.customersScanCnic,
                              actionIcon: Icons.document_scanner_rounded,
                              onAction: () => context.push('/owner/customers/scan'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                final expanded = _expandedKey == c.key;
                                final blacklisted = _isBlacklisted(c);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            c.name.isNotEmpty
                                                ? c.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(c.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            ),
                                            if (blacklisted)
                                              Chip(
                                                label: Text(l10n.customersBlacklisted,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white)),
                                                backgroundColor: Colors.red,
                                                padding: EdgeInsets.zero,
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          [
                                            if (c.phone.isNotEmpty) c.phone,
                                            if (c.cnic != null) c.cnic!,
                                            l10n.customersBookingsLine(c.bookingCount, c.totalSpent),
                                          ].join('\n'),
                                        ),
                                        trailing: Icon(expanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded),
                                        onTap: () => setState(() {
                                          _expandedKey =
                                              expanded ? null : c.key;
                                        }),
                                      ),
                                      if (expanded)
                                        ...c.bookings.map((b) => ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: 18),
                                              title: Text(
                                                  '${b.vehicleName ?? l10n.summaryVehicle} • ${b.packageType}'),
                                              subtitle: Text(
                                                  '${b.pickupTime.day}/${b.pickupTime.month}/${b.pickupTime.year} • ${_statusLabel(l10n, b.status)}'),
                                              trailing: Text(
                                                  l10n.amountRs(b.totalAmount),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800)),
                                            )),
                                      if (expanded && c.bookings.isEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 12),
                                          child: Text(
                                              l10n.customersNoBookings,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stored booking statuses mapped to localized labels — the stored
/// value itself is never changed.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
