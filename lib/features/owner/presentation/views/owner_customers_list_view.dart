import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../customer/domain/usecases/get_shop_customers_usecase.dart';
import '../../../customer/utils/customer_grouping.dart';
import '../widgets/customer_list_filter_chips.dart';
import '../widgets/customer_row_book_action.dart';

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
  final _searchController = TextEditingController();
  String? _expandedKey;
  CustomerListFilter _chipFilter = CustomerListFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final bookings = await sl<BookingRemoteDataSource>().getShopBookings(_shopId);
      final saved = await sl<GetShopCustomersUseCase>()(_shopId);
      final blacklist = await sl<BlacklistRemoteDataSource>().getAllRecords();
      if (!mounted) return;
      setState(() {
        _customers = groupCustomerSummaries(bookings: bookings, savedCustomers: saved);
        _blacklistedCnics = blacklist.where((r) => r.isActive).map((r) => r.cnicNumber.replaceAll('-', '').trim()).toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _loading = false; });
    }
  }

  bool _isBlacklisted(CustomerSummary c) {
    final cnic = c.cnic?.replaceAll('-', '').trim();
    return cnic != null && _blacklistedCnics.contains(cnic);
  }

  // O11 classification: Regular = 2+ rentals, New = 0–1 rentals,
  // Flagged = blacklisted or has dues. "Has dues" is the dues-screen
  // definition: a booking in an approved/paid/active/completed status
  // with a remaining balance — derived from the bookings already
  // loaded for the row, never a new collection.
  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};
  bool _hasDues(CustomerSummary c) => c.bookings.any((b) => _dueStatuses.contains(b.status) && b.remainingBalance > 0);
  bool _matchesChip(CustomerSummary c) => switch (_chipFilter) {
        CustomerListFilter.all => true,
        CustomerListFilter.regular => c.bookingCount >= 2,
        CustomerListFilter.isNew => c.bookingCount <= 1,
        CustomerListFilter.flagged => _isBlacklisted(c) || _hasDues(c),
      };

  List<CustomerSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    final byQuery = q.isEmpty ? _customers : _customers.where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q) || (c.cnic ?? '').toLowerCase().contains(q)).toList();
    return byQuery.where(_matchesChip).toList();
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset — no double status bar.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.customersTitle,
              subtitle: _loading ? l10n.customersLoading : l10n.customersCount(_customers.length),
              actions: [
                IconButton(
                  tooltip: l10n.customersScanCnic,
                  icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                  onPressed: () => context.push('/owner/customers/scan'),
                ),
              ],
            ),
            // Audit §18: search is 52dp, radius 16, borderSubtle
            // border, with a clear button; the labelled Add action
            // below it (the header scan icon, tooltip only, was the
            // only add entry point before).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                height: 52,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.customersSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty ? IconButton(tooltip: l10n.handoverClear, icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () => setState(() { _query = ''; _searchController.clear(); })) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DebouncedButton(text: l10n.addCustomerTitle, icon: Icons.person_add_rounded, onPressed: () => context.push('/owner/customers/add')),
            ),
            // O11: filter chips (All / Regular / New / Flagged).
            CustomerListFilterChips(selected: _chipFilter, onSelected: (f) => setState(() => _chipFilter = f)),
            Expanded(
              // E2: shared loading / error / empty states.
              child: _loading
                  ? AppLoadingState(message: l10n.customersLoadingMessage)
                  : _hasError
                      ? AppErrorState(message: l10n.customersLoadError, onRetry: _load)
                      : filtered.isEmpty
                          ? AppEmptyState(title: l10n.customersEmptyTitle, message: l10n.customersEmptyMessage, actionLabel: l10n.customersScanCnic, actionIcon: Icons.document_scanner_rounded, onAction: () => context.push('/owner/customers/scan'))
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
                                          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                        ),
                                        title: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            if (c.bookingCount >= 2)
                                              Chip(label: Text(l10n.customersBadgeRegular, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)), backgroundColor: AppColors.accentSuccessStrong, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                            if (c.bookingCount <= 1)
                                              Chip(label: Text(l10n.customersBadgeNew, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)), backgroundColor: AppColors.orangeFill, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                            if (blacklisted)
                                              // Audit §18: white on
                                              // Colors.red is 3.68:1 —
                                              // errorDark #DC2626 is
                                              // ~4.9:1. No KYC/trust
                                              // marker: neither the
                                              // entity nor the summary
                                              // carries KYC data.
                                              Chip(label: Text(l10n.customersBlacklisted, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)), backgroundColor: AppColors.errorDark, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                          ],
                                        ),
                                        // Audit §18: subtitle capped at
                                        // 3 lines with ellipsis.
                                        subtitle: Text([if (c.phone.isNotEmpty) c.phone, if (c.cnic != null) c.cnic!, l10n.customersBookingsLine(c.bookingCount, formatRs(c.totalSpent))].join('\n'), maxLines: 3, overflow: TextOverflow.ellipsis),
                                        trailing: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                                        onTap: () => setState(() { _expandedKey = expanded ? null : c.key; }),
                                      ),
                                      if (expanded)
                                        ...c.bookings.map((b) => ListTile(
                                              dense: true,
                                              leading: const Icon(Icons.receipt_long_rounded, size: 18),
                                              title: Text('${b.vehicleName ?? l10n.summaryVehicle} • ${b.packageType}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                              subtitle: Text('${b.pickupTime.day}/${b.pickupTime.month}/${b.pickupTime.year} • ${_statusLabel(l10n, b.status)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                              // C5: grouped amount.
                                              trailing: Text(l10n.amountRs(formatRs(b.totalAmount)), style: const TextStyle(fontWeight: FontWeight.w600)),
                                            )),
                                      if (expanded && c.bookings.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Text(l10n.customersNoBookings, style: Theme.of(context).textTheme.bodySmall),
                                        ),
                                      // #18: Book for this customer —
                                      // wizard opens prefilled (name,
                                      // phone, CNIC); adding the customer
                                      // itself stays a separate step.
                                      if (expanded)
                                        CustomerRowBookAction(customer: c),
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
