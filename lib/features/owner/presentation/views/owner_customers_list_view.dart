import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../customer/domain/usecases/get_shop_customers_usecase.dart';
import '../../../customer/utils/customer_grouping.dart';
import '../widgets/owner_bottom_nav.dart';

/// Phase B (C1): the shop's customers — every person who booked,
/// rolled up with their booking count, total spent and last booking,
/// plus scanned/guarantor records that have not booked yet. A row
/// expands to that customer's bookings. Blacklisted CNICs are badged.
class OwnerCustomersListView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onBack;

  const OwnerCustomersListView({super.key, this.shopId, this.onBack});

  @override
  State<OwnerCustomersListView> createState() =>
      _OwnerCustomersListViewState();
}

class _OwnerCustomersListViewState extends State<OwnerCustomersListView> {
  List<CustomerSummary> _customers = [];
  Set<String> _blacklistedCnics = {};
  bool _loading = true;
  String _query = '';
  String? _expandedKey;

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 3),
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack ?? () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customers',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  Text(
                      _loading
                          ? 'Loading…'
                          : '${_customers.length} customers',
                      style: const TextStyle(
                          color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Scan a CNIC',
                  icon: const Icon(Icons.document_scanner_rounded,
                      color: Colors.white),
                  onPressed: () =>
                      context.push('/owner/customers/scan'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search name, phone or CNIC',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                              'No customers yet — scan a CNIC or take a walk-in booking.'))
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
                                      backgroundColor:
                                          AppColors.royalNavy,
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
                                          const Chip(
                                            label: Text('Blacklisted',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white)),
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.zero,
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      [
                                        if (c.phone.isNotEmpty) c.phone,
                                        if (c.cnic != null) c.cnic!,
                                        '${c.bookingCount} booking${c.bookingCount == 1 ? '' : 's'} • Rs. ${c.totalSpent}',
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
                                              '${b.vehicleName ?? 'Vehicle'} • ${b.packageType}'),
                                          subtitle: Text(
                                              '${b.pickupTime.day}/${b.pickupTime.month}/${b.pickupTime.year} • ${b.status}'),
                                          trailing: Text('Rs. ${b.totalAmount}',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w800)),
                                        )),
                                  if (expanded && c.bookings.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Text(
                                          'No bookings yet — saved from a CNIC scan or as a guarantor.',
                                          style: TextStyle(fontSize: 12)),
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
