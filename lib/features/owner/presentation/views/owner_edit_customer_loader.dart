import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'owner_add_customer_wizard.dart';
import 'owner_customer_detail_view.dart';

/// Walk-in CRM: the `/owner/customers/:id/edit` route guard. The
/// wizard needs the saved record (to prefill + preserve identity);
/// the Edit button passes it via `extra`, but a deep link has no
/// extra, so the record is loaded by id here first.
///
/// Walk-in only: an online record is refused — the owner is shown
/// the profile instead (online customers are approved/rejected by
/// the super admin and are never edited, archived or KYC-replaced
/// by a shop). A missing record lands on the profile's own
/// not-found state.
class OwnerEditCustomerLoader extends StatefulWidget {
  const OwnerEditCustomerLoader({
    super.key,
    required this.customerId,
    this.customer,
    this.initialStep = 0,
  });

  final String customerId;
  final CustomerEntity? customer;
  final int initialStep;

  @override
  State<OwnerEditCustomerLoader> createState() =>
      _OwnerEditCustomerLoaderState();
}

class _OwnerEditCustomerLoaderState extends State<OwnerEditCustomerLoader> {
  CustomerEntity? _customer;
  bool _loading = true;
  bool _hasError = false;

  /// The "online customers cannot be edited here" note is shown
  /// once per loader instance (build can run many times).
  bool _onlineNoted = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _customer = widget.customer;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final customer = await sl<CustomerRemoteDataSource>()
          .getCustomerById(widget.customerId);
      if (!mounted) return;
      setState(() {
        _customer = customer;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        body: AppLoadingState(message: l10n.customersLoadingMessage),
      );
    }
    if (_hasError) {
      return Scaffold(
        body: AppErrorState(
          message: l10n.customersLoadError,
          onRetry: _load,
        ),
      );
    }
    final customer = _customer;
    if (customer == null) {
      return OwnerCustomerDetailView(customerId: widget.customerId);
    }
    if (customer.source != 'walk_in') {
      // Online records are refused for editing — show the profile
      // with an honest note instead of opening the wizard.
      if (!_onlineNoted) {
        _onlineNoted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.customerDetailEditOnlineNotAllowed)),
          );
        });
      }
      return OwnerCustomerDetailView(customerId: widget.customerId);
    }
    return OwnerAddCustomerWizard(
      editingCustomer: customer,
      initialStep: widget.initialStep,
    );
  }
}
