import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';

/// #18 + owner-deck finish (#35): the actions on an expanded customer
/// row. "Book a Car" opens the manual booking wizard prefilled with
/// this customer's name, phone and CNIC (as route query params);
/// "View Profile" opens the customer detail screen. The profile id
/// prefers the saved record; a booking-only customer falls back to
/// the booking's customer id, then the list key, then the CNIC digits
/// (the detail screen also resolves a CNIC id).
class CustomerRowBookAction extends StatelessWidget {
  const CustomerRowBookAction({super.key, required this.customer});

  final CustomerSummary customer;

  String _profileId() {
    final saved = customer.savedRecord?.customerId;
    if (saved != null && saved.isNotEmpty) return saved;
    final fromBooking = customer.bookings
        .map((b) => b.customerId)
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    if (fromBooking.isNotEmpty) return fromBooking;
    if (customer.key.startsWith('id:')) return customer.key.substring(3);
    return customer.cnic?.replaceAll('-', '').trim() ?? customer.key;
  }

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
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => context.push(RouteNames.ownerCustomerDetail
                .replaceFirst(':id', _profileId())),
            icon: const Icon(Icons.person_rounded, size: 18),
            label: Text(l10n.customersViewProfile),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _bookFor(context),
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(l10n.quickBookCar),
          ),
        ],
      ),
    );
  }
}
