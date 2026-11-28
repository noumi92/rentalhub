import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// O13: the "customer added" success screen. Reached from the Add
/// Customer wizard after a successful save (the wizard passes the
/// saved record via `extra`; a deep link without it loads the record
/// by id instead). Start Booking opens manual booking prefilled with
/// the customer's name/phone/CNIC; View Profile opens the detail
/// screen. No auto-redirect — the owner chooses the next step.
class OwnerCustomerAddedView extends StatefulWidget {
  final String customerId;
  final CustomerEntity? customer;

  const OwnerCustomerAddedView({
    super.key,
    required this.customerId,
    this.customer,
  });

  @override
  State<OwnerCustomerAddedView> createState() => _OwnerCustomerAddedViewState();
}

class _OwnerCustomerAddedViewState extends State<OwnerCustomerAddedView> {
  CustomerEntity? _customer;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    if (_customer != null) {
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final customer = await sl<CustomerRemoteDataSource>()
          .getCustomerById(widget.customerId);
      if (mounted) setState(() => _customer = customer);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startBooking() {
    final customer = _customer;
    final params = <String, String>{};
    if (customer != null) {
      if (customer.name.isNotEmpty) params['name'] = customer.name;
      if (customer.phone.isNotEmpty) params['phone'] = customer.phone;
      if (customer.cnic != null && customer.cnic!.isNotEmpty) {
        params['cnic'] = customer.cnic!;
      }
    }
    context.push(Uri(
      path: RouteNames.ownerManualBooking,
      queryParameters: params.isEmpty ? null : params,
    ).toString());
  }

  void _viewProfile() {
    context.push(
      RouteNames.ownerCustomerDetail.replaceFirst(':id', widget.customerId),
    );
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
            MinimalAppBar(
              title: l10n.customerAddedTitle,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.ownerCustomers),
            ),
            Expanded(
              child: _loading
                  ? AppLoadingState(message: l10n.customersLoadingMessage)
                  : _hasError
                      ? AppErrorState(
                          message: l10n.customersLoadError, onRetry: _load)
                      : customer == null
                          ? AppEmptyState(
                              title: l10n.customerDetailNotFound,
                              message: l10n.customerDetailNotFoundMessage)
                          : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentSuccessStrong,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 56, color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                customer.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.customerAddedReady(customer.name),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 32),
                              DebouncedButton(
                                text: l10n.customerAddedStartBooking,
                                icon: Icons.calendar_month_rounded,
                                onPressed: _startBooking,
                              ),
                              const SizedBox(height: 12),
                              DebouncedButton(
                                text: l10n.customerAddedViewProfile,
                                icon: Icons.person_rounded,
                                backgroundColor: AppColors.primary,
                                textColor: Colors.white,
                                onPressed: _viewProfile,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      context.go(RouteNames.ownerCustomers),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: Text(l10n.done),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
