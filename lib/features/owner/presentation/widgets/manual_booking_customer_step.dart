import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_status_helpers.dart';
import 'guarantor_picker.dart';
import 'manual_booking_customer_card.dart';

/// O21: step 1 — pick a REGISTERED customer. No new customer is
/// ever typed here: search the shop's saved customers (name / phone
/// / CNIC), tap a card; a blacklisted or blocked customer cannot be
/// selected, and an archived customer never appears in the pick
/// list at all. An unregistered walk-in goes to the full Add
/// Customer (KYC) flow via [onAddNewCustomer] and returns through
/// the customer-added screen's Start Booking action, which prefills
/// this step.
/// Cards show the live trust score, blacklist state (loaded once,
/// the customers-list pattern), KYC state (photo + licence, the
/// triage-checklist definition) and the saved-signature indicator.
class ManualBookingCustomerStep extends StatefulWidget {
  const ManualBookingCustomerStep({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onAddNewCustomer,
    required this.onGuarantorChanged,
    this.prefilledCnic,
    this.prefilledName,
    this.prefilledPhone,
    this.initialCustomers,
    this.blacklistedCnics,
    this.trustScoreOverrides,
  });

  final CustomerEntity? selected;
  final ValueChanged<CustomerEntity> onSelected;
  /// Called with the current search text, so the Add Customer flow
  /// can prefill the CNIC when the owner already typed one.
  final ValueChanged<String> onAddNewCustomer;
  final ValueChanged<GuarantorSelection?> onGuarantorChanged;

  /// Prefill from an entry point (Customers list / Convert to
  /// manual / customer-added screen): the matching saved customer
  /// is auto-selected once the list loads.
  final String? prefilledCnic;
  final String? prefilledName;
  final String? prefilledPhone;

  /// Test overrides: skip the data sources entirely and use these.
  final List<CustomerEntity>? initialCustomers;
  final Set<String>? blacklistedCnics;
  final Map<String, double>? trustScoreOverrides;

  @override
  State<ManualBookingCustomerStep> createState() =>
      _ManualBookingCustomerStepState();
}

class _ManualBookingCustomerStepState
    extends State<ManualBookingCustomerStep> {
  final _searchController = TextEditingController();
  List<CustomerEntity> _customers = [];
  Set<String> _blacklisted = {};
  bool _loading = true;
  bool _loadFailed = false;
  bool _prefillTried = false;
  String _query = '';

  static String _digits(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.initialCustomers != null) {
      if (!mounted) return;
      setState(() {
        // Archived customers never appear in the pick list.
        _customers = _visible(widget.initialCustomers!);
        _blacklisted = widget.blacklistedCnics ?? {};
        _loading = false;
      });
      _tryPrefill();
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      if (!sl.isRegistered<CustomerRemoteDataSource>()) {
        throw StateError('CustomerRemoteDataSource not registered');
      }
      final customers = await sl<CustomerRemoteDataSource>().getShopCustomers(currentShopId());
      var blacklisted = <String>{};
      if (sl.isRegistered<BlacklistRemoteDataSource>()) {
        final records = await sl<BlacklistRemoteDataSource>().getAllRecords();
        blacklisted = records.where((r) => r.isActive).map((r) => _digits(r.cnicNumber)).toSet();
      }
      if (!mounted) return;
      setState(() {
        _customers = _visible(customers);
        _blacklisted = blacklisted;
        _loading = false;
      });
      _tryPrefill();
    } catch (_) {
      if (mounted) setState(() { _loadFailed = true; _loading = false; });
    }
  }

  /// Prefill match: CNIC first, then name + phone. A blacklisted
  /// or blocked match is never auto-selected.
  CustomerEntity? get _prefillMatch {
    final cnic = _digits(widget.prefilledCnic);
    if (cnic.isNotEmpty) {
      for (final c in _customers) {
        if (_digits(c.cnic) == cnic) return c;
      }
    }
    final name = (widget.prefilledName ?? '').trim().toLowerCase();
    final phone = _digits(widget.prefilledPhone);
    if (name.isEmpty && phone.isEmpty) return null;
    for (final c in _customers) {
      final nameOk = name.isEmpty || c.name.trim().toLowerCase() == name;
      final phoneOk = phone.isEmpty || _digits(c.phone) == phone;
      if (nameOk && phoneOk) return c;
    }
    return null;
  }

  void _tryPrefill() {
    if (_prefillTried || widget.selected != null) return;
    _prefillTried = true;
    final match = _prefillMatch;
    if (match != null && !_isBlacklisted(match) && !_isBlocked(match)) widget.onSelected(match);
  }

  bool get _hasPrefill => (widget.prefilledCnic ?? '').trim().isNotEmpty || (widget.prefilledName ?? '').trim().isNotEmpty;

  bool get _prefillUnmatched => _hasPrefill && !_loading && !_loadFailed && widget.selected == null && _prefillMatch == null;

  bool _isBlacklisted(CustomerEntity c) {
    final cnic = _digits(c.cnic);
    return cnic.isNotEmpty && _blacklisted.contains(cnic);
  }

  /// Walk-in CRM guard — the same shape as [_isBlacklisted], over
  /// the stored per-shop status instead of the CNIC list. The shop
  /// id is the one this step already loads with
  /// (`currentShopId()`); [shopStatusFor] also matches the
  /// `shop_<uid>` document-id form of the key.
  bool _isBlocked(CustomerEntity c) =>
      shopStatusFor(c, currentShopId()) == CustomerEntity.statusBlocked;

  bool _isArchived(CustomerEntity c) =>
      shopStatusFor(c, currentShopId()) == CustomerEntity.statusArchived;

  /// Archived customers never appear in the pick list at all.
  List<CustomerEntity> _visible(List<CustomerEntity> customers) =>
      customers.where((c) => !_isArchived(c)).toList();

  /// KYC on file (triage checklist): profile photo + licence number.
  bool _kycDone(CustomerEntity c) => c.profilePhotoUrl != null && c.licenseNumber != null;

  List<CustomerEntity> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q) || (c.cnic ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('manual-booking-customer-search'),
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: l10n.manualBookingSearchCustomers,
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text(l10n.customersLoadingMessage),
            ],
          )
        else if (_loadFailed) ...[
          Text(l10n.customersLoadError, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.dangerTextFor(brightness))),
          TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(l10n.commonRetry)),
        ] else if (_customers.isEmpty)
          Text(l10n.manualBookingNoCustomers, style: Theme.of(context).textTheme.bodySmall)
        else if (_filtered.isEmpty)
          Text(l10n.manualBookingNoMatchingCustomers, style: Theme.of(context).textTheme.bodySmall)
        else
          ..._filtered.map((c) => ManualBookingCustomerCard(
                customer: c,
                selected: widget.selected?.customerId == c.customerId,
                blacklisted: _isBlacklisted(c),
                blocked: _isBlocked(c),
                kycDone: _kycDone(c),
                trustScore: widget.trustScoreOverrides?[c.customerId],
                onSelected: widget.onSelected,
              )),
        if (_prefillUnmatched)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.manualBookingCustomerNotRegistered, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warningTextFor(brightness))),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('manual-booking-add-customer'),
            onPressed: () => widget.onAddNewCustomer(_searchController.text.trim()),
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: Text(l10n.manualBookingAddNewCustomer),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.manualBookingAddNewCustomerHint, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 18),
        Text(l10n.manualBookingGuarantorSection, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GuarantorPicker(onChanged: widget.onGuarantorChanged),
      ],
    );
  }
}
