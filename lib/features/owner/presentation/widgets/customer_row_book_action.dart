import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';

/// #18: "Book a Car" action on an expanded customer row — opens the
/// manual booking wizard prefilled with this customer's name, phone
/// and CNIC (as route query params). Extracted so the customers list
/// stays under the 250-line cap.
class CustomerRowBookAction extends StatelessWidget {
  const CustomerRowBookAction({super.key, required this.customer});

  final CustomerSummary customer;

  void _bookFor(BuildContext context) {
    final params = <String, String>{};
    if (customer.name.isNotEmpty) params['name'] = customer.name;
    if (customer.phone.isNotEmpty) params['phone'] = customer.phone;
    if (customer.cnic != null && customer.cnic!.isNotEmpty) {
      params['cnic'] = customer.cnic!;
    }
    context.push(Uri(
      path: RouteNames.ownerManualBooking,
      queryParameters: params.isEmpty ? null : params,
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: () => _bookFor(context),
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: Text(l10n.quickBookCar),
        ),
      ),
    );
  }
}
