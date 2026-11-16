import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../widgets/customer_detail_header.dart';
import '../widgets/customer_detail_kyc_section.dart';
import '../widgets/customer_reject_reason_dialog.dart';

/// Owner-deck finish — the 1 missing screen (#35): a customer profile.
/// Header (name, phone, CNIC), KYC status, documents/photo, rental
/// history, total spent and blacklist state, plus owner Approve /
/// Reject of the profile. The id is a saved-record id; a booking-only
/// customer (no saved record) still resolves — by CNIC, then from
/// their bookings — with an honest "no KYC record on file" state.
/// Dues use the same definition as the dues screen: an approved /
/// paid / active / completed booking with a remaining balance.
class OwnerCustomerDetailView extends StatefulWidget {
  final String customerId;
  final String? shopId;

  const OwnerCustomerDetailView({super.key, required this.customerId, this.shopId});

  @override
  State<OwnerCustomerDetailView> createState() => _OwnerCustomerDetailViewState();
}

class _OwnerCustomerDetailViewState extends State<OwnerCustomerDetailView> {
  CustomerEntity? _customer;
  List<BookingEntity> _bookings = [];
  bool _blacklisted = false;
  bool _loading = true;
  bool _hasError = false;
  bool _acting = false;

  String get _shopId => widget.shopId ?? currentShopId();
  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};

  String _digits(String? v) => (v ?? '').replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final customerDs = sl<CustomerRemoteDataSource>();
      final bookingDs = sl<BookingRemoteDataSource>();
      final blacklistDs = sl<BlacklistRemoteDataSource>();
      var customer = await customerDs.getCustomerById(widget.customerId);
      customer ??= await customerDs.getCustomerByCnic(_shopId, widget.customerId);
      final all = await bookingDs.getShopBookings(_shopId);
      // Final capture: the `where` closure cannot promote the
      // mutable `customer` local (it is reassigned below).
      final resolved = customer;
      final bookings = all.where((b) {
        if (resolved != null) {
          return b.customerId == resolved.customerId || (_digits(b.customerCnic).isNotEmpty && _digits(b.customerCnic) == _digits(resolved.cnic));
        }
        return b.customerId == widget.customerId || _digits(b.customerCnic) == _digits(widget.customerId);
      }).toList()
        ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
      // No saved record: the customer is known only from bookings.
      // Synthesise a display record from the newest booking instead
      // of showing a fake "not found" for a real customer.
      customer ??= bookings.isEmpty
          ? null
          : CustomerEntity(customerId: bookings.first.customerId, shopId: _shopId, name: bookings.first.customerName ?? '', phone: bookings.first.customerPhone ?? '', cnic: bookings.first.customerCnic, createdAt: bookings.last.pickupTime);
      final blacklisted = customer?.cnic != null && await blacklistDs.isCnicBlacklisted(customer!.cnic!);
      if (!mounted) return;
      setState(() {
        _customer = customer;
        _bookings = bookings;
        _blacklisted = blacklisted;
        _loading = false;
      });
    } catch (_) {
      // OW-M1: the catch used to set only _hasError — build checks _loading first, so a load failure spun forever and the error state below was unreachable.
      if (mounted) setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  int get _totalSpent => _bookings.fold(0, (s, b) => s + b.totalAmount);
  int get _totalDues => _bookings.where((b) => _dueStatuses.contains(b.status) && b.remainingBalance > 0).fold(0, (s, b) => s + b.remainingBalance);

  Future<void> _setApproval(String status, {String? reason}) async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) return;
    setState(() => _acting = true);
    try {
      await sl<CustomerRemoteDataSource>().updateApprovalStatus(customerId: customer.customerId, status: status, rejectionReason: reason);
      await _load();
    } catch (_) {
      // OW-M2: the old try/finally swallowed the failure — the owner saw nothing and the chip still showed the old state. The record is left unchanged; _load is only called on success.
      if (mounted) AppFeedback.showError(context, l10n.customerDetailApprovalFailed);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    // The dialog owns its TextEditingController (disposed in its own
    // State.dispose): disposing from here the moment showDialog
    // returns would touch a TextField still built while the dialog
    // route animates out.
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => CustomerRejectReasonDialog(
        title: l10n.customerDetailRejectReasonTitle,
        hint: l10n.customerDetailRejectReasonHint,
        requiredMessage: l10n.customerDetailRejectReasonRequired,
        confirmLabel: l10n.customerDetailRejectConfirm,
        cancelLabel: l10n.cancel,
      ),
    );
    if (reason != null && mounted) await _setApproval('rejected', reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(title: l10n.customerDetailTitle, subtitle: customer?.name),
            Expanded(
              child: _loading
                  ? AppLoadingState(message: l10n.customersLoadingMessage)
                  : _hasError
                      ? AppErrorState(message: l10n.customersLoadError, onRetry: _load)
                      : customer == null
                          ? AppEmptyState(title: l10n.customerDetailNotFound, message: l10n.customerDetailNotFoundMessage)
                          : RefreshIndicator(
                              // Pull-to-refresh (user layout,
                              // 2026-11-16): re-runs [_load].
                              onRefresh: _load,
                              child: _body(context, l10n, customer),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, CustomerEntity customer) {
    final approval = customer.approvalStatus;
    return SingleChildScrollView(
      // Pull-to-refresh (user layout, 2026-11-16): the scroll view
      // must stay draggable even when the content is short, or the
      // RefreshIndicator above it never triggers.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase 3: slim identity card + merged red alert banner
          // (rejection reason + KYC status together).
          CustomerDetailHeader(customer: customer, blacklisted: _blacklisted),
          const SizedBox(height: 16),
          // Phase 3: KYC header carries the real uploaded count
          // (e.g. "KYC Documents (3/11 Uploaded)") over the 3x4
          // dashed grid of all 11 tracked slots.
          CustomerDetailKycSection(customer: customer),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: Text(l10n.customerDetailTotalSpent, style: const TextStyle(fontWeight: FontWeight.w500))), Text(l10n.amountRs(formatRs(_totalSpent)), style: const TextStyle(fontWeight: FontWeight.w500))]),
          const SizedBox(height: 4),
          Row(children: [Expanded(child: Text(l10n.customerDetailTotalDues, style: const TextStyle(fontWeight: FontWeight.w500))), Text(l10n.amountRs(formatRs(_totalDues)), style: const TextStyle(fontWeight: FontWeight.w500))]),
          const SizedBox(height: 16),
          Text(l10n.customerDetailRentalHistory, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (_bookings.isEmpty)
            Text(l10n.customersNoBookings, style: Theme.of(context).textTheme.bodySmall)
          else
            ..._bookings.map((b) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_rounded, size: 18),
                  title: Text('${b.vehicleName ?? l10n.summaryVehicle} • ${b.packageType}'),
                  subtitle: Text('${formatDate(context, b.pickupTime)} • ${_statusLabel(l10n, b.status)}'), // Audit 2026-11-15 DS-5: localized date, never raw d/m/y.
                  trailing: Text(l10n.amountRs(formatRs(b.totalAmount)), style: const TextStyle(fontWeight: FontWeight.w600)),
                )),
          const SizedBox(height: 16),
          // OW-m14: the button matching the current status is disabled (DebouncedButton has no disabled slot, so the decided action is dimmed + input-blocked); the opposite action stays available.
          Row(
            children: [
              Expanded(child: Opacity(opacity: approval == 'approved' ? 0.5 : 1, child: AbsorbPointer(absorbing: approval == 'approved', child: DebouncedButton(text: l10n.customerDetailApprove, icon: Icons.check_rounded, backgroundColor: AppColors.accentSuccessStrong, isLoading: _acting, onPressed: () => _setApproval('approved'))))),
              const SizedBox(width: 12),
              Expanded(child: Opacity(opacity: approval == 'rejected' ? 0.5 : 1, child: AbsorbPointer(absorbing: approval == 'rejected', child: DebouncedButton(text: l10n.customerDetailReject, icon: Icons.close_rounded, backgroundColor: AppColors.errorDark, isLoading: _acting, onPressed: _reject)))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stored booking statuses mapped to localized labels — the stored
/// value itself is never changed.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
