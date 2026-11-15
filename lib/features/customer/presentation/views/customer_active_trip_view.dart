import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/presentation/widgets/booking_status_chip.dart';
import '../../../bookings/presentation/widgets/pass_shop_contact_card.dart';
import '../../../bookings/presentation/widgets/pickup_countdown_timer.dart';
import '../widgets/active_trip_handover_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

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

  // Audit 2026-11-15 DS-5: localized date + time, never raw d/m/y.
  String _when(DateTime t) => formatDateTime(context, t);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = widget.booking;
    final isActive = b.status == 'active';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.activeTripTitle,
              onBack: widget.onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PickupCountdownTimer(
                      targetPickupTime: isActive ? b.returnTime : b.pickupTime,
                      label: isActive
                          ? l10n.timeUntilReturn
                          : l10n.countdownToPickup,
                      // CU-m8: once the time passes the digits count
                      // up the overdue time under this label.
                      overdueLabel: isActive
                          ? l10n.countdownReturnReached
                          : l10n.countdownPickupReached,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppCardDecoration.shadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  b.vehicleName ?? l10n.rentalCar,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              BookingStatusChip(status: b.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.activeTripShopLine(b.shopName ?? l10n.showroomLabel, b.vehiclePlate ?? ''),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Divider(height: 20),
                          _fact(l10n.pickupLabel, _when(b.pickupTime)),
                          const SizedBox(height: 8),
                          _fact(l10n.returnDue, _when(b.returnTime)),
                          const SizedBox(height: 8),
                          _fact(l10n.packageLabel, l10n.activeTripPackageRental(b.packageType)),
                          if (b.kmLimit != null) ...[
                            const SizedBox(height: 8),
                            _fact(l10n.kmIncluded, '${b.kmLimit} km'),
                          ],
                          const SizedBox(height: 8),
                          _fact(l10n.totalFare, l10n.amountRs(formatRs(b.totalAmount))),
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
                      shopName: b.shopName ?? l10n.rentalShowroom,
                      shopPhone: b.shopPhone,
                      bookingId: b.bookingId,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: l10n.viewPickupPassQr,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ),
        ),
      ],
    );
  }
}
