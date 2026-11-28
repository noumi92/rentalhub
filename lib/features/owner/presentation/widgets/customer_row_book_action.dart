import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';

/// Minimalist customer card action row: 48px square Call button, expanded
/// subtle outlined "Profile" button, and expanded terracotta "Book Car" button.
class CustomerRowBookAction extends StatelessWidget {
  const CustomerRowBookAction({
    super.key,
    required this.customer,
    this.blocked = false,
  });

  final CustomerSummary customer;
  final bool blocked;

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? cs.outlineVariant : AppColors.borderSubtle;
    final hasPhone = customer.phone.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.call_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  RouteNames.ownerCustomerDetail
                      .replaceFirst(':id', _profileId()),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: Text(
                  l10n.customersProfileShort,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: blocked ? null : () => _bookFor(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orangeFill,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(
                  l10n.quickBookCar,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
