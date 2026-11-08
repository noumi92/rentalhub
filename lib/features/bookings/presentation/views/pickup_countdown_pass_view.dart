import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: onBack != null
                  ? IconButton(
                      tooltip: l10n.back,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Text(
                l10n.passTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    PickupCountdownTimer(
                      targetPickupTime: booking.pickupTime,
                    ),
                    const SizedBox(height: 16),
                    DigitalQrPassWidget(
                      bookingId: booking.bookingId,
                      vehicleName: booking.vehicleName ?? l10n.passRentalVehicle,
                      plateNumber: booking.vehiclePlate ?? 'PAK-786',
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
