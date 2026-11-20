import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/presentation/widgets/shop_payment_account.dart';
import '../../../../fleet/data/datasources/fleet_remote_data_source.dart';
import 'approve_terms_summary.dart';

/// O18: approve a booking AND assign the payment account in one
/// step. The old flow was a one-tap status flip with no account, no
/// terms and no deadline; the customer then saw every shop account
/// and paid into whichever one they guessed.
///
/// The sheet lists the shop's real accounts (same `bank_accounts`
/// shape the customer sees), shows the terms ([ApproveTermsSummary]),
/// and on confirm writes status 'approved' plus the chosen account
/// number ([ShopPaymentAccount.number]) and the deadline (now + 30
/// minutes). The deadline is DISPLAY-ONLY: no job auto-cancels or
/// expires the booking on it.
Future<void> showApproveBookingSheet(
  BuildContext context, {
  required BookingEntity booking,
  required ValueChanged<BookingEntity> onApproved,
  List<ShopPaymentAccount>? accounts,
  int? securityDepositPkr,
  FirebaseFirestore? firestore,
  BookingRemoteDataSource? dataSource,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => ApproveBookingSheet(
      booking: booking,
      onApproved: onApproved,
      accounts: accounts,
      securityDepositPkr: securityDepositPkr,
      firestore: firestore,
      dataSource: dataSource,
    ),
  );
}

class ApproveBookingSheet extends StatefulWidget {
  const ApproveBookingSheet({
    super.key,
    required this.booking,
    required this.onApproved,
    this.accounts,
    this.securityDepositPkr,
    this.firestore,
    this.dataSource,
  });

  final BookingEntity booking;
  final ValueChanged<BookingEntity> onApproved;

  /// Preloaded accounts / deposit, for tests. Production loads
  /// both (accounts from the shop doc, deposit from the vehicle).
  final List<ShopPaymentAccount>? accounts;
  final int? securityDepositPkr;

  /// Injectable Firestore for tests; production uses the default
  /// instance (see [ShopPaymentAccount.fetch]).
  final FirebaseFirestore? firestore;

  /// Injectable data source for tests; production resolves it
  /// from the service locator.
  final BookingRemoteDataSource? dataSource;

  @override
  State<ApproveBookingSheet> createState() => _ApproveBookingSheetState();
}

class _ApproveBookingSheetState extends State<ApproveBookingSheet> {
  List<ShopPaymentAccount>? _accounts;
  int? _depositPkr;
  ShopPaymentAccount? _selected;
  bool _processing = false;

  /// Fixed at open, so the deadline the owner sees is the one
  /// written on confirm.
  late final DateTime _deadline =
      DateTime.now().add(const Duration(minutes: 30));

  @override
  void initState() {
    super.initState();
    _depositPkr = widget.securityDepositPkr;
    if (widget.accounts != null) {
      _accounts = widget.accounts;
    } else {
      _loadAccounts();
    }
    if (_depositPkr == null) _loadDeposit();
  }

  Future<void> _loadAccounts() async {
    final accounts = await ShopPaymentAccount.fetch(
      widget.booking.shopId,
      firestore: widget.firestore,
    );
    if (mounted) setState(() => _accounts = accounts);
  }

  Future<void> _loadDeposit() async {
    try {
      final vehicles = await sl<FleetRemoteDataSource>()
          .getShopVehicles(widget.booking.shopId);
      final match = vehicles.where((v) => v.vehicleId == widget.booking.vehicleId);
      if (match.isNotEmpty && mounted) {
        setState(() => _depositPkr = match.first.securityDepositPkr);
      }
    } catch (_) {
      // A failed vehicle read hides the deposit row — the sheet
      // never invents a deposit figure.
    }
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _processing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _processing = true);
    try {
      final ds = widget.dataSource ?? sl<BookingRemoteDataSource>();
      final updated = await ds.updateBookingStatus(
        bookingId: widget.booking.bookingId,
        status: 'approved',
        selectedPaymentAccount: selected.number,
        paymentDeadline: _deadline,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onApproved(updated);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, l10n.requestsApprovalFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = _accounts;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.approveAssignTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.approveAssignChooseAccount,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (accounts == null)
              const Center(child: CircularProgressIndicator())
            else if (accounts.isEmpty)
              Text(
                l10n.approveAssignNoAccounts,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              RadioGroup<ShopPaymentAccount>(
                groupValue: _selected,
                onChanged: (value) {
                  if (_processing) return;
                  setState(() => _selected = value);
                },
                child: Column(
                  children: [
                    for (final account in accounts)
                      RadioListTile<ShopPaymentAccount>(
                        value: account,
                        title: Text(account.methodTitle(l10n)),
                        subtitle: Text(
                            '${account.title} • ${account.number}'.trim()),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // The deposit comes from the vehicle's
            // `securityDepositPkr`, never a hardcoded figure; when
            // the vehicle cannot be read the deposit row is omitted
            // rather than invented.
            ApproveTermsSummary(
              booking: widget.booking,
              depositPkr: _depositPkr,
              deadline: _deadline,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selected == null || _processing ? null : _confirm,
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.approveAssignConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
