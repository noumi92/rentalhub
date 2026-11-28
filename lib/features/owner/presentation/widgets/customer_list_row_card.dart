import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../customer/utils/customer_grouping.dart';
import 'customer_list_card_header.dart';
import 'customer_row_book_action.dart';

/// Minimalist hairline CRM customer card: identity header + subtle 1px
/// divider + 3 direct action buttons (Call, Profile, Book Car).
class CustomerListRowCard extends StatelessWidget {
  const CustomerListRowCard({
    super.key,
    required this.customer,
    required this.blacklisted,
    required this.blocked,
    required this.kycIncomplete,
    required this.dormant,
    this.expanded = false,
    this.onToggleExpand,
    required this.isLast,
  });

  final CustomerSummary customer;
  final bool blacklisted;
  final bool blocked;
  final bool kycIncomplete;
  final bool dormant;
  final bool expanded;
  final VoidCallback? onToggleExpand;
  final bool isLast;

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

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: cs.surface,
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? cs.outlineVariant : AppColors.borderSubtle,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          CustomerListCardHeader(
            customer: c,
            blacklisted: blacklisted,
            blocked: blocked,
            kycIncomplete: kycIncomplete,
            dormant: dormant,
            expanded: false,
            onTap: () => context.push(
              RouteNames.ownerCustomerDetail.replaceFirst(':id', _profileId()),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? cs.outlineVariant.withValues(alpha: 0.4)
                : AppColors.borderSubtle.withValues(alpha: 0.7),
          ),
          CustomerRowBookAction(customer: c, blocked: blocked),
        ],
      ),
    );
  }
}
