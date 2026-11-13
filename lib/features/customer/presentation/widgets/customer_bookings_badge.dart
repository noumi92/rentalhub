import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';

/// CU-M11: the Bookings tab badge — the number of the signed-in
/// customer's bookings needing action (approved and awaiting the
/// advance payment, or payment proof rejected). Same Badge pattern
/// as the owner Requests badge and the customer support badge: the
/// plain [icon] renders when the count is zero, when the user is
/// signed out, or when no data source resolves (e.g. in widget
/// tests) — a badge must never invent a count.
///
/// The stream is created once in [initState] and kept for the
/// widget's life, so shell rebuilds on tab switches do not
/// resubscribe. Tests may pass [countStream] directly instead of
/// going through DI.
class CustomerBookingsBadge extends StatefulWidget {
  final Widget icon;
  final Stream<int>? countStream;

  const CustomerBookingsBadge({super.key, required this.icon, this.countStream});

  @override
  State<CustomerBookingsBadge> createState() => _CustomerBookingsBadgeState();
}

class _CustomerBookingsBadgeState extends State<CustomerBookingsBadge> {
  late Stream<int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = widget.countStream ?? _resolveCounts();
  }

  @override
  void didUpdateWidget(covariant CustomerBookingsBadge oldWidget) {
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
      return _countsFrom(sl<BookingRemoteDataSource>(), customerId);
    } catch (_) {}
    try {
      return _countsFrom(BookingRemoteDataSource(), customerId);
    } catch (_) {}
    return Stream.value(0);
  }

  Stream<int> _countsFrom(BookingRemoteDataSource ds, String customerId) {
    return ds.streamCustomerBookings(customerId).map(
          (list) => list
              .where((b) =>
                  b.status == 'approved' || b.status == 'payment_rejected')
              .length,
        );
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
