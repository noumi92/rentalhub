import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/availability_month_grid.dart';

/// Phase B (B3): the booking calendar of one vehicle. Each day shows
/// whether the car is free, has a pending request (amber) or is
/// confirmed out (red). Tapping a day lists that day's bookings.
class OwnerVehicleCalendarView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerVehicleCalendarView({
    super.key,
    required this.vehicle,
    this.onBack,
  });

  @override
  State<OwnerVehicleCalendarView> createState() =>
      _OwnerVehicleCalendarViewState();
}

class _OwnerVehicleCalendarViewState extends State<OwnerVehicleCalendarView> {
  List<BookingEntity> _bookings = [];
  bool _loading = true;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookings = await sl<BookingRemoteDataSource>()
        .getVehicleBookings(widget.vehicle.vehicleId);
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loading = false;
    });
  }

  List<BookingEntity> _bookingsOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _bookings.where((b) {
      final from = DateTime(
          b.pickupTime.year, b.pickupTime.month, b.pickupTime.day);
      final to =
          DateTime(b.returnTime.year, b.returnTime.month, b.returnTime.day);
      return !d.isBefore(from) && !d.isAfter(to);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final selectedBookings =
        _selectedDay == null ? <BookingEntity>[] : _bookingsOn(_selectedDay!);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack ?? () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Calendar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(v.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AvailabilityMonthGrid(
                          month: _month,
                          bookings: _bookings,
                          selectedDay: _selectedDay,
                          onMonthChanged: (m) => setState(() => _month = m),
                          onDaySelected: (d) =>
                              setState(() => _selectedDay = d),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _legend(AppColors.successContainerFor(Theme.of(context).brightness), 'Free'),
                            _legend(AppColors.warningContainerFor(Theme.of(context).brightness), 'Requested'),
                            _legend(AppColors.errorContainerFor(Theme.of(context).brightness), 'Confirmed'),
                            _legend(Theme.of(context).colorScheme.surfaceContainerHighest, 'Past'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedDay != null) ...[
                          Text(
                            'Bookings on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          if (selectedBookings.isEmpty)
                            const Text('No bookings on this day.'),
                          ...selectedBookings.map((b) => Card(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(
                                      b.customerName ??
                                          b.customerId,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                      '${b.packageType} • ${b.pickupTime.hour}:${b.pickupTime.minute.toString().padLeft(2, '0')} → ${b.returnTime.day}/${b.returnTime.month}'),
                                  trailing: Chip(
                                      label: Text(b.status,
                                          style: Theme.of(context).textTheme.labelSmall)),
                                ),
                              )),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
