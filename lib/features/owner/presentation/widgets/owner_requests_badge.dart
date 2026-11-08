import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';

/// Phase C (C3): the Requests tab badge — the pending-request count,
/// the same source as the dashboard KPI: shop bookings with status
/// 'requested' or 'payment_submitted', streamed live so a new request
/// lights the badge without reopening the tab. Renders the plain
/// [icon] when the count is zero (or when no data source resolves,
/// e.g. in widget tests) — a badge must never invent a count.
///
/// The stream is created once in [initState] and kept for the
/// widget's life, so shell rebuilds on tab switches do not
/// resubscribe. Tests may pass [countStream] directly instead of
/// going through DI.
class OwnerRequestsBadge extends StatefulWidget {
  final Widget icon;
  final Stream<int>? countStream;

  const OwnerRequestsBadge({super.key, required this.icon, this.countStream});

  @override
  State<OwnerRequestsBadge> createState() => _OwnerRequestsBadgeState();
}

class _OwnerRequestsBadgeState extends State<OwnerRequestsBadge> {
  late Stream<int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = widget.countStream ?? _resolveCounts();
  }

  @override
  void didUpdateWidget(covariant OwnerRequestsBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countStream != oldWidget.countStream) {
      _counts = widget.countStream ?? _resolveCounts();
    }
  }

  Stream<int> _resolveCounts() {
    try {
      return _countsFrom(sl<BookingRemoteDataSource>());
    } catch (_) {}
    try {
      return _countsFrom(BookingRemoteDataSource());
    } catch (_) {}
    return Stream.value(0);
  }

  Stream<int> _countsFrom(BookingRemoteDataSource ds) {
    return ds.streamShopBookings(currentShopId()).map(
          (list) => list
              .where((b) =>
                  b.status == 'requested' || b.status == 'payment_submitted')
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
