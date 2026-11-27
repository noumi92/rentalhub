import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'customer_trust_breakdown.dart';

/// Phase 2 (2.5) — the customer detail's Profile tab: the trust
/// score with its breakdown. The identity header (name, contact,
/// QR, blacklisted chip) sits above the tabs, shared like the
/// customer profile hub's header.
///
/// Step 3 — the KYC entry point lives here (not a new tab, not the
/// sticky bar): reviewers (decideKyc) get a "View KYC documents"
/// button under the breakdown that opens the existing KYC Review
/// detail screen for this customer, with `?from=customer` so its
/// back button returns here instead of to the queue.
class CustomerDetailProfileTab extends StatelessWidget {
  const CustomerDetailProfileTab({super.key, required this.detail, this.padding = const EdgeInsets.all(16), this.canReviewKyc = false});

  final CustomerDetail detail;
  final EdgeInsetsGeometry padding;

  /// Whether the signed-in admin may review KYC (decideKyc:
  /// super admin + operations). Resolved once by the detail view
  /// and passed down — never resolved here.
  final bool canReviewKyc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerTrustBreakdown(
            breakdown: detail.trustBreakdown,
            completedTrips: detail.completedTrips,
            meanOwnerRating: detail.meanOwnerRating,
            kycStatus: detail.kycStatus,
          ),
          if (canReviewKyc) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go(
                '${RouteNames.adminKycReviewDetail.replaceFirst(':customerId', detail.customer.customerId)}?from=customer',
              ),
              icon: const Icon(Icons.badge_rounded),
              label: Text(l10n.admin2_customerDetailViewKyc),
            ),
          ],
        ],
      ),
    );
  }
}
