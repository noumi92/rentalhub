import 'package:flutter/material.dart';

import '../../data/datasources/admin_people_data_source.dart';
import 'customer_trust_breakdown.dart';

/// Phase 2 (2.5) — the customer detail's Profile tab: the trust
/// score with its breakdown. The identity header (name, contact,
/// QR, blacklisted chip) sits above the tabs, shared like the
/// customer profile hub's header.
class CustomerDetailProfileTab extends StatelessWidget {
  const CustomerDetailProfileTab({super.key, required this.detail, this.padding = const EdgeInsets.all(16)});

  final CustomerDetail detail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: CustomerTrustBreakdown(
        breakdown: detail.trustBreakdown,
        completedTrips: detail.completedTrips,
        meanOwnerRating: detail.meanOwnerRating,
        kycStatus: detail.kycStatus,
      ),
    );
  }
}
