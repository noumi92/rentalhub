import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../data/datasources/customer_support_data_source.dart';

/// Phase C (C3): the Support tab badge — the number of the signed-in
/// customer's tickets an admin has replied to (tickets in
/// 'in_progress'; see `CustomerSupportDataSource`). Renders the plain
/// [icon] when the count is zero, when the user is signed out, or
/// when no data source resolves (e.g. in widget tests) — a badge must
/// never invent a count.
///
/// The stream is created once in [initState] and kept for the
/// widget's life, so shell rebuilds on tab switches do not
/// resubscribe. Tests may pass [countStream] directly instead of
/// going through DI.
class CustomerSupportBadge extends StatefulWidget {
  final Widget icon;
  final Stream<int>? countStream;

  const CustomerSupportBadge({super.key, required this.icon, this.countStream});

  @override
  State<CustomerSupportBadge> createState() => _CustomerSupportBadgeState();
}

class _CustomerSupportBadgeState extends State<CustomerSupportBadge> {
  late Stream<int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = widget.countStream ?? _resolveCounts();
  }

  @override
  void didUpdateWidget(covariant CustomerSupportBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countStream != oldWidget.countStream) {
      _counts = widget.countStream ?? _resolveCounts();
    }
  }

  String _customerId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Stream<int> _resolveCounts() {
    final customerId = _customerId();
    if (customerId.isEmpty) return Stream.value(0);
    try {
      return sl<CustomerSupportDataSource>()
          .streamRepliedTicketCount(customerId);
    } catch (_) {}
    try {
      return CustomerSupportDataSource()
          .streamRepliedTicketCount(customerId);
    } catch (_) {}
    return Stream.value(0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _counts,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return widget.icon;
        return Badge(label: Text('$count'), child: widget.icon);
      },
    );
  }
}
