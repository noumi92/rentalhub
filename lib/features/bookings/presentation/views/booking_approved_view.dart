import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/booking_summary_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';

class BookingApprovedView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onPayAdvance;
  final VoidCallback? onBack;

  const BookingApprovedView({
    super.key,
    required this.booking,
    this.onPayAdvance,
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
              title: l10n.approvedTitle,
              onBack: onBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentSuccess
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle_rounded,
                                color: AppColors.successTextFor(
                                    Theme.of(context).brightness),
                                size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.approvedReadyAdvance,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.approvedPayToGuarantee(formatRs(booking.advanceRequired)),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color: AppColors.primaryContainer),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    BookingSummaryCard(
                      carName: booking.vehicleName ?? l10n.summaryVehicle,
                      plateNumber: booking.vehiclePlate ?? 'PAK-786',
                      shopName: booking.shopName ?? l10n.showroomLabel,
                      isWithDriver: booking.isWithDriver,
                      packageType: booking.packageType,
                      pickupTime: booking.pickupTime,
                      returnTime: booking.returnTime,
                      totalAmount: booking.totalAmount,
                      advanceRequired: booking.advanceRequired,
                      tripType: booking.tripType,
                      kmLimit: booking.kmLimit,
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
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: l10n.payAdvanceAmount(formatRs(booking.advanceRequired)),
                icon: Icons.payments_rounded,
                onPressed: () async {
                  onPayAdvance?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
