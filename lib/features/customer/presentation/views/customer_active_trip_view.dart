import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/presentation/widgets/booking_status_chip.dart';
import '../../../bookings/presentation/widgets/pass_shop_contact_card.dart';
import '../../../bookings/presentation/widgets/pickup_countdown_timer.dart';
import '../widgets/active_trip_handover_card.dart';

/// E3: the customer's live trip screen. Everything on it comes from the
/// booking and the real handover record (`handovers/{bookingId}`,
/// written by the owner at pickup): pickup/return times, the return
/// countdown, the odometer and fuel recorded at handover. The old
/// mock telemetry (fake speed/location) is gone — the app has no live
/// GPS tracking, so nothing here pretends to have it.
class CustomerActiveTripView extends StatefulWidget {
  const CustomerActiveTripView({
    super.key,
    required this.booking,
    this.onViewPass,
    this.onBack,
  });

  final BookingEntity booking;
  final VoidCallback? onViewPass;
  final VoidCallback? onBack;

  @override
  State<CustomerActiveTripView> createState() => _CustomerActiveTripViewState();
}

class _CustomerActiveTripViewState extends State<CustomerActiveTripView> {
  Map<String, dynamic>? _handover;
  bool _handoverLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHandover();
  }

  Future<void> _loadHandover() async {
    Map<String, dynamic>? data;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('handovers')
          .doc(widget.booking.bookingId)
          .get();
      data = snap.data();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _handover = data;
        _handoverLoaded = true;
      });
    }
  }

  String _when(DateTime t) =>
      '${t.day}/${t.month}/${t.year} at ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isActive = b.status == 'active';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Text(
                'Active Trip',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PickupCountdownTimer(
                      targetPickupTime:
                          isActive ? b.returnTime : b.pickupTime,
                      label: isActive
                          ? 'TIME UNTIL RETURN'
                          : 'COUNTDOWN TO PICKUP',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  b.vehicleName ?? 'Rental Car',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ),
                              BookingStatusChip(status: b.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${b.shopName ?? 'Showroom'} • ${b.vehiclePlate ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Divider(height: 20),
                          _fact('Pickup', _when(b.pickupTime)),
                          const SizedBox(height: 8),
                          _fact('Return due', _when(b.returnTime)),
                          const SizedBox(height: 8),
                          _fact('Package', '${b.packageType} rental'),
                          if (b.kmLimit != null) ...[
                            const SizedBox(height: 8),
                            _fact('KM included', '${b.kmLimit} km'),
                          ],
                          const SizedBox(height: 8),
                          _fact('Total fare', 'Rs. ${b.totalAmount}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActiveTripHandoverCard(
                      handover: _handover,
                      loaded: _handoverLoaded,
                    ),
                    const SizedBox(height: 16),
                    PassShopContactCard(
                      shopId: b.shopId,
                      shopName: b.shopName ?? 'Rental Showroom',
                      shopPhone: b.shopPhone,
                      bookingId: b.bookingId,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: 'View Pickup Pass (QR)',
                icon: Icons.qr_code_rounded,
                onPressed: () async {
                  widget.onViewPass?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
      ],
    );
  }
}
