import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../widgets/booking_status_chip.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

class BookingSuccessView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onProceedToPayment;
  final VoidCallback? onViewBookings;

  const BookingSuccessView({
    super.key,
    required this.booking,
    this.onProceedToPayment,
    this.onViewBookings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.successTransmitted,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                AppColors.accentSuccess.withValues(alpha: 0.3)),
                      ),
                      // Item 4: the raw #10B981 icon is 2.54:1 on the
                      // pale tint — the readable success text token is
                      // 5.48:1 in light (dark leg unchanged).
                      child: Icon(Icons.check_circle_rounded,
                          color: AppColors.successTextFor(
                              Theme.of(context).brightness),
                          size: 54),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.successTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.successReference(booking.bookingId),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.orangeTextFor(Theme.of(context).brightness)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      // CU-M12: a missing field renders '—', never a
                      // fake shop name ('the showroom').
                      l10n.successBody(booking.vehicleName ?? '—', booking.shopName ?? '—'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppCardDecoration.shadow(context)
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.successShopStatus,
                                  style: Theme.of(context).textTheme.bodyMedium),
                              BookingStatusChip(status: booking.status),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.successAdvanceDue,
                                  style: Theme.of(context).textTheme.bodyMedium),
                              Text(l10n.amountRs(formatRs(booking.advanceRequired)),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.orangeTextFor(Theme.of(context).brightness))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final uri = whatsappUri(
                          phone: booking.shopPhone ?? '',
                          message:
                              l10n.successWhatsapp(booking.shopName ?? '—', booking.bookingId, booking.vehicleName ?? '—'),
                        );
                        if (uri == null) {
                          AppFeedback.showInfo(
                            context,
                            l10n.shopNoWhatsappShowroom,
                          );
                          return;
                        }
                        if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (context.mounted) {
                            AppFeedback.showError(
                              context,
                              l10n.couldNotOpenWhatsapp,
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.successTextFor(
                            Theme.of(context).brightness),
                        // Translucent success tint over the surface (same
                        // pattern as the success circle above): readable
                        // in both modes, no pale glare in dark mode.
                        side: BorderSide(
                            color: AppColors.accentSuccess
                                .withValues(alpha: 0.4)),
                        backgroundColor: AppColors.accentSuccess
                            .withValues(alpha: 0.1),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.successTextFor(
                              Theme.of(context).brightness)),
                      label:  Text(l10n.successMessageShop),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DebouncedButton(
                    text: l10n.successViewPayment,
                    icon: Icons.payments_outlined,
                    onPressed: () async {
                      onProceedToPayment?.call();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onViewBookings,
                    child: Text(l10n.successBackToBookings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
