import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../customer/data/services/customer_wallet_service.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/presentation/widgets/security_totals_card.dart';
import '../../../customer/presentation/widgets/wallet_ledger.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../services/customer_detail_controller.dart';

/// Owner side of the customer Security wallet — read-only. Walk-in
/// customers only: their wallets are managed by the shop owner, so
/// the owner sees the same Security totals the customer's own wallet
/// shows (held / released / deducted / refunded / still owed) plus
/// the per-deposit entries. Online customers maintain their own
/// wallet — the entry point never offers this screen for them, and
/// this view refuses their record too, so a deep link cannot open
/// another customer's wallet either.
///
/// Deposits come from [SecurityDepositDataSource.getShopDeposits]
/// filtered by customer (the shop's own records); vehicle names and
/// fallback dates come from the customer's bookings.
class OwnerCustomerSecurityWalletView extends StatefulWidget {
  final String customerId;
  final String? shopId;

  /// The resolved record, passed by the customer detail screen.
  /// When absent (deep link) the view resolves it via
  /// [CustomerDetailController] before deciding walk-in vs online.
  final CustomerEntity? customer;

  /// Test seams — production resolves all three from the locator.
  final SecurityDepositDataSource? deposits;
  final BookingRemoteDataSource? bookings;
  final CustomerDetailController? controller;

  const OwnerCustomerSecurityWalletView({
    super.key,
    required this.customerId,
    this.shopId,
    this.customer,
    this.deposits,
    this.bookings,
    this.controller,
  });

  @override
  State<OwnerCustomerSecurityWalletView> createState() =>
      _OwnerCustomerSecurityWalletViewState();
}

class _OwnerCustomerSecurityWalletViewState
    extends State<OwnerCustomerSecurityWalletView> {
  SecurityTotals _totals = const SecurityTotals();
  List<WalletLedgerEntry> _entries = const [];
  String? _customerName;
  bool _isLoading = true;
  bool _hasError = false;
  // The record is an online customer (or could not be resolved as
  // walk-in): the wallet is theirs to maintain, not the shop's.
  bool _online = false;
  // The locale the current load's entry titles were built for.
  Locale? _titlesLocale;

  String get _shopId => widget.shopId ?? currentShopId();
  SecurityDepositDataSource get _deposits =>
      widget.deposits ?? sl<SecurityDepositDataSource>();
  BookingRemoteDataSource get _bookings =>
      widget.bookings ?? sl<BookingRemoteDataSource>();
  CustomerDetailController get _controller =>
      widget.controller ?? CustomerDetailController();

  @override
  void initState() {
    super.initState();
  }

  /// [_load] reads AppLocalizations, so the load starts here (not
  /// initState): `dependOnInheritedWidget` before initState
  /// completes throws. A locale change re-loads with the new
  /// language's titles.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_titlesLocale != locale) {
      _titlesLocale = locale;
      _load();
    }
  }

  Future<void> _load() async {
    // Localized entry wording is captured before the first await —
    // using context across the awaits below trips
    // use_build_context_synchronously.
    final l10n = AppLocalizations.of(context)!;
    final titles = WalletEntryTitles(
      securityHeld: l10n.walletEntrySecurityHeld,
      securityReleased: l10n.walletEntrySecurityReleased,
      securityReleasedOnCancel: l10n.walletEntrySecurityReleasedCancel,
      securityDeducted: l10n.walletEntrySecurityDeducted,
      securityRefunded: l10n.walletEntrySecurityRefunded,
      securityOwed: l10n.walletEntrySecurityOwed,
    );
    if (mounted) {
      setState(() {
        _hasError = false;
        _online = false;
      });
    }
    try {
      var customer = widget.customer;
      customer ??= (await _controller.load(
              customerId: widget.customerId, shopId: _shopId))
          .customer;
      // Fail closed: no record, or an online record, is never
      // shown as a shop-managed wallet.
      if (customer == null || customer.source != 'walk_in') {
        if (mounted) {
          setState(() {
            _online = true;
            _isLoading = false;
          });
        }
        return;
      }
      final deposits = (await _deposits.getShopDeposits(_shopId))
          .where((d) => d.customerId == widget.customerId)
          .toList();
      final bookings =
          await _bookings.getCustomerBookings(widget.customerId);
      final byId = {for (final b in bookings) b.bookingId: b};
      final entries = <WalletLedgerEntry>[];
      for (final d in deposits) {
        final booking = byId[d.bookingId];
        entries.addAll(CustomerWalletService.securityEntriesFor(
          deposit: d,
          vehicle: booking?.vehicleName ?? 'Rental Car',
          bookingId: d.bookingId,
          // A deposit with no booking on file falls back to its own
          // timestamps; sorting still puts the newest first.
          pickupTime: booking?.pickupTime ??
              d.collectedAt ??
              DateTime.now(),
          returnTime: booking?.returnTime ??
              d.releasedAt ??
              d.deductedAt ??
              DateTime.now(),
          titles: titles,
        ));
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _customerName = customer?.name;
        _totals = SecurityTotals.fromDeposits(deposits);
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
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
              title: l10n.ownerSecurityWalletTitle,
              subtitle: _customerName,
            ),
            Expanded(
              child: _isLoading
                  ? AppLoadingState(message: l10n.walletLoading)
                  : _hasError
                      ? AppErrorState(
                          message: l10n.walletLoadError,
                          onRetry: _load)
                      : _online
                          ? AppEmptyState(
                              title: l10n.ownerSecurityWalletOnline,
                              icon: Icons.lock_rounded,
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: !_totals.hasActivity
                                    ? AppEmptyState(
                                        title: l10n
                                            .ownerSecurityWalletEmpty,
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SecurityTotalsCard(
                                              totals: _totals),
                                          const SizedBox(height: 20),
                                          Text(l10n.walletLedger,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                          const SizedBox(height: 10),
                                          WalletLedger(
                                            isLoading: false,
                                            entries: _entries,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
