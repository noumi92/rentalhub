import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_shell.dart';

/// Phase D (D1) — the bookings list: every booking, filterable by
/// lifecycle status, searchable by booking id, customer, or vehicle.
class AdminBookingsView extends StatefulWidget {
  const AdminBookingsView({super.key});

  @override
  State<AdminBookingsView> createState() => _AdminBookingsViewState();
}

class _AdminBookingsViewState extends State<AdminBookingsView> {
  final _searchController = TextEditingController();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String _filter = 'all';

  static const _statuses = [
    'all',
    'requested',
    'approved',
    'payment_submitted',
    'paid',
    'active',
    'completed',
    'rejected',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bookings =
        await sl<AdminPlatformDataSource>().getBookings(status: _filter);
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  List<BookingModel> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _bookings;
    return _bookings.where((b) {
      return b.bookingId.toLowerCase().contains(query) ||
          (b.customerName ?? '').toLowerCase().contains(query) ||
          (b.vehicleName ?? '').toLowerCase().contains(query) ||
          (b.shopName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: RouteNames.adminBookings,
      title: 'Bookings',
      subtitle: 'Every booking on the platform',
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by booking, customer, car, or shop…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statuses
                    .map((s) => ChoiceChip(
                          label: Text(s),
                          selected: _filter == s,
                          onSelected: (_) {
                            setState(() {
                              _filter = s;
                              _isLoading = true;
                            });
                            _load();
                          },
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visible.isEmpty
                      ? Center(
                          child: Text(
                            'No bookings match — the list reads the bookings collection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final b = _visible[i];
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      ),
                                ),
                                title: Text(
                                    '${b.vehicleName ?? b.vehicleId} • ${b.bookingId}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        )),
                                subtitle: Text(
                                  '${b.customerName ?? 'Customer'} • ${b.shopName ?? ''} • Rs. ${b.totalAmount} • ${b.tripType}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                trailing: _statusChip(context, b.status),
                                onTap: () => context.go(
                                  RouteNames.adminBookingDetail
                                      .replaceFirst(':bookingId', b.bookingId),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final brightness = Theme.of(context).brightness;
    final color = switch (status) {
      'completed' => AppColors.successTextFor(brightness),
      'active' || 'paid' => Colors.blue.shade700,
      'rejected' || 'cancelled' => AppColors.dangerTextFor(brightness),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
