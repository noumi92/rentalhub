import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';

/// #18 + owner-deck finish (#35), restyled Phase 3: the actions on
/// an expanded customer row. "Book a Car" opens the manual booking
/// wizard prefilled with this customer's name, phone and CNIC (as
/// route query params); "View Profile" opens the customer detail
/// screen. The profile id prefers the saved record; a booking-only
/// customer falls back to the booking's customer id, then the list
/// key, then the CNIC digits (the detail screen also resolves a
/// CNIC id).
///
/// Phase 3 adds a Call button (same `tel:` launch pattern as
/// [ShopDetailHeader]: `Uri(scheme: 'tel', ...)` + [launchUrl],
/// dialer failure surfaced, disabled with no phone number). The row
/// is 48 px high — the guide's 38 px violates rulebook §4.6 (48x48
/// minimum touch target). Book a Car is solid orange (`orangeFill`,
/// white text 5.18:1); View Profile and Call are outlined.
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

  Future<void> _call(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final digits = customer.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.couldNotOpenDialer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhone = customer.phone.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Tooltip(
              message: l10n.call,
              child: SizedBox(
                width: 48,
                height: 48,
                child: OutlinedButton(
                  onPressed: hasPhone ? () => _call(context) : null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.call_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.ownerCustomerDetail
                    .replaceFirst(':id', _profileId())),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.person_rounded, size: 18),
                label: Text(l10n.customersViewProfile,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _bookFor(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orangeFill,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: Text(l10n.quickBookCar,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
