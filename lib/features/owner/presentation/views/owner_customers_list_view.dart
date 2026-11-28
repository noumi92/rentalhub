import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/usecases/get_shop_customers_usecase.dart';
import '../../../customer/utils/customer_grouping.dart';
import '../widgets/customer_add_pill.dart';
import '../widgets/customer_list_filter_chips.dart';
import '../widgets/customer_list_row_card.dart';
import '../widgets/customer_status_helpers.dart';

/// Phase B (C1): the shop's customers — every person who booked,
/// rolled up with their booking count, total spent and last booking,
/// plus scanned/guarantor records that have not booked yet. A row
/// expands to that customer's bookings. Blacklisted CNICs are badged.
///
/// Walk-in CRM: a customer the shop archived (`shopStatuses`) is
/// hidden from this list entirely, whatever the filter; a blocked
/// customer stays visible (with a badge and a filter segment) but
/// cannot be picked for a new booking (see
/// [ManualBookingCustomerStep]). A blocked customer with dues can
/// still pay those dues — the block stops NEW bookings only.
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
    if (_shopId.trim().isEmpty) {
      if (mounted) setState(() { _customers = []; _loading = false; });
      return;
    }
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

  /// This shop's stored per-shop status for a row ('active' when
  /// the row has no saved record or no entry for this shop).
  String _shopStatus(CustomerSummary c) => shopStatusFor(c.savedRecord, _shopId);

  bool _isArchived(CustomerSummary c) => _shopStatus(c) == CustomerEntity.statusArchived;

  /// Archived rows never reach the list, the counts or the search
  /// — hiding is not a filter, it is unconditional.
  List<CustomerSummary> get _visibleCustomers => _customers.where((c) => !_isArchived(c)).toList();

  // O11 classification (Item 5, 2026-11-21): Regular = 2+ rentals,
  // New = 0–1 rentals, Blacklisted = CNIC on the active blacklist,
  // With Dues = an approved/paid/active/completed booking with a
  // remaining balance (dues-screen definition, from already-loaded
  // bookings), Pending Approval = an ONLINE saved record whose
  // approvalStatus is 'pending' (walk-in records sit at 'pending'
  // forever — approve/reject was removed for walk-ins — so they
  // never match), Blocked = this shop's stored per-shop status.
  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};
  bool _hasDues(CustomerSummary c) => c.bookings.any((b) => _dueStatuses.contains(b.status) && b.remainingBalance > 0);
  bool _matchesFilter(CustomerSummary c, CustomerListFilter filter) => switch (filter) {
        CustomerListFilter.all => true,
        CustomerListFilter.regular => c.bookingCount >= 2,
        CustomerListFilter.isNew => c.bookingCount <= 1,
        CustomerListFilter.blacklisted => _isBlacklisted(c),
        CustomerListFilter.withDues => _hasDues(c),
        CustomerListFilter.pendingApproval => c.savedRecord?.approvalStatus == 'pending' && c.savedRecord?.source == 'online',
        CustomerListFilter.blocked => _shopStatus(c) == CustomerEntity.statusBlocked,
      };

  // Fleet-style counts over the visible list (before the search
  // query), like the fleet bar — archived rows count nowhere.
  int _countFor(CustomerListFilter filter) => _visibleCustomers.where((c) => _matchesFilter(c, filter)).length;

  List<CustomerSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    final byQuery = q.isEmpty ? _visibleCustomers : _visibleCustomers.where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q) || (c.cnic ?? '').toLowerCase().contains(q)).toList();
    return byQuery.where((c) => _matchesFilter(c, _chipFilter)).toList();
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
              title: l10n.customersManagementTitle,
              subtitle: _loading ? l10n.customersLoading : l10n.customersCount(_visibleCustomers.length),
              actions: [
                // Item 5 (2026-11-21): Add Customer moved from
                // the extended FAB (heroTag 'customers-add', build
                // 83) into the app bar as the fleet header's orange
                // pill — same destination ('/owner/customers/add').
                // The FAB overlapped the list on a phone; the action
                // itself is kept, only its position changed.
                CustomerAddPill(onPressed: () => context.push('/owner/customers/add')),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.customersScanCnic,
                  icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                  onPressed: () => context.push('/owner/customers/scan'),
                ),
              ],
            ),
            // Audit §18: search is 52dp, radius 16, borderSubtle
            // border, with a clear button. The full-width Add
            // Customer banner that used to sit below it is gone —
            // the action lives in the app bar pill (Item 5).
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
            // O11: filter chips — fleet-style bar with counts; the
            // alert segments (Blacklisted / With Dues / Pending
            // Approval / Blocked) hide at zero count.
            CustomerListFilterChips(
              selected: _chipFilter,
              allCount: _countFor(CustomerListFilter.all), regularCount: _countFor(CustomerListFilter.regular), newCount: _countFor(CustomerListFilter.isNew),
              blacklistedCount: _countFor(CustomerListFilter.blacklisted), withDuesCount: _countFor(CustomerListFilter.withDues),
              pendingApprovalCount: _countFor(CustomerListFilter.pendingApproval), blockedCount: _countFor(CustomerListFilter.blocked),
              onSelected: (f) => setState(() => _chipFilter = f),
            ),
            Expanded(
              // E2: shared loading / error / empty states.
              child: _loading
                  ? AppLoadingState(message: l10n.customersLoadingMessage)
                  : _hasError
                      ? AppErrorState(message: l10n.customersLoadError, onRetry: _load)
                      : filtered.isEmpty
                          ? AppEmptyState(title: l10n.customersEmptyTitle, message: l10n.customersEmptyMessage, actionLabel: l10n.customersScanCnic, actionIcon: Icons.document_scanner_rounded, onAction: () => context.push('/owner/customers/scan'))
                          : RefreshIndicator(
                              // Pull-to-refresh (user layout,
                              // 2026-11-16): re-runs [_load].
                              onRefresh: _load,
                              child: ListView.builder(
                              // Short lists must stay draggable or
                              // the indicator never triggers.
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final c = filtered[index];
                                final badges = rowStatusBadges(c, _shopId);
                                return CustomerListRowCard(
                                  customer: c,
                                  blacklisted: _isBlacklisted(c),
                                  blocked: badges.blocked,
                                  kycIncomplete: badges.kycIncomplete,
                                  dormant: badges.dormant,
                                  isLast: index == filtered.length - 1,
                                );
                              },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
