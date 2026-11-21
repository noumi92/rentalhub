import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/repositories/customer_repository.dart';
import '../services/customer_detail_controller.dart';
import '../services/kyc_slot_replace_service.dart';
import '../widgets/customer_detail_actions.dart';
import '../widgets/customer_kyc_replace_handler.dart';
import '../widgets/customer_reject_reason_dialog.dart';
import 'customer_detail_body.dart';

/// Owner-deck finish — the 1 missing screen (#35): a customer profile.
/// Header (name, phone, CNIC), KYC status, documents/photo, rental
/// history, total spent and blacklist state, plus owner Approve /
/// Reject of the profile. The id is a saved-record id; a booking-only
/// customer (no saved record) still resolves — by CNIC, then from
/// their bookings — with an honest "no KYC record on file" state.
/// Dues use the same definition as the dues screen: an approved /
/// paid / active / completed booking with a remaining balance.
///
/// Walk-in CRM (2026-11-21): walk-in records are shop-managed —
/// the header carries the shop status + derived chips (Active /
/// Blocked / KYC Incomplete / Dormant / Frequent), the actions are
/// Block/Unblock, Edit and Archive, and every KYC tile is
/// replaceable in place. Online records keep Approve/Reject and
/// gain Block/Unblock only (no Edit, no Archive, no KYC replace).
/// Data + mutations live in [CustomerDetailController]; the scroll
/// content in [CustomerDetailBody].
class OwnerCustomerDetailView extends StatefulWidget {
  final String customerId;
  final String? shopId;

  /// Test seams: the repository for status/KYC writes and the
  /// KYC replace service. Production resolves both from the
  /// locator (the replacer falls back to a fresh instance, whose
  /// uploader comes from the locator).
  final CustomerRepository? repository;
  final KycSlotReplaceService? replacer;

  const OwnerCustomerDetailView({super.key, required this.customerId, this.shopId, this.repository, this.replacer});

  @override
  State<OwnerCustomerDetailView> createState() => _OwnerCustomerDetailViewState();
}

class _OwnerCustomerDetailViewState extends State<OwnerCustomerDetailView> {
  CustomerDetailData? _data;
  bool _loading = true;
  bool _hasError = false;
  bool _acting = false;

  late final CustomerDetailController _controller = CustomerDetailController(repository: widget.repository);
  late final KycSlotReplaceService _replacer = widget.replacer ?? KycSlotReplaceService();

  String get _shopId => widget.shopId ?? currentShopId();
  String get _statusShopId => _data?.canonicalShopId ?? _shopId;
  CustomerRepository get _repository => widget.repository ?? sl<CustomerRepository>();
  CustomerEntity? get _customer => _data?.customer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _hasError = false);
    }
    try {
      final data = await _controller.load(customerId: widget.customerId, shopId: _shopId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      // OW-M1: the catch used to set only _hasError — build checks _loading first, so a load failure spun forever and the error state below was unreachable.
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  Future<void> _setApproval(String status, {String? reason}) async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) return;
    setState(() => _acting = true);
    try {
      await _controller.setApproval(customerId: customer.customerId, status: status, reason: reason);
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

  /// Walk-in CRM: writes one shop's per-shop status and reloads,
  /// so the chip + banner follow the stored value.
  Future<void> _setStatus(String status, {required String doneMessage}) async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) return;
    setState(() => _acting = true);
    try {
      await _controller.setStatus(
          customerId: customer.customerId,
          shopId: _statusShopId,
          status: status);
      await _load();
      if (mounted) AppFeedback.showSuccess(context, doneMessage);
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.customerDetailStatusFailed);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _toggleBlock() async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) return;
    final current = customer.statusForShop(_statusShopId);
    final next = current == CustomerEntity.statusActive
        ? CustomerEntity.statusBlocked
        : CustomerEntity.statusActive;
    final message = next == CustomerEntity.statusBlocked
        ? l10n.customerDetailBlocked
        : current == CustomerEntity.statusArchived
            ? l10n.customerDetailRestored
            : l10n.customerDetailUnblocked;
    await _setStatus(next, doneMessage: message);
  }

  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) return;
    if (!await CustomerDetailActions.confirmArchive(context)) return;
    setState(() => _acting = true);
    try {
      await _controller.archive(
          customerId: customer.customerId, shopId: _statusShopId);
      await _load();
      if (mounted) AppFeedback.showSuccess(context, l10n.customerDetailArchivedDone);
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.customerDetailStatusFailed);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _edit() {
    final customer = _customer;
    if (customer == null) return;
    context.push(
      RouteNames.ownerCustomerEdit.replaceFirst(':id', customer.customerId),
      extra: customer,
    );
  }

  Future<void> _replaceSlot(String field) async {
    final customer = _customer;
    if (customer == null) return;
    await handleKycSlotReplace(
      context: context,
      customer: customer,
      field: field,
      shopId: _statusShopId,
      repository: _repository,
      replacer: _replacer,
      onChanged: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data;
    final customer = data?.customer;
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
                      : customer == null || data == null
                          ? AppEmptyState(title: l10n.customerDetailNotFound, message: l10n.customerDetailNotFoundMessage)
                          : RefreshIndicator(
                              // Pull-to-refresh (user layout,
                              // 2026-11-16): re-runs [_load].
                              onRefresh: _load,
                              child: CustomerDetailBody(
                                customer: customer,
                                bookings: data.bookings,
                                blacklisted: data.blacklisted,
                                shopId: _statusShopId,
                                acting: _acting,
                                onApprove: () => _setApproval('approved'),
                                onReject: _reject,
                                onBlockToggle: _toggleBlock,
                                onEdit: _edit,
                                onArchive: _archive,
                                onReplaceSlot: _replaceSlot,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
