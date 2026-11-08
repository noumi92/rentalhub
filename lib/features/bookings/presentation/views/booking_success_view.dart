import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../widgets/booking_status_chip.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              titleWidget: Text(
                'Request Transmitted',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppColors.accentSuccess, size: 54),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Request Sent Successfully!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reference: ${booking.bookingId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your reservation request for ${booking.vehicleName ?? "Vehicle"} has been delivered to ${booking.shopName ?? "the showroom"}. Once approved, you will be notified to submit the advance deposit.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Showroom Status:',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              BookingStatusChip(status: booking.status),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Advance Due Upon Approval:',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              Text('Rs. ${booking.advanceRequired}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.secondary)),
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
                              'Hi ${booking.shopName ?? 'there'}, this is about '
                              'my RentalHub booking ${booking.bookingId} '
                              '(${booking.vehicleName ?? 'vehicle'}).',
                        );
                        if (uri == null) {
                          AppFeedback.showInfo(
                            context,
                            'This showroom has no WhatsApp number listed.',
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
                              'Could not open WhatsApp.',
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentSuccess,
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
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.accentSuccess),
                      label: const Text('Message Showroom on WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
                    text: 'View Payment Details / Status',
                    icon: Icons.payments_outlined,
                    onPressed: () async {
                      onProceedToPayment?.call();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onViewBookings,
                    child: Text('Return to My Bookings',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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
