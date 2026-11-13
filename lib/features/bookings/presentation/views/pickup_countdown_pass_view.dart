import 'package:flutter/material.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/digital_qr_pass_widget.dart';
import '../widgets/pass_shop_contact_card.dart';
import '../widgets/pickup_countdown_timer.dart';
import '../../../../l10n/app_localizations.dart';

class PickupCountdownPassView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onReturnHome;
  final VoidCallback? onBack;

  const PickupCountdownPassView({
    super.key,
    required this.booking,
    this.onReturnHome,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.passTitle,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    PickupCountdownTimer(
                      targetPickupTime: booking.pickupTime,
                      overdueLabel: l10n.countdownPickupReached,
                    ),
                    const SizedBox(height: 16),
                    DigitalQrPassWidget(
                      bookingId: booking.bookingId,
                      vehicleName: booking.vehicleName ?? l10n.passRentalVehicle,
                      // CU-M12: a missing plate renders '—', never a
                      // fake 'PAK-786'.
                      plateNumber: booking.vehiclePlate ?? '—',
                      shopName: booking.shopName ?? l10n.rentalShowroom,
                      pickupTime: booking.pickupTime,
                    ),
                    const SizedBox(height: 16),
                    PassShopContactCard(
                      shopId: booking.shopId,
                      shopName: booking.shopName ?? l10n.rentalShowroom,
                      shopPhone: booking.shopPhone,
                      bookingId: booking.bookingId,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: l10n.passDoneHome,
                icon: Icons.home_rounded,
                onPressed: () async {
                  onReturnHome?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
